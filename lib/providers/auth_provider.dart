//Current user + login state
<<<<<<< HEAD
// Manage current user state across the app
// lib/providers/auth_provider.dart
=======
>>>>>>> ad84b937b4b4d482bcedc774ccf75ecb50ff5a5b

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

<<<<<<< HEAD
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
=======
  AppUser? currentUser;
  bool isLoading = false;

  Future<bool> login(String email, String password) async {
    isLoading = true;
    notifyListeners();

    currentUser = await _authService.login(email, password);

    isLoading = false;
    notifyListeners();

    return currentUser != null;
  }

  Future<bool> register(AppUser user) async {
    isLoading = true;
    notifyListeners();

    currentUser = await _authService.registerUser(user);

    isLoading = false;
    notifyListeners();

    return currentUser != null;
  }

  Future<void> logout() async {
    await _authService.logout();
    currentUser = null;
    notifyListeners();
  }
>>>>>>> ad84b937b4b4d482bcedc774ccf75ecb50ff5a5b
}
