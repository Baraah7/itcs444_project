//Current user + login state
// Manage current user state across the app
// lib/providers/auth_provider.dart

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.role == 'admin';
  bool get isRenter => _currentUser?.role == 'renter';
  bool get isGuest => _currentUser?.role == 'guest';

  // Register user
  Future<String?> registerUser(UserModel user, String password) async {
    try {
      UserModel newUser = await _authService.registerUser(user, password);
      _currentUser = newUser;
      notifyListeners();
      return null; // success
    } catch (e) {
      return e.toString(); // return error message
    }
  }

  // Login user
  Future<String?> loginUser(String email, String password) async {
    try {
      UserModel user = await _authService.loginUser(email, password);
      _currentUser = user;
      notifyListeners();
      return null; // success
    } catch (e) {
      return e.toString(); // return error message
    }
  }

  // Logout user
  Future<void> logoutUser() async {
    await _authService.logoutUser();
    _currentUser = null;
    notifyListeners();
  }

  // Update user profile
  Future<String?> updateProfile(UserModel updatedUser) async {
    try {
      await _authService.updateProfile(updatedUser);
      _currentUser = updatedUser;
      notifyListeners();
      return null; // success
    } catch (e) {
      return e.toString(); // return error message
    }
  }

  // Reload current user from Firestore (optional)
  Future<void> reloadUser() async {
    if (_currentUser != null) {
      UserModel user = await _authService.getUserById(_currentUser!.id);
      _currentUser = user;
      notifyListeners();
    }
  }
}
