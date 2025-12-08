import 'package:flutter/material.dart';
import '../models/rental_model.dart';
import '../services/tracking_service.dart';

class TrackingProvider with ChangeNotifier {
  final TrackingService _service = TrackingService();
  List<Rental> _activeRentals = [];
  List<Rental> _rentalHistory = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = false;

  List<Rental> get activeRentals => _activeRentals;
  List<Rental> get rentalHistory => _rentalHistory;
  Map<String, dynamic> get stats => _stats;
  bool get isLoading => _isLoading;

  void trackUserRentals(String userId) {
    _service.trackUserRentals(userId).listen((rentals) {
      _activeRentals = rentals;
      notifyListeners();
    });
  }

  void trackAllRentals() {
    _service.trackAllActiveRentals().listen((rentals) {
      _activeRentals = rentals;
      notifyListeners();
    });
  }

  Future<void> loadUserHistory(String userId) async {
    _isLoading = true;
    notifyListeners();
    
    _rentalHistory = await _service.getUserRentalHistory(userId);
    _stats = await _service.getRentalStats(userId);
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadAllHistory() async {
    _isLoading = true;
    notifyListeners();
    
    _rentalHistory = await _service.getAllRentalHistory();
    
    _isLoading = false;
    notifyListeners();
  }
}
