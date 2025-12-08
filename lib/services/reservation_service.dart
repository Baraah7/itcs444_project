// lib/services/reservation_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
<<<<<<< HEAD
=======
import '../models/rental_model.dart';
import '../models/equipment_model.dart';
import 'notification_service.dart';
>>>>>>> Task1

class ReservationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
<<<<<<< HEAD



  // Check if an item is available for specific dates
Future<bool> checkItemAvailability({
  required String itemId,
  required String equipmentId,
  required DateTime startDate,
  required DateTime endDate,
  String? excludeReservationId,
}) async {
  try {
    // Check if item exists and is available
    final itemDoc = await _firestore
        .collection('equipment')
        .doc(equipmentId)
        .collection('Items')
        .doc(itemId)
        .get();

    if (!itemDoc.exists) {
      debugPrint('Item not found: $itemId');
      return false;
    }

    final itemData = itemDoc.data();
    if (itemData == null || itemData['availability'] != true) {
      debugPrint('Item not available: ${itemData?['availability']}');
      return false;
    }

    // Check for overlapping reservations
    // ONLY check 'confirmed' and 'active' reservations (not 'pending')
    final reservationsQuery = await _firestore
        .collection('reservations')
        .where('itemId', isEqualTo: itemId)
        .where('status', whereIn: ['confirmed', 'active'])
        .get();

    debugPrint('Found ${reservationsQuery.docs.length} active reservations');

    for (final reservation in reservationsQuery.docs) {
      final data = reservation.data();
      final reservationStart = (data['startDate'] as Timestamp).toDate();
      final reservationEnd = (data['endDate'] as Timestamp).toDate();

      debugPrint('Reservation: ${reservationStart} to ${reservationEnd}');
      debugPrint('Requested: $startDate to $endDate');

      // Check if dates overlap
      bool overlaps = startDate.isBefore(reservationEnd) && 
                      endDate.isAfter(reservationStart);
      
      if (overlaps) {
        debugPrint('Date overlap detected!');
        return false;
      }
    }

    return true;
  } catch (e) {
    debugPrint('Error checking availability: $e');
    return false;
  }
}

  bool _datesOverlap(Timestamp newStart, Timestamp newEnd, Timestamp existingStart, Timestamp existingEnd) {
    return (newStart.toDate().isBefore(existingEnd.toDate()) &&
        newEnd.toDate().isAfter(existingStart.toDate()));
  }

  int _calculateDays(DateTime start, DateTime end) {
    return end.difference(start).inDays + 1;
  }

  Future<Map<String, dynamic>> createReservation({
    required String userId,
=======
  final NotificationService _notificationService = NotificationService();
  
  // Collection references
  CollectionReference get rentalsCollection => _firestore.collection('rentals');
  CollectionReference get equipmentCollection => _firestore.collection('equipment');
  CollectionReference get usersCollection => _firestore.collection('users');
  
  // 1. CREATE A NEW RENTAL (FIXED VERSION)
  Future<String> createRental({
>>>>>>> Task1
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
      
<<<<<<< HEAD
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
=======
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
>>>>>>> Task1
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
<<<<<<< HEAD
          return snapshot.docs.map((doc) {
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
        });
  }

  Future<void> updateReservationStatus({
    required String reservationId,
=======
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
  
  // 5. UPDATE RENTAL STATUS (ADMIN)
  Future<void> updateRentalStatus({
    required String rentalId,
>>>>>>> Task1
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
      
      await _firestore
          .collection('reservations')
          .doc(reservationId)
          .update(updateData);
      
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
      throw Exception('Failed to update reservation status: $e');
    }
  }

  Future<Map<String, dynamic>?> getReservationById(String reservationId) async {
    try {
      final doc = await _firestore.collection('reservations').doc(reservationId).get();
      
      if (!doc.exists) return null;
      
      final data = doc.data() as Map<String, dynamic>?; // ADD CAST HERE
      if (data == null) return null;
      
      final startDate = data?['startDate'] as Timestamp?;
      final endDate = data?['endDate'] as Timestamp?;
      final createdAt = data?['createdAt'] as Timestamp?;
      
      return {
        'id': doc.id,
        ...data,
        'startDate': startDate?.toDate() ?? DateTime.now(),
        'endDate': endDate?.toDate() ?? DateTime.now(),
        'createdAt': createdAt?.toDate() ?? DateTime.now(),
      };
    } catch (e) {
      debugPrint('Error getting reservation: $e');
      return null;
    }
  }
    Stream<List<Map<String, dynamic>>> getAllReservationsStream() {
    return _firestore
        .collection('reservations')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) return <String, dynamic>{};
            
            final startDate = data?['startDate'] as Timestamp?;
            final endDate = data?['endDate'] as Timestamp?;
            final createdAt = data?['createdAt'] as Timestamp?;
            
            return {
              'id': doc.id,
              ...?data,
              'startDate': startDate?.toDate() ?? DateTime.now(),
              'endDate': endDate?.toDate() ?? DateTime.now(),
              'createdAt': createdAt?.toDate() ?? DateTime.now(),
            };
          }).toList();
        });
    }
<<<<<<< HEAD
=======
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
>>>>>>> Task1
}