//User's reservations + rental history
import 'package:flutter/foundation.dart';
import '../models/reservation_model.dart';
import '../models/equipment_model.dart';

class ReservationProvider with ChangeNotifier {
  List<Reservation> _reservations = [];
  List<Reservation> _userReservations = [];
  bool _isLoading = false;
  String? _error;
  String _currentUserId = '';

  List<Reservation> get allReservations => _reservations;
  List<Reservation> get userReservations => _userReservations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize with sample data
  ReservationProvider() {
    _initializeSampleData();
  }

  void _initializeSampleData() {
    _reservations = [
      Reservation(
        id: '1',
        userId: 'user-001',
        equipmentId: '1',
        equipmentName: 'Excavator CAT 320',
        startDate: DateTime.now().add(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 5)),
        status: ReservationStatus.confirmed,
        totalPrice: 12500.0,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        notes: 'Need for construction project',
      ),
      Reservation(
        id: '2',
        userId: 'user-001',
        equipmentId: '4',
        equipmentName: 'Scissor Lift',
        startDate: DateTime.now().add(const Duration(days: 10)),
        endDate: DateTime.now().add(const Duration(days: 12)),
        status: ReservationStatus.pending,
        totalPrice: 2400.0,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        notes: 'For building maintenance',
      ),
      Reservation(
        id: '3',
        userId: 'user-002',
        equipmentId: '2',
        equipmentName: 'Bulldozer Komatsu',
        startDate: DateTime.now().subtract(const Duration(days: 3)),
        endDate: DateTime.now().add(const Duration(days: 2)),
        status: ReservationStatus.active,
        totalPrice: 15000.0,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];
    
    _updateUserReservations();
  }

  // Set current user ID
  void setCurrentUserId(String userId) {
    _currentUserId = userId;
    _updateUserReservations();
  }

  // Update user-specific reservations
  void _updateUserReservations() {
    if (_currentUserId.isNotEmpty) {
      _userReservations = _reservations
          .where((reservation) => reservation.userId == _currentUserId)
          .toList();
    } else {
      _userReservations = [];
    }
    notifyListeners();
  }

  // Create new reservation
  Future<Reservation> createReservation({
    required String equipmentId,
    required String equipmentName,
    required DateTime startDate,
    required DateTime endDate,
    required double dailyRate,
    String? notes,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      final durationInDays = endDate.difference(startDate).inDays;
      final totalPrice = dailyRate * durationInDays;

      final newReservation = Reservation(
        id: 'res-${DateTime.now().millisecondsSinceEpoch}',
        userId: _currentUserId,
        equipmentId: equipmentId,
        equipmentName: equipmentName,
        startDate: startDate,
        endDate: endDate,
        status: ReservationStatus.pending,
        totalPrice: totalPrice,
        createdAt: DateTime.now(),
        notes: notes,
      );

      _reservations.insert(0, newReservation);
      _updateUserReservations();
      notifyListeners();

      return newReservation;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Update reservation status
  Future<void> updateReservationStatus(
    String reservationId,
    ReservationStatus newStatus,
  ) async {
    _setLoading(true);
    _error = null;

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      final index = _reservations.indexWhere((r) => r.id == reservationId);
      if (index != -1) {
        final updatedReservation = _reservations[index].copyWith(status: newStatus);
        _reservations[index] = updatedReservation;
        _updateUserReservations();
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Cancel reservation
  Future<void> cancelReservation(String reservationId) async {
    await updateReservationStatus(reservationId, ReservationStatus.cancelled);
  }

  // Confirm reservation
  Future<void> confirmReservation(String reservationId) async {
    await updateReservationStatus(reservationId, ReservationStatus.confirmed);
  }

  // Complete reservation
  Future<void> completeReservation(String reservationId) async {
    await updateReservationStatus(reservationId, ReservationStatus.completed);
  }

  // Get reservation by ID
  Reservation? getReservationById(String id) {
    try {
      return _reservations.firstWhere((reservation) => reservation.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get reservations by equipment ID
  List<Reservation> getReservationsByEquipmentId(String equipmentId) {
    return _reservations
        .where((reservation) => reservation.equipmentId == equipmentId)
        .toList();
  }

  // Check if equipment is available for dates
  bool isEquipmentAvailable(
    String equipmentId,
    DateTime startDate,
    DateTime endDate,
    String? excludeReservationId,
  ) {
    final equipmentReservations = getReservationsByEquipmentId(equipmentId)
        .where((reservation) => reservation.status != ReservationStatus.cancelled)
        .where((reservation) => excludeReservationId == null || reservation.id != excludeReservationId);

    for (final reservation in equipmentReservations) {
      // Check for date overlap
      if (startDate.isBefore(reservation.endDate) && endDate.isAfter(reservation.startDate)) {
        return false;
      }
    }

    return true;
  }

  // Get pending reservations count (for admin)
  int get pendingReservationsCount {
    return _reservations
        .where((reservation) => reservation.status == ReservationStatus.pending)
        .length;
  }

  // Get active reservations count
  int get activeReservationsCount {
    return _reservations
        .where((reservation) => reservation.status == ReservationStatus.active)
        .length;
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}