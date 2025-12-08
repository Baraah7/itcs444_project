// lib/services/reservation_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReservationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;



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
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
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
}