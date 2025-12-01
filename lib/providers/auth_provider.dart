//Current user + login state
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;

  // Simulate login process
  Future<void> login(String email, String password) async {
    _setLoading(true);
    _error = null;

    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 2));

      // Mock authentication - replace with actual Firebase Auth
      if (email == 'admin@example.com' && password == 'admin123') {
        _user = User(
          uid: 'admin-001',
          email: email,
          name: 'Admin User',
          role: 'admin',
          phoneNumber: '+1234567890',
          createdAt: DateTime.now(),
          isEmailVerified: true,
        );
      } else if (email == 'user@example.com' && password == 'user123') {
        _user = User(
          uid: 'user-001',
          email: email,
          name: 'Regular User',
          role: 'user',
          phoneNumber: '+1234567891',
          createdAt: DateTime.now(),
          isEmailVerified: true,
        );
      } else {
        throw Exception('Invalid email or password');
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Simulate registration process
  Future<void> register(String email, String password, String name, String phone) async {
    _setLoading(true);
    _error = null;

    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 2));

      // Mock registration - replace with actual Firebase Auth
      _user = User(
        uid: 'user-${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        name: name,
        role: 'user',
        phoneNumber: phone,
        createdAt: DateTime.now(),
        isEmailVerified: false,
      );

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Logout user
  Future<void> logout() async {
    _setLoading(true);
    
    try {
      // Simulate logout delay
      await Future.delayed(const Duration(seconds: 1));
      
      _user = null;
      _error = null;
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Update user profile
  Future<void> updateProfile({
    String? name,
    String? phoneNumber,
    String? address,
  }) async {
    if (_user == null) return;

    _setLoading(true);

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      _user = _user!.copyWith(
        name: name,
        phoneNumber: phoneNumber,
        address: address,
      );

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
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

  // Initialize auth state (for app startup)
  Future<void> initialize() async {
    _setLoading(true);
    
    // Check if user is already logged in (from local storage)
    // This is a mock implementation - replace with actual persistence
    await Future.delayed(const Duration(seconds: 1));
    
    _setLoading(false);
  }
}