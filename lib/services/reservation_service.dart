// lib/services/reservation_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
      
      // Create rental document
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
      
      // Save rental
      await rentalRef.set(rental.toMap());
      
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
    required String itemId,
    required String equipmentName,
    required String itemName,
    required DateTime startDate,
    required DateTime endDate,
    required String userEmail,
    required String userName,
    double? dailyRate,
    String? notes,
  }) async {
    try {
      final totalDays = _calculateDays(startDate, endDate);
      final totalPrice = dailyRate != null ? dailyRate * totalDays : 0.0;

      final isAvailable = await checkItemAvailability(
        itemId: itemId,
        equipmentId: equipmentId,
        startDate: startDate,
        endDate: endDate,
      );

      if (!isAvailable) {
        return {
          'success': false,
          'message': 'Item is no longer available for the selected dates'
        };
      }

      final reservationRef = _firestore.collection('reservations').doc();
      final reservationId = reservationRef.id;
      
      final reservationData = {
        'id': reservationId,
        'userId': userId,
        'userEmail': userEmail,
        'userName': userName,
        'equipmentId': equipmentId,
        'equipmentName': equipmentName,
        'itemId': itemId,
        'itemName': itemName,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'totalDays': totalDays,
        'dailyRate': dailyRate,
        'totalPrice': totalPrice,
        'status': 'pending',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'pickupDate': null,
        'returnDate': null,
        'notes': notes ?? '',
      };

      await reservationRef.set(reservationData);
      
      await _firestore
          .collection('equipment')
          .doc(equipmentId)
          .collection('Items')
          .doc(itemId)
          .update({
            'lastReservationId': reservationId,
            'lastReservationDate': Timestamp.now(),
          });

      return {
        'success': true,
        'message': 'Reservation created successfully!',
        'reservationId': reservationId,
      };
    } catch (e) {
      debugPrint('Error creating reservation: $e');
      return {
        'success': false,
        'message': 'Failed to create reservation. Please try again.'
      };
    }
  }

  Future<List<Map<String, dynamic>>> getItemReservations({
  required String itemId,
  required String equipmentId,
}) async {
  try {
    final reservations = await _firestore
        .collection('reservations')
        .where('itemId', isEqualTo: itemId)
        .where('equipmentId', isEqualTo: equipmentId)
        .where('status', whereIn: ['confirmed', 'active']) // REMOVED 'pending'
        .orderBy('startDate')
        .get();

    return reservations.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      final startDate = data?['startDate'] as Timestamp?;
      final endDate = data?['endDate'] as Timestamp?;
      
      return {
        'id': doc.id,
        ...?data,
        'startDate': startDate?.toDate() ?? DateTime.now(),
        'endDate': endDate?.toDate() ?? DateTime.now(),
      };
    }).toList();
  } catch (e) {
    debugPrint('Error getting reservations: $e');
    return [];
  }
}

  Future<bool> cancelReservation(String reservationId) async {
    try {
      await _firestore
          .collection('reservations')
          .doc(reservationId)
          .update({
            'status': 'cancelled',
            'updatedAt': Timestamp.now(),
          });
      return true;
    } catch (e) {
      debugPrint('Error cancelling reservation: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getUserReservations(String userId) async {
    try {
      final reservations = await _firestore
          .collection('reservations')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return reservations.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?; // ADD CAST HERE
        final startDate = data?['startDate'] as Timestamp?;
        final endDate = data?['endDate'] as Timestamp?;
        final createdAt = data?['createdAt'] as Timestamp?;
        
        return {
          'id': doc.id,
          ...?data, // FIXED: Use ...? instead of ...
          'startDate': startDate?.toDate() ?? DateTime.now(),
          'endDate': endDate?.toDate() ?? DateTime.now(),
          'createdAt': createdAt?.toDate() ?? DateTime.now(),
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting user reservations: $e');
      return [];
    }
  }

  Stream<List<Map<String, dynamic>>> getUserRentals() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);
    
    return _firestore
        .collection('reservations')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
          final rentals = snapshot.docs
              .map((doc) {
                try {
                  return Rental.fromMap(doc.data() as Map<String, dynamic>);
                } catch (e) {
                  print('Error parsing rental: $e');
                  return null;
                }
              })
              .where((rental) => rental != null && rental.id.isNotEmpty)
              .cast<Rental>()
              .toList();
          
          rentals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return rentals;
        });
  }
  
  // 4. GET ALL RENTALS (FOR ADMIN)
  Stream<List<Rental>> getAllRentals() {
    return rentalsCollection.snapshots().map((snapshot) {
      print('getAllRentals: Got ${snapshot.docs.length} documents');
      final rentals = <Rental>[];
      
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          print('Processing rental: ${doc.id}');
          final rental = Rental.fromMap(data);
          rentals.add(rental);
        } catch (e) {
          print('Error parsing rental ${doc.id}: $e');
        }
      }
      
      print('getAllRentals: Returning ${rentals.length} rentals');
      rentals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return rentals;
    });
  }

  Future<void> updateReservationStatus({
    required String reservationId,
    required String status,
    String? adminNotes,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
        'updatedAt': Timestamp.now(),
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