import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/rental_model.dart';
import '../models/equipment_model.dart';
import 'notification_service.dart';

class ReservationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();
  
  // Collection references
  CollectionReference get rentalsCollection => _firestore.collection('rentals');
  CollectionReference get equipmentCollection => _firestore.collection('equipment');
  CollectionReference get usersCollection => _firestore.collection('users');
  
  // 1. CREATE A NEW RENTAL (FIXED VERSION)
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
      // Get current Firebase user
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        throw Exception('Please login to make a reservation');
      }
      
      // Get user details from Firestore
      final userDoc = await usersCollection.doc(firebaseUser.uid).get();
      if (!userDoc.exists) {
        throw Exception('User profile not found. Please complete your profile.');
      }
      
      final userData = userDoc.data() as Map<String, dynamic>;
      var userFullName = '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();
      if (userFullName.isEmpty) {
        userFullName = userData['email'] ?? 'User';
      }
      
      // Calculate duration and validate
      final int duration = endDate.difference(startDate).inDays;
      if (duration < 1) {
        throw Exception('Rental must be at least 1 day');
      }
      
      // Get maximum rental days for this equipment type
      final maxDays = _getMaxRentalDays(itemType);
      if (duration > maxDays) {
        throw Exception('Maximum rental period is $maxDays days for $itemType');
      }
      
      // Calculate total cost
      final double totalCost = dailyRate * duration * quantity;
      
      // Use Firestore transaction to ensure data consistency
      final String rentalId = await _firestore.runTransaction<String>((transaction) async {
        // 1. Get equipment document
        final equipmentRef = equipmentCollection.doc(equipmentId);
        final equipmentDoc = await transaction.get(equipmentRef);
        
        if (!equipmentDoc.exists) {
          throw Exception('Equipment not found');
        }
        
        final equipmentData = equipmentDoc.data() as Map<String, dynamic>;
        
        // 2. Check if equipment is available
        final availability = equipmentData['availability'] ?? false;
        if (!availability) {
          throw Exception('This equipment is currently unavailable');
        }
        
        // 3. Check quantity
        final totalQuantity = (equipmentData['quantity'] ?? 1) as int;
        final availableQuantity = (equipmentData['availableQuantity'] ?? totalQuantity) as int;
        
        if (availableQuantity < quantity) {
          throw Exception('Not enough equipment available. Only $availableQuantity available');
        }
        
        // 4. Check for overlapping reservations
        final overlappingQuery = await _firestore
            .collection('rentals')
            .where('equipmentId', isEqualTo: equipmentId)
            .where('status', whereIn: ['pending', 'approved', 'checked_out'])
            .get();
        
        int reservedCount = 0;
        for (final rentalDoc in overlappingQuery.docs) {
          final rentalData = rentalDoc.data() as Map<String, dynamic>;
          final rentalStart = DateTime.parse(rentalData['startDate']);
          final rentalEnd = DateTime.parse(rentalData['endDate']);
          
          // Check for date overlap
          if (startDate.isBefore(rentalEnd) && endDate.isAfter(rentalStart)) {
            reservedCount += (rentalData['quantity'] ?? 1) as int;
          }
        }
        
        final actuallyAvailable = availableQuantity - reservedCount;
        if (actuallyAvailable < quantity) {
          throw Exception('Not available for selected dates. Try different dates.');
        }
        
        // 5. Create rental document
        final rentalRef = rentalsCollection.doc();
        final rentalId = rentalRef.id;
        
        final rental = Rental(
          id: rentalId,
          userId: firebaseUser.uid,
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
        
        // 6. Update equipment's available quantity
        final newAvailableQuantity = availableQuantity - quantity;
        transaction.update(equipmentRef, {
          'availableQuantity': newAvailableQuantity,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        // 7. Save rental
        transaction.set(rentalRef, rental.toMap());
        
        return rentalId;
      });
      
      // Send notification to user
      await _notificationService.sendNotification(
        userId: firebaseUser.uid,
        title: 'Rental Request Submitted',
        message: 'Your rental request for "$equipmentName" has been submitted and is pending approval.',
        type: 'approval',
        data: {'rentalId': rentalId},
      );
      
      // Notify admins
      await _notifyAdmins(
        'New Rental Request',
        'New rental request for "$equipmentName" by $userFullName',
        'approval',
        {'rentalId': rentalId},
      );
      
      return rentalId;
    } catch (e) {
      throw Exception('Failed to create rental: ${e.toString()}');
    }
  }
  
  // 2. CHECK AVAILABILITY (FIXED VERSION)
  Future<bool> checkAvailability({
    required String equipmentId,
    required DateTime startDate,
    required DateTime endDate,
    int quantity = 1,
  }) async {
    try {
      // Get equipment document
      final equipmentDoc = await equipmentCollection.doc(equipmentId).get();
      
      if (!equipmentDoc.exists) {
        return false;
      }
      
      final equipmentData = equipmentDoc.data() as Map<String, dynamic>;
      
      // Check basic availability
      final availability = equipmentData['availability'] ?? false;
      if (!availability) {
        return false;
      }
      
      // Check quantity
      final totalQuantity = (equipmentData['quantity'] ?? 1) as int;
      final availableQuantity = (equipmentData['availableQuantity'] ?? totalQuantity) as int;
      
      if (availableQuantity < quantity) {
        return false;
      }
      
      // Check for overlapping reservations
      final overlappingQuery = await _firestore
          .collection('rentals')
          .where('equipmentId', isEqualTo: equipmentId)
          .where('status', whereIn: ['pending', 'approved', 'checked_out'])
          .get();
      
      int reservedCount = 0;
      for (final rentalDoc in overlappingQuery.docs) {
        final rentalData = rentalDoc.data() as Map<String, dynamic>;
        final rentalStart = DateTime.parse(rentalData['startDate']);
        final rentalEnd = DateTime.parse(rentalData['endDate']);
        
        // Check for date overlap
        if (startDate.isBefore(rentalEnd) && endDate.isAfter(rentalStart)) {
          reservedCount += (rentalData['quantity'] ?? 1) as int;
        }
      }
      
      final actuallyAvailable = availableQuantity - reservedCount;
      return actuallyAvailable >= quantity;
      
    } catch (e) {
      print('Error checking availability: $e');
      return false;
    }
  }
  
  // 3. GET USER'S RENTALS
  Stream<List<Rental>> getUserRentals() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);
    
    return rentalsCollection
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                try {
                  return Rental.fromMap(doc.data() as Map<String, dynamic>);
                } catch (e) {
                  print('Error parsing rental: $e');
                  return Rental.fromMap({}); // Return empty rental on error
                }
              })
              .where((rental) => rental.id.isNotEmpty) // Filter out empty rentals
              .toList();
        });
  }
  
  // 4. GET ALL RENTALS (FOR ADMIN)
  Stream<List<Rental>> getAllRentals() {
    return rentalsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                try {
                  return Rental.fromMap(doc.data() as Map<String, dynamic>);
                } catch (e) {
                  print('Error parsing rental: $e');
                  return Rental.fromMap({});
                }
              })
              .where((rental) => rental.id.isNotEmpty)
              .toList();
        });
  }
  
  // 5. UPDATE RENTAL STATUS (ADMIN)
  Future<void> updateRentalStatus({
    required String rentalId,
    required String status,
    String? adminNotes,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      if (adminNotes != null && adminNotes.isNotEmpty) {
        updateData['adminNotes'] = adminNotes;
      }
      
      // If marking as returned, release the equipment quantity
      if (status == 'returned') {
        final rentalDoc = await rentalsCollection.doc(rentalId).get();
        if (rentalDoc.exists) {
          final rentalData = rentalDoc.data() as Map<String, dynamic>;
          final equipmentId = rentalData['equipmentId'] as String;
          final quantity = (rentalData['quantity'] ?? 1) as int;
          
          // Get current available quantity
          final equipmentDoc = await equipmentCollection.doc(equipmentId).get();
          if (equipmentDoc.exists) {
            final equipmentData = equipmentDoc.data() as Map<String, dynamic>;
            final currentAvailable = (equipmentData['availableQuantity'] ?? 0) as int;
            
            // Add back the returned quantity
            await equipmentCollection.doc(equipmentId).update({
              'availableQuantity': currentAvailable + quantity,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
          
          // Add return date
          updateData['actualReturnDate'] = DateTime.now().toIso8601String();
        }
      }
      
      await rentalsCollection.doc(rentalId).update(updateData);
      
      // Send notification to user
      final rentalDoc = await rentalsCollection.doc(rentalId).get();
      if (rentalDoc.exists) {
        final rentalData = rentalDoc.data() as Map<String, dynamic>;
        final userId = rentalData['userId'] as String;
        final equipmentName = rentalData['equipmentName'] as String;
        
        String title = '';
        String message = '';
        
        switch (status) {
          case 'approved':
            title = 'Rental Approved';
            message = 'Your rental request for "$equipmentName" has been approved!';
            break;
          case 'checked_out':
            title = 'Equipment Checked Out';
            message = 'You have checked out "$equipmentName". Please return by the due date.';
            break;
          case 'returned':
            title = 'Rental Completed';
            message = 'Thank you for returning "$equipmentName" on time!';
            break;
          case 'cancelled':
            title = 'Rental Cancelled';
            message = 'Your rental for "$equipmentName" has been cancelled.';
            break;
        }
        
        if (title.isNotEmpty) {
          await _notificationService.sendNotification(
            userId: userId,
            title: title,
            message: message,
            type: 'approval',
            data: {'rentalId': rentalId},
          );
        }
      }
      
    } catch (e) {
      throw Exception('Failed to update rental status: $e');
    }
  }
  
  // 6. CANCEL RENTAL (USER)
  Future<void> cancelRental(String rentalId) async {
    try {
      final rentalDoc = await rentalsCollection.doc(rentalId).get();
      if (!rentalDoc.exists) {
        throw Exception('Rental not found');
      }
      
      final rentalData = rentalDoc.data() as Map<String, dynamic>;
      final status = rentalData['status'] as String;
      final userId = rentalData['userId'] as String;
      final user = _auth.currentUser;
      
      // Check ownership
      if (user?.uid != userId) {
        throw Exception('Not authorized to cancel this rental');
      }
      
      // Only allow cancellation if status is pending
      if (status != 'pending') {
        throw Exception('Cannot cancel rental with status: $status');
      }
      
      // Release equipment quantity
      final equipmentId = rentalData['equipmentId'] as String;
      final quantity = (rentalData['quantity'] ?? 1) as int;
      
      final equipmentDoc = await equipmentCollection.doc(equipmentId).get();
      if (equipmentDoc.exists) {
        final equipmentData = equipmentDoc.data() as Map<String, dynamic>;
        final currentAvailable = (equipmentData['availableQuantity'] ?? 0) as int;
        
        await equipmentCollection.doc(equipmentId).update({
          'availableQuantity': currentAvailable + quantity,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      // Update rental status
      await rentalsCollection.doc(rentalId).update({
        'status': 'cancelled',
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
    } catch (e) {
      throw Exception('Failed to cancel rental: $e');
    }
  }
  
  // 7. EXTEND RENTAL
  Future<void> extendRental({
    required String rentalId,
    required DateTime newEndDate,
  }) async {
    try {
      final rentalDoc = await rentalsCollection.doc(rentalId).get();
      if (!rentalDoc.exists) {
        throw Exception('Rental not found');
      }
      
      final rentalData = rentalDoc.data() as Map<String, dynamic>;
      final currentEndDate = DateTime.parse(rentalData['endDate']);
      
      if (newEndDate.isBefore(currentEndDate)) {
        throw Exception('New end date must be after current end date');
      }
      
      // Check availability for extended period
      final equipmentId = rentalData['equipmentId'] as String;
      final quantity = (rentalData['quantity'] ?? 1) as int;
      final startDate = DateTime.parse(rentalData['startDate']);
      
      final isAvailable = await checkAvailability(
        equipmentId: equipmentId,
        startDate: startDate,
        endDate: newEndDate,
        quantity: quantity,
      );
      
      if (!isAvailable) {
        throw Exception('Not available for extended period');
      }
      
      // Calculate additional cost
      final extraDays = newEndDate.difference(currentEndDate).inDays;
      final dailyRate = (rentalData['totalCost'] as double) / 
          (currentEndDate.difference(startDate).inDays);
      final additionalCost = extraDays * dailyRate * quantity;
      
      // Update rental
      await rentalsCollection.doc(rentalId).update({
        'endDate': newEndDate.toIso8601String(),
        'totalCost': (rentalData['totalCost'] as double) + additionalCost,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      
    } catch (e) {
      throw Exception('Failed to extend rental: $e');
    }
  }
  
  // 8. GET RENTAL BY ID
  Future<Rental> getRentalById(String rentalId) async {
    final rentalDoc = await rentalsCollection.doc(rentalId).get();
    
    if (!rentalDoc.exists) {
      throw Exception('Rental not found');
    }
    
    return Rental.fromMap(rentalDoc.data() as Map<String, dynamic>);
  }
  
  // 9. GET OVERDUE RENTALS
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
  
  // HELPER METHODS
  int _getMaxRentalDays(String itemType) {
    switch (itemType.toLowerCase()) {
      case 'wheelchair':
      case 'walker':
        return 30;
      case 'hospital bed':
      case 'oxygen machine':
        return 60;
      case 'crutches':
      case 'cane':
      case 'walking stick':
        return 14;
      case 'shower chair':
      case 'commode':
        return 21;
      default:
        return 30;
    }
  }
  
  // CALCULATE USER TRUST SCORE
  Future<int> calculateUserTrustScore(String userId) async {
    try {
      final userRentals = await rentalsCollection
          .where('userId', isEqualTo: userId)
          .get();
      
      if (userRentals.docs.isEmpty) return 0;
      
      int returnedCount = 0;
      int overdueCount = 0;
      int cancelledCount = 0;
      
      for (final doc in userRentals.docs) {
        final rentalData = doc.data() as Map<String, dynamic>;
        final status = rentalData['status'] as String;
        
        if (status == 'returned') returnedCount++;
        if (status == 'cancelled') cancelledCount++;
        
        // Check if overdue
        if (status == 'checked_out') {
          final endDate = DateTime.parse(rentalData['endDate']);
          if (endDate.isBefore(DateTime.now())) {
            overdueCount++;
          }
        }
      }
      
      // Simple trust score calculation
      int score = returnedCount * 10;
      score -= overdueCount * 20;
      score -= cancelledCount * 5;
      
      return score.clamp(0, 100);
    } catch (e) {
      print('Error calculating trust score: $e');
      return 0;
    }
  }
  
  // NOTIFY ADMINS
  Future<void> _notifyAdmins(String title, String message, String type, [Map<String, dynamic>? data]) async {
    try {
      final admins = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      for (var admin in admins.docs) {
        await _notificationService.sendNotification(
          userId: admin.id,
          title: title,
          message: message,
          type: type,
          data: data,
        );
      }
    } catch (e) {
      print('Error notifying admins: $e');
    }
  }
}