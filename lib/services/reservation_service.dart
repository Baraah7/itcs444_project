//Reservation booking + tracking
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/rental_model.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

class ReservationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();
  
  // Collection references
  CollectionReference get rentalsCollection => _firestore.collection('rentals');
  CollectionReference get usersCollection => _firestore.collection('users');
  
  // Create a new rental reservation
  Future<String> createRental({
    required String equipmentId,
    required String equipmentName,
    required String itemType,
    required DateTime startDate,
    required DateTime endDate,
    int quantity = 1,
    double dailyRate = 0,
  }) async {
    try {
      // Get current user
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');
      
      // Get user details
      final userDoc = await usersCollection.doc(user.uid).get();
      
      if (!userDoc.exists) throw Exception('User not found');
      
      final userData = userDoc.data() as Map<String, dynamic>;
      final userFullName = '${userData['firstName']} ${userData['lastName']}';
      
      // Check equipment availability in subcollection
      final itemsSnapshot = await _firestore
          .collection('equipment')
          .doc(equipmentId)
          .collection('Items')
          .where('availability', isEqualTo: true)
          .get();
      
      if (itemsSnapshot.docs.length < quantity) {
        throw Exception('Not enough items available. Only ${itemsSnapshot.docs.length} available');
      }
      
      // Calculate total cost
      final int duration = endDate.difference(startDate).inDays;
      final double totalCost = dailyRate * duration * quantity;
      
      // Create rental ID
      final rentalId = rentalsCollection.doc().id;
      
      // Create rental object
      final rental = Rental(
        id: rentalId,
        userId: user.uid,
        userFullName: userFullName,
        equipmentId: equipmentId,
        equipmentName: equipmentName,
        itemType: itemType,
        startDate: startDate,
        endDate: endDate,
        totalCost: totalCost,
        status: 'pending',
        createdAt: DateTime.now(),
        quantity: quantity,
      );
      
      // Save to Firestore
      await rentalsCollection.doc(rentalId).set(rental.toMap());
      
      // Mark items as reserved (temporarily unavailable)
      final itemsToReserve = itemsSnapshot.docs.take(quantity);
      for (final itemDoc in itemsToReserve) {
        await itemDoc.reference.update({
          'availability': false,
          'reservedFor': rentalId,
          'reservedUntil': endDate.toIso8601String(),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
      
      // Send notification (you can implement Firebase Cloud Messaging here)
      _sendNewReservationNotification(rental);
      
      return rentalId;
    } catch (e) {
      throw Exception('Failed to create rental: $e');
    }
  }
  
  // Get rentals for current user
  Stream<List<Rental>> getUserRentals() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);
    
    return rentalsCollection
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Rental.fromMap(doc.data() as Map<String, dynamic>))
              .toList();
        });
  }
  
  // Get all rentals (for admin)
  Stream<List<Rental>> getAllRentals() {
    return rentalsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Rental.fromMap(doc.data() as Map<String, dynamic>))
              .toList();
        });
  }
  
  // Get rentals by status
  Stream<List<Rental>> getRentalsByStatus(String status) {
    return rentalsCollection
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Rental.fromMap(doc.data() as Map<String, dynamic>))
              .toList();
        });
  }
  
  // Get single rental by ID
  Future<Rental> getRentalById(String rentalId) async {
    final rentalDoc = await rentalsCollection.doc(rentalId).get();
    
    if (!rentalDoc.exists) throw Exception('Rental not found');
    
    return Rental.fromMap(rentalDoc.data() as Map<String, dynamic>);
  }
  
  // Get rental stream for real-time updates
  Stream<Rental> getRentalStream(String rentalId) {
    return rentalsCollection
        .doc(rentalId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) throw Exception('Rental not found');
          return Rental.fromMap(snapshot.data() as Map<String, dynamic>);
        });
  }
  
  // Update rental status (admin only)
  Future<void> updateRentalStatus({
    required String rentalId,
    required String status,
    String? adminNotes,
  }) async {
    try {
      final rentalDoc = await rentalsCollection.doc(rentalId).get();
      if (!rentalDoc.exists) throw Exception('Rental not found');
      
      final rental = Rental.fromMap(rentalDoc.data() as Map<String, dynamic>);
      final updateData = <String, dynamic>{
        'status': status,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      if (adminNotes != null) {
        updateData['adminNotes'] = adminNotes;
      }
      
      // Update rental document
      await rentalsCollection.doc(rentalId).update(updateData);
      
      // Handle different status transitions
      switch (status) {
        case 'approved':
          await _handleApproval(rental);
          break;
        case 'checked_out':
          await _handleCheckout(rental);
          break;
        case 'returned':
          await _handleReturn(rental);
          break;
        case 'cancelled':
          await _handleCancellation(rental);
          break;
        case 'maintenance':
          await _handleMaintenance(rental);
          break;
      }
      
      // Send notification
      _sendStatusUpdateNotification(rentalId, status, rental.userId);
      
    } catch (e) {
      throw Exception('Failed to update rental status: $e');
    }
  }
  
  // Check equipment availability for date range
  Future<bool> checkAvailability({
    required String equipmentId,
    required DateTime startDate,
    required DateTime endDate,
    int quantity = 1,
  }) async {
    try {
      // Check for available items
      final availableItems = await _firestore
          .collection('equipment')
          .doc(equipmentId)
          .collection('Items')
          .where('availability', isEqualTo: true)
          .get();
      
      if (availableItems.docs.length < quantity) return false;
      
      // Check for overlapping rentals
      final overlappingQuery = await rentalsCollection
          .where('equipmentId', isEqualTo: equipmentId)
          .where('status', whereIn: ['pending', 'approved', 'checked_out'])
          .get();
      
      int reservedCount = 0;
      for (final rentalDoc in overlappingQuery.docs) {
        final rental = Rental.fromMap(rentalDoc.data() as Map<String, dynamic>);
        
        // Check for date overlap
        if (startDate.isBefore(rental.endDate) && 
            endDate.isAfter(rental.startDate)) {
          reservedCount += rental.quantity;
        }
      }
      
      // Total available minus reserved
      final totalAvailable = availableItems.docs.length;
      return (totalAvailable - reservedCount) >= quantity;
    } catch (e) {
      throw Exception('Failed to check availability: $e');
    }
  }
  
  // Cancel rental (user only)
  Future<void> cancelRental(String rentalId) async {
    try {
      final rentalDoc = await rentalsCollection.doc(rentalId).get();
      
      if (!rentalDoc.exists) throw Exception('Rental not found');
      
      final rental = Rental.fromMap(rentalDoc.data() as Map<String, dynamic>);
      final user = _auth.currentUser;
      
      // Check ownership
      if (user?.uid != rental.userId) {
        throw Exception('Not authorized to cancel this rental');
      }
      
      // Only allow cancellation if status is pending
      if (!rental.canBeCancelled) {
        throw Exception('Cannot cancel rental with status: ${rental.status}');
      }
      
      // Update rental status
      await rentalsCollection.doc(rentalId).update({
        'status': 'cancelled',
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
      // Free up reserved items
      await _freeUpReservedItems(rentalId);
      
      // Send notification
      _sendStatusUpdateNotification(rentalId, 'cancelled', rental.userId);
      
    } catch (e) {
      throw Exception('Failed to cancel rental: $e');
    }
  }
  
  // Extend rental duration
  Future<void> extendRental({
    required String rentalId,
    required DateTime newEndDate,
    double? additionalCost,
  }) async {
    try {
      final rentalDoc = await rentalsCollection.doc(rentalId).get();
      if (!rentalDoc.exists) throw Exception('Rental not found');
      
      final rental = Rental.fromMap(rentalDoc.data() as Map<String, dynamic>);
      
      // Only allow extension for active rentals
      if (!rental.isActive) {
        throw Exception('Cannot extend rental with status: ${rental.status}');
      }
      
      // Check availability for extended period
      final isAvailable = await checkAvailability(
        equipmentId: rental.equipmentId,
        startDate: rental.startDate,
        endDate: newEndDate,
        quantity: rental.quantity,
      );
      
      if (!isAvailable) {
        throw Exception('Not available for extended period');
      }
      
      // Calculate additional cost if not provided
      final calculatedCost = additionalCost ?? 
          (rental.totalCost / rental.durationInDays) * 
          (newEndDate.difference(rental.endDate).inDays);
      
      // Update rental
      await rentalsCollection.doc(rentalId).update({
        'endDate': newEndDate.toIso8601String(),
        'totalCost': rental.totalCost + calculatedCost,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
      // Update reserved items
      await _updateReservedItems(rentalId, newEndDate);
      
    } catch (e) {
      throw Exception('Failed to extend rental: $e');
    }
  }
  
  // Get overdue rentals
  Stream<List<Rental>> getOverdueRentals() {
    final now = DateTime.now().toIso8601String();
    
    return rentalsCollection
        .where('status', isEqualTo: 'checked_out')
        .where('endDate', isLessThan: now)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Rental.fromMap(doc.data() as Map<String, dynamic>))
              .toList();
        });
  }
  
  // Get rentals needing action (pending, overdue, etc.)
  Stream<List<Rental>> getRentalsNeedingAction() {
    return rentalsCollection
        .where('status', whereIn: ['pending', 'checked_out'])
        .snapshots()
        .map((snapshot) {
          final allRentals = snapshot.docs
              .map((doc) => Rental.fromMap(doc.data() as Map<String, dynamic>))
              .toList();
          
          // Filter checked_out rentals for overdue ones
          return allRentals.where((rental) {
            if (rental.status == 'pending') return true;
            if (rental.status == 'checked_out' && rental.isOverdue) return true;
            return false;
          }).toList();
        });
  }
  
  // Get rental statistics
  Future<Map<String, dynamic>> getRentalStatistics() async {
    final allRentals = await rentalsCollection.get();
    final rentals = allRentals.docs
        .map((doc) => Rental.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
    
    int pending = 0;
    int approved = 0;
    int checkedOut = 0;
    int returned = 0;
    int cancelled = 0;
    int maintenance = 0;
    double totalRevenue = 0;
    int overdue = 0;
    
    for (final rental in rentals) {
      switch (rental.status) {
        case 'pending':
          pending++;
          break;
        case 'approved':
          approved++;
          break;
        case 'checked_out':
          checkedOut++;
          if (rental.isOverdue) overdue++;
          break;
        case 'returned':
          returned++;
          totalRevenue += rental.totalCost;
          break;
        case 'cancelled':
          cancelled++;
          break;
        case 'maintenance':
          maintenance++;
          break;
      }
    }
    
    return {
      'total': rentals.length,
      'pending': pending,
      'approved': approved,
      'checkedOut': checkedOut,
      'returned': returned,
      'cancelled': cancelled,
      'maintenance': maintenance,
      'overdue': overdue,
      'totalRevenue': totalRevenue,
      'active': pending + approved + checkedOut,
    };
  }
  
  // Get user rental history
  Future<List<Rental>> getUserRentalHistory(String userId) async {
    final snapshot = await rentalsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    
    return snapshot.docs
        .map((doc) => Rental.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }
  
  // Get equipment rental history
  Future<List<Rental>> getEquipmentRentalHistory(String equipmentId) async {
    final snapshot = await rentalsCollection
        .where('equipmentId', isEqualTo: equipmentId)
        .orderBy('createdAt', descending: true)
        .get();
    
    return snapshot.docs
        .map((doc) => Rental.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }
  
  // PRIVATE HELPER METHODS
  
  // Handle approval process
  Future<void> _handleApproval(Rental rental) async {
    // Update reserved items to approved status
    final itemsSnapshot = await _firestore
        .collectionGroup('Items')
        .where('reservedFor', isEqualTo: rental.id)
        .get();
    
    for (final itemDoc in itemsSnapshot.docs) {
      await itemDoc.reference.update({
        'rentalStatus': 'approved',
        'rentedTo': rental.id,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }
  }
  
  // Handle checkout process
  Future<void> _handleCheckout(Rental rental) async {
    // Update items to checked out status
    final itemsSnapshot = await _firestore
        .collectionGroup('Items')
        .where('rentedTo', isEqualTo: rental.id)
        .get();
    
    for (final itemDoc in itemsSnapshot.docs) {
      await itemDoc.reference.update({
        'checkedOutAt': DateTime.now().toIso8601String(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }
  }
  
  // Handle return process
  Future<void> _handleReturn(Rental rental) async {
    // Free up items and mark as available
    final itemsSnapshot = await _firestore
        .collectionGroup('Items')
        .where('rentedTo', isEqualTo: rental.id)
        .get();
    
    for (final itemDoc in itemsSnapshot.docs) {
      await itemDoc.reference.update({
        'availability': true,
        'returnedAt': DateTime.now().toIso8601String(),
        'reservedFor': FieldValue.delete(),
        'reservedUntil': FieldValue.delete(),
        'rentedTo': FieldValue.delete(),
        'rentalStatus': FieldValue.delete(),
        'checkedOutAt': FieldValue.delete(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }
    
    // Update rental with actual return date
    await rentalsCollection.doc(rental.id).update({
      'actualReturnDate': DateTime.now().toIso8601String(),
    });
  }
  
  // Handle cancellation process
  Future<void> _handleCancellation(Rental rental) async {
    await _freeUpReservedItems(rental.id);
  }
  
  // Handle maintenance process
  Future<void> _handleMaintenance(Rental rental) async {
    // Mark items as needing maintenance
    final itemsSnapshot = await _firestore
        .collectionGroup('Items')
        .where('rentedTo', isEqualTo: rental.id)
        .get();
    
    for (final itemDoc in itemsSnapshot.docs) {
      await itemDoc.reference.update({
        'needsMaintenance': true,
        'maintenanceRequestedAt': DateTime.now().toIso8601String(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }
  }
  
  // Free up reserved items
  Future<void> _freeUpReservedItems(String rentalId) async {
    final itemsSnapshot = await _firestore
        .collectionGroup('Items')
        .where('reservedFor', isEqualTo: rentalId)
        .get();
    
    for (final itemDoc in itemsSnapshot.docs) {
      await itemDoc.reference.update({
        'availability': true,
        'reservedFor': FieldValue.delete(),
        'reservedUntil': FieldValue.delete(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }
  }
  
  // Update reserved items end date
  Future<void> _updateReservedItems(String rentalId, DateTime newEndDate) async {
    final itemsSnapshot = await _firestore
        .collectionGroup('Items')
        .where('reservedFor', isEqualTo: rentalId)
        .get();
    
    for (final itemDoc in itemsSnapshot.docs) {
      await itemDoc.reference.update({
        'reservedUntil': newEndDate.toIso8601String(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }
  }
  
  // Send notification for new reservation
  void _sendNewReservationNotification(Rental rental) {
    // Implement Firebase Cloud Messaging here
    print('New reservation created: ${rental.id} by ${rental.userFullName}');
    
    // Example FCM implementation:
    /*
    await FirebaseMessaging.instance.send(
      data: {
        'type': 'new_reservation',
        'rentalId': rental.id,
        'userId': rental.userId,
        'equipmentName': rental.equipmentName,
      },
    );
    */
  }
  
  // Send notification for status update
  void _sendStatusUpdateNotification(String rentalId, String status, String userId) {
    print('Rental $rentalId status updated to: $status');
    
    // Example FCM implementation:
    /*
    await FirebaseMessaging.instance.send(
      data: {
        'type': 'status_update',
        'rentalId': rentalId,
        'status': status,
        'userId': userId,
      },
    );
    */
  }
  
  // Check if user has overdue rentals
  Future<bool> userHasOverdueRentals(String userId) async {
    final snapshot = await rentalsCollection
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'checked_out')
        .get();
    
    for (final doc in snapshot.docs) {
      final rental = Rental.fromMap(doc.data() as Map<String, dynamic>);
      if (rental.isOverdue) return true;
    }
    
    return false;
  }
  
  // Calculate user trust score based on rental history
  Future<int> calculateUserTrustScore(String userId) async {
    final history = await getUserRentalHistory(userId);
    
    if (history.isEmpty) return 0;
    
    int returnedCount = 0;
    int overdueCount = 0;
    int cancelledCount = 0;
    
    for (final rental in history) {
      if (rental.status == 'returned') returnedCount++;
      if (rental.status == 'checked_out' && rental.isOverdue) overdueCount++;
      if (rental.status == 'cancelled') cancelledCount++;
    }
    
    // Calculate score (simplified)
    int score = returnedCount * 10;
    score -= overdueCount * 20;
    score -= cancelledCount * 5;
    
    // Ensure score is between 0 and 100
    return score.clamp(0, 100);
  }
  
  // Get equipment availability calendar
  Future<Map<DateTime, int>> getEquipmentAvailabilityCalendar(
    String equipmentId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final availabilityMap = <DateTime, int>{};
    
    // Get total available items
    final availableItems = await _firestore
        .collection('equipment')
        .doc(equipmentId)
        .collection('Items')
        .where('availability', isEqualTo: true)
        .get();
    
    final totalAvailable = availableItems.docs.length;
    
    // Get all rentals for this equipment in date range
    final rentalsSnapshot = await rentalsCollection
        .where('equipmentId', isEqualTo: equipmentId)
        .where('status', whereIn: ['pending', 'approved', 'checked_out'])
        .get();
    
    // Initialize all dates with full availability
    DateTime currentDate = startDate;
    while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
      availabilityMap[currentDate] = totalAvailable;
      currentDate = currentDate.add(const Duration(days: 1));
    }
    
    // Subtract reserved quantities for each date
    for (final rentalDoc in rentalsSnapshot.docs) {
      final rental = Rental.fromMap(rentalDoc.data() as Map<String, dynamic>);
      
      DateTime rentalDate = rental.startDate;
      while (rentalDate.isBefore(rental.endDate) || rentalDate.isAtSameMomentAs(rental.endDate)) {
        if (availabilityMap.containsKey(rentalDate)) {
          availabilityMap[rentalDate] = (availabilityMap[rentalDate]! - rental.quantity).clamp(0, totalAvailable);
        }
        rentalDate = rentalDate.add(const Duration(days: 1));
      }
    }
    
    return availabilityMap;
  }
}