//User's reservations + rental history
import 'package:flutter/foundation.dart';
import '../models/reservation_model.dart';
import '../models/equipment_model.dart';

class ReservationProvider extends ChangeNotifier {
  List<Reservation> _reservations = [];
  List<Reservation> _userReservations = [];
  
  // Current user ID (dummy for testing)
  String _currentUserId = 'user_001';
  String _currentUserName = 'John Doe';
  String _currentUserEmail = 'john.doe@example.com';
  String _currentUserPhone = '+1234567890';

  ReservationProvider() {
    _initializeDummyData();
  }

  void _initializeDummyData() {
    _reservations = [
      Reservation(
        id: 'res_001',
        equipmentId: 'eq_001',
        equipmentName: 'Standard Wheelchair',
        equipmentType: 'Wheelchair',
        userId: 'user_001',
        userName: 'John Doe',
        userEmail: 'john.doe@example.com',
        userPhone: '+1234567890',
        startDate: DateTime.now().add(const Duration(days: -5)),
        endDate: DateTime.now().add(const Duration(days: 2)),
        rentalDays: 7,
        dailyRate: 10.0,
        totalCost: 70.0,
        status: ReservationStatus.checkedOut,
        createdAt: DateTime.now().add(const Duration(days: -10)),
        notes: 'Need for hospital visit next week',
        equipmentImage: 'assets/wheelchair.jpg',
        approvedAt: DateTime.now().add(const Duration(days: -9)),
        checkedOutAt: DateTime.now().add(const Duration(days: -5)),
      ),
      Reservation(
        id: 'res_002',
        equipmentId: 'eq_002',
        equipmentName: 'Walker with Wheels',
        equipmentType: 'Walker',
        userId: 'user_002',
        userName: 'Jane Smith',
        userEmail: 'jane.smith@example.com',
        userPhone: '+0987654321',
        startDate: DateTime.now().add(const Duration(days: 3)),
        endDate: DateTime.now().add(const Duration(days: 10)),
        rentalDays: 7,
        dailyRate: 5.0,
        totalCost: 35.0,
        status: ReservationStatus.approved,
        createdAt: DateTime.now().add(const Duration(days: -2)),
        equipmentImage: 'assets/walker.jpg',
        approvedAt: DateTime.now().add(const Duration(days: -1)),
      ),
      Reservation(
        id: 'res_003',
        equipmentId: 'eq_003',
        equipmentName: 'Hospital Bed',
        equipmentType: 'Hospital Bed',
        userId: 'user_003',
        userName: 'Robert Johnson',
        userEmail: 'robert@example.com',
        userPhone: '+1122334455',
        startDate: DateTime.now().add(const Duration(days: -15)),
        endDate: DateTime.now().add(const Duration(days: -1)),
        rentalDays: 14,
        dailyRate: 20.0,
        totalCost: 280.0,
        status: ReservationStatus.returned,
        createdAt: DateTime.now().add(const Duration(days: -20)),
        equipmentImage: 'assets/bed.jpg',
        approvedAt: DateTime.now().add(const Duration(days: -19)),
        checkedOutAt: DateTime.now().add(const Duration(days: -15)),
        returnedAt: DateTime.now().add(const Duration(days: -1)),
      ),
      Reservation(
        id: 'res_004',
        equipmentId: 'eq_004',
        equipmentName: 'Oxygen Concentrator',
        equipmentType: 'Oxygen Machine',
        userId: 'user_004',
        userName: 'Sarah Williams',
        userEmail: 'sarah@example.com',
        userPhone: '+5566778899',
        startDate: DateTime.now().add(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 8)),
        rentalDays: 7,
        dailyRate: 30.0,
        totalCost: 210.0,
        status: ReservationStatus.pending,
        createdAt: DateTime.now(),
        notes: 'Required for post-surgery recovery for 1 week',
        equipmentImage: 'assets/oxygen.jpg',
      ),
      Reservation(
        id: 'res_005',
        equipmentId: 'eq_001',
        equipmentName: 'Standard Wheelchair',
        equipmentType: 'Wheelchair',
        userId: 'user_001',
        userName: 'John Doe',
        userEmail: 'john.doe@example.com',
        userPhone: '+1234567890',
        startDate: DateTime.now().add(const Duration(days: -30)),
        endDate: DateTime.now().add(const Duration(days: -23)),
        rentalDays: 7,
        dailyRate: 10.0,
        totalCost: 70.0,
        status: ReservationStatus.returned,
        createdAt: DateTime.now().add(const Duration(days: -35)),
        equipmentImage: 'assets/wheelchair.jpg',
        approvedAt: DateTime.now().add(const Duration(days: -34)),
        checkedOutAt: DateTime.now().add(const Duration(days: -30)),
        returnedAt: DateTime.now().add(const Duration(days: -23)),
      ),
    ];

    // Filter reservations for current user
    _userReservations = _reservations
        .where((r) => r.userId == _currentUserId)
        .toList();
  }

  // Getters
  List<Reservation> get reservations => _reservations;
  List<Reservation> get userReservations => _userReservations;
  String get currentUserId => _currentUserId;
  String get currentUserName => _currentUserName;
  String get currentUserEmail => _currentUserEmail;
  String get currentUserPhone => _currentUserPhone;

  List<Reservation> get pendingReservations =>
      _reservations.where((r) => r.status == ReservationStatus.pending).toList();

  List<Reservation> get activeReservations => _reservations
      .where((r) => r.status == ReservationStatus.approved || 
                     r.status == ReservationStatus.checkedOut)
      .toList();

  List<Reservation> get overdueReservations =>
      _reservations.where((r) => r.isOverdue).toList();

  // Check equipment availability for given dates
  bool isEquipmentAvailable({
    required String equipmentId,
    required DateTime startDate,
    required DateTime endDate,
    String? excludeReservationId,
  }) {
    final equipmentReservations = _reservations
        .where((r) => r.equipmentId == equipmentId && 
               r.id != excludeReservationId)
        .toList();
    
    for (final reservation in equipmentReservations) {
      // Skip cancelled, rejected, and returned reservations
      if (reservation.status == ReservationStatus.cancelled ||
          reservation.status == ReservationStatus.rejected ||
          reservation.status == ReservationStatus.returned) {
        continue;
      }
      
      // Check for date overlap
      final overlap = (startDate.isBefore(reservation.endDate) && 
                       endDate.isAfter(reservation.startDate));
      
      if (overlap) {
        return false;
      }
    }
    
    return true;
  }

  // Add new reservation
  void addReservation(Reservation reservation) {
    _reservations.insert(0, reservation);
    
    if (reservation.userId == _currentUserId) {
      _userReservations.insert(0, reservation);
    }
    
    notifyListeners();
  }

  // Create reservation from equipment
  Reservation createReservation({
    required Equipment equipment,
    required DateTime startDate,
    required DateTime endDate,
    required String notes,
  }) {
    final rentalDays = endDate.difference(startDate).inDays;
    final dailyRate = equipment.rentalPricePerDay ?? 0.0;
    final totalCost = dailyRate * rentalDays;
    
    return Reservation(
      id: 'res_${DateTime.now().millisecondsSinceEpoch}',
      equipmentId: equipment.id,
      equipmentName: equipment.name,
      equipmentType: equipment.type.name,
      userId: _currentUserId,
      userName: _currentUserName,
      userEmail: _currentUserEmail,
      userPhone: _currentUserPhone,
      startDate: startDate,
      endDate: endDate,
      rentalDays: rentalDays,
      dailyRate: dailyRate,
      totalCost: totalCost,
      status: ReservationStatus.pending,
      createdAt: DateTime.now(),
      notes: notes,
      equipmentImage: equipment.images.isNotEmpty ? equipment.images[0] : null,
    );
  }

  // Update reservation status
  void updateReservationStatus(String reservationId, ReservationStatus newStatus) {
    final index = _reservations.indexWhere((r) => r.id == reservationId);
    
    if (index != -1) {
      final reservation = _reservations[index];
      final updatedReservation = reservation.copyWith(
        status: newStatus,
        approvedAt: newStatus == ReservationStatus.approved ? DateTime.now() : reservation.approvedAt,
        checkedOutAt: newStatus == ReservationStatus.checkedOut ? DateTime.now() : reservation.checkedOutAt,
        returnedAt: newStatus == ReservationStatus.returned ? DateTime.now() : reservation.returnedAt,
        cancelledAt: newStatus == ReservationStatus.cancelled ? DateTime.now() : reservation.cancelledAt,
      );
      
      _reservations[index] = updatedReservation;
      
      // Update in user reservations if exists
      final userIndex = _userReservations.indexWhere((r) => r.id == reservationId);
      if (userIndex != -1) {
        _userReservations[userIndex] = updatedReservation;
      }
      
      notifyListeners();
    }
  }

  // Quick action methods
  void approveReservation(String reservationId) {
    updateReservationStatus(reservationId, ReservationStatus.approved);
  }

  void rejectReservation(String reservationId, {String? adminNotes}) {
    final index = _reservations.indexWhere((r) => r.id == reservationId);
    
    if (index != -1) {
      final reservation = _reservations[index];
      final updatedReservation = reservation.copyWith(
        status: ReservationStatus.rejected,
        adminNotes: adminNotes,
      );
      
      _reservations[index] = updatedReservation;
      
      final userIndex = _userReservations.indexWhere((r) => r.id == reservationId);
      if (userIndex != -1) {
        _userReservations[userIndex] = updatedReservation;
      }
      
      notifyListeners();
    }
  }

  void checkOutReservation(String reservationId) {
    updateReservationStatus(reservationId, ReservationStatus.checkedOut);
  }

  void returnReservation(String reservationId) {
    updateReservationStatus(reservationId, ReservationStatus.returned);
  }

  void cancelReservation(String reservationId) {
    updateReservationStatus(reservationId, ReservationStatus.cancelled);
  }

  // Get reservation by ID
  Reservation? getReservationById(String id) {
    try {
      return _reservations.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get reservations for equipment
  List<Reservation> getReservationsByEquipmentId(String equipmentId) {
    return _reservations
        .where((r) => r.equipmentId == equipmentId)
        .toList();
  }

  // Get reservations for user
  List<Reservation> getReservationsByUserId(String userId) {
    return _reservations
        .where((r) => r.userId == userId)
        .toList();
  }

  // Statistics
  Map<String, dynamic> getReservationStats() {
    final total = _reservations.length;
    final pending = pendingReservations.length;
    final active = activeReservations.length;
    final overdue = overdueReservations.length;
    final completed = _reservations
        .where((r) => r.status == ReservationStatus.returned)
        .length;
    final cancelled = _reservations
        .where((r) => r.status == ReservationStatus.cancelled)
        .length;

    return {
      'total': total,
      'pending': pending,
      'active': active,
      'overdue': overdue,
      'completed': completed,
      'cancelled': cancelled,
    };
  }

  Map<String, dynamic> getUserReservationStats() {
    final userReservations = _userReservations;
    final total = userReservations.length;
    final pending = userReservations
        .where((r) => r.status == ReservationStatus.pending)
        .length;
    final active = userReservations
        .where((r) => r.status == ReservationStatus.approved || 
                      r.status == ReservationStatus.checkedOut)
        .length;
    final completed = userReservations
        .where((r) => r.status == ReservationStatus.returned)
        .length;
    final cancelled = userReservations
        .where((r) => r.status == ReservationStatus.cancelled)
        .length;

    return {
      'total': total,
      'pending': pending,
      'active': active,
      'completed': completed,
      'cancelled': cancelled,
    };
  }

  // Calculate recommended duration based on equipment type
  int getRecommendedDuration(String equipmentType) {
    switch (equipmentType.toLowerCase()) {
      case 'wheelchair':
      case 'walker':
      case 'crutches':
        return 7; // 1 week
      case 'hospital bed':
      case 'oxygen machine':
        return 14; // 2 weeks
      case 'shower chair':
      case 'commode':
        return 30; // 1 month
      default:
        return 7; // Default 1 week
    }
  }

  // Get upcoming reservations (within next 7 days)
  List<Reservation> getUpcomingReservations() {
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));
    
    return _userReservations
        .where((r) => 
            (r.status == ReservationStatus.approved || 
             r.status == ReservationStatus.checkedOut) &&
            r.startDate.isAfter(now) &&
            r.startDate.isBefore(nextWeek))
        .toList();
  }

  // Get reservations requiring action (pending or overdue)
  List<Reservation> getReservationsRequiringAction() {
    return _userReservations
        .where((r) => 
            r.status == ReservationStatus.pending ||
            r.isOverdue)
        .toList();
  }
}