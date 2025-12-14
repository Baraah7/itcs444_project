import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/rental_model.dart';
import 'notification_service.dart';
import 'equipment_service.dart';
import '../widgets/AdminNotificationsScreen.dart';
import '../services/notification_service.dart';

class ReservationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();
  final EquipmentService _equipmentService = EquipmentService();

  // Collection references
  CollectionReference get rentalsCollection => _firestore.collection('rentals');
  CollectionReference get equipmentCollection =>
      _firestore.collection('equipment');
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
        throw Exception(
          'User profile not found. Please complete your profile.',
        );
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      var userFullName =
          '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();
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

      // Check available quantity
      final availableQty = await _equipmentService.getAvailableQuantity(
        equipmentId,
      );
      if (quantity > availableQty) {
        throw Exception(
          'Only $availableQty item(s) available. You requested $quantity.',
        );
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

      // Don't sync equipment on pending - wait for admin approval

      // Notify admins only (user already knows they submitted the request)
     await _notificationService.sendAdminNotification(
  title: 'New Rental Request',
  message: 'User ${firebaseUser.email} submitted a rental request for "$equipmentName".',
  type: 'reservation_submitted',
  data: {'rentalId': rentalId, 'userId': firebaseUser.uid},
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
    String? excludeRentalId,
  }) async {
    try {
      // Get equipment document
      final equipmentDoc = await equipmentCollection.doc(equipmentId).get();

      if (!equipmentDoc.exists) {
        return false;
      }

      final equipmentData = equipmentDoc.data() as Map<String, dynamic>;

      // Check quantity
      final totalQuantity = (equipmentData['quantity'] ?? 1) as int;
      final availableQuantity =
          (equipmentData['availableQuantity'] ?? totalQuantity) as int;

      // Check for overlapping reservations
      final overlappingQuery = await _firestore
          .collection('rentals')
          .where('equipmentId', isEqualTo: equipmentId)
          .where('status', whereIn: ['pending', 'approved', 'checked_out'])
          .get();

      int reservedCount = 0;
      int excludedRentalQuantity = 0;

      for (final rentalDoc in overlappingQuery.docs) {
        final rentalData = rentalDoc.data() as Map<String, dynamic>;

        // Track the quantity of the rental we're extending
        if (excludeRentalId != null && rentalDoc.id == excludeRentalId) {
          excludedRentalQuantity = (rentalData['quantity'] ?? 1) as int;
          continue;
        }

        final rentalStart = DateTime.parse(rentalData['startDate']);
        final rentalEnd = DateTime.parse(rentalData['endDate']);

        // Check for date overlap (excluding touching boundaries)
        // Two periods overlap if: start1 < end2 AND end1 > start2
        // But we want to allow touching: if end1 == start2 or start1 == end2, no overlap
        if (startDate.isBefore(rentalEnd) &&
            endDate.isAfter(rentalStart) &&
            !startDate.isAtSameMomentAs(rentalEnd) &&
            !endDate.isAtSameMomentAs(rentalStart)) {
          reservedCount += (rentalData['quantity'] ?? 1) as int;
        }
      }

      // When extending, add back the quantity from the excluded rental
      // because those items are already in use by that rental
      final effectiveAvailable = availableQuantity + excludedRentalQuantity;
      final actuallyAvailable = effectiveAvailable - reservedCount;

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
        .snapshots()
        .map((snapshot) {
          final rentals = snapshot.docs
              .map((doc) {
                try {
                  final data = doc.data() as Map<String, dynamic>;
                  if (data['hiddenFromUser'] == true) return null;
                  return Rental.fromMap(data);
                } catch (e) {
                  print('Error parsing rental: $e');
                  return null;
                }
              })
              .where(
                (rental) =>
                    rental != null &&
                    rental.id.isNotEmpty &&
                    rental.status != 'maintenance',
              )
              .cast<Rental>()
              .toList();

          rentals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return rentals;
        });
  }

  // 4. GET ALL RENTALS (FOR ADMIN)
  Stream<List<Rental>> getAllRentals() {
    return rentalsCollection
        .where('status', whereNotIn: ['available', 'maintenance', 'cancelled'])
        .snapshots()
        .map((snapshot) {
      final rentals = <Rental>[];

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final rental = Rental.fromMap(data);
          rentals.add(rental);
        } catch (e) {
          print('Error parsing rental ${doc.id}: $e');
        }
      }

      rentals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return rentals;
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

      // Get rental data for equipment sync
      final rentalDoc = await rentalsCollection.doc(rentalId).get();
      if (!rentalDoc.exists) {
        throw Exception('Rental not found');
      }

      final rentalData = rentalDoc.data() as Map<String, dynamic>;
      final equipmentId = rentalData['equipmentId'] as String;
      final quantity = (rentalData['quantity'] ?? 1) as int;

      // If marking as returned, release the equipment quantity
      if (status == 'returned') {
        // Add return date
        updateData['actualReturnDate'] = DateTime.now().toIso8601String();
      }

      await rentalsCollection.doc(rentalId).update(updateData);

      // Sync equipment status
      await _equipmentService.syncEquipmentWithRental(
        equipmentId: equipmentId,
        rentalStatus: status,
        quantity: quantity,
      );

      // Send notification to user
      final userId = rentalData['userId'] as String;
      final equipmentName = rentalData['equipmentName'] as String;

      String title = '';
      String message = '';

      switch (status) {
        case 'approved':
          title = 'Rental Approved';
          message =
              'Your rental request for "$equipmentName" has been approved!';
          break;
        case 'checked_out':
          title = 'Equipment Picked Up';
          message =
              'You have picked up "$equipmentName". Please return by the due date.';
          break;
        case 'returned':
          title = 'Rental Completed';
          message = 'Thank you for returning "$equipmentName" on time!';
          break;
        case 'cancelled':
          title = 'Rental Cancelled';
          message = 'Your rental for "$equipmentName" has been cancelled.';
          break;
        case 'maintenance':
          // No notification sent to user for maintenance
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

      // Only allow cancellation if status is pending or approved
      if (status != 'pending' && status != 'approved') {
        throw Exception('Cannot cancel rental with status: $status');
      }

      // Update rental status
      await rentalsCollection.doc(rentalId).update({
        'status': 'cancelled',
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Release equipment quantity
      final equipmentId = rentalData['equipmentId'] as String;
      final quantity = (rentalData['quantity'] ?? 1) as int;

      await _equipmentService.syncEquipmentWithRental(
        equipmentId: equipmentId,
        rentalStatus: 'cancelled',
        quantity: quantity,
      );

      // Notify admins if it was an approved reservation
      if (status == 'approved') {
        final equipmentName = rentalData['equipmentName'] as String;
        final userFullName = rentalData['userFullName'] as String;

        await _notificationService.sendAdminNotification(
          title: 'Approved Reservation Cancelled',
          message: 'User $userFullName cancelled their approved reservation for "$equipmentName"',
          type: 'cancellation',
          data: {'rentalId': rentalId},
        );
      }
    } catch (e) {
      throw Exception('Failed to cancel rental: $e');
    }
  }

  // HIDE RENTAL FROM MY RESERVATIONS (USER)
  Future<void> deleteRental(String rentalId) async {
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
        throw Exception('Not authorized to delete this rental');
      }

      // Only allow deletion if status is cancelled or returned
      if (status != 'cancelled' && status != 'returned') {
        throw Exception('Can only delete cancelled or returned reservations');
      }

      // Mark as hidden instead of deleting
      await rentalsCollection.doc(rentalId).update({'hiddenFromUser': true});
    } catch (e) {
      throw Exception('Failed to delete rental: $e');
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
      final startDate = DateTime.parse(rentalData['startDate']);

      if (newEndDate.isBefore(currentEndDate) ||
          newEndDate.isAtSameMomentAs(currentEndDate)) {
        throw Exception('New end date must be after current end date');
      }

      final equipmentId = rentalData['equipmentId'] as String;
      final quantity = (rentalData['quantity'] ?? 1) as int;

      // Check availability for the extension period only (from current end to new end)
      // We check slightly before current end to catch any overlapping rentals
      final isAvailable = await checkAvailability(
        equipmentId: equipmentId,
        startDate: currentEndDate,
        endDate: newEndDate,
        quantity: quantity,
        excludeRentalId: rentalId,
      );

      if (!isAvailable) {
        throw Exception('Not available for extended period');
      }

      // Calculate additional cost
      final extraDays = newEndDate.difference(currentEndDate).inDays;
      final totalDays = currentEndDate.difference(startDate).inDays;
      final dailyRate = totalDays > 0
          ? (rentalData['totalCost'] as double) / totalDays
          : 0.0;
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

}
