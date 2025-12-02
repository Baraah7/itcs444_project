// lib/providers/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  AppUser? _currentUser;

  AppUser? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.role.toLowerCase() == 'admin';
  bool get isRenter => _currentUser?.role.toLowerCase() == 'renter';
  bool get isDonor => _currentUser?.role.toLowerCase() == 'donor';
  bool get isGuest => _currentUser == null;

  /// REGISTER USER
  Future<String?> registerUser(AppUser user) async {
    try {
      AppUser? newUser = await _authService.registerUser(user);
      if (newUser != null) {
        _currentUser = newUser;
        notifyListeners();
        return null; // success
      } else {
        return "Registration failed";
      }
    } catch (e) {
      return e.toString();
    }
  }

  /// LOGIN USER
  Future<String?> loginUser(String email, String password) async {
    try {
      AppUser? user = await _authService.login(email, password);
      if (user != null) {
        _currentUser = user;
        notifyListeners();
        return null; // success
      } else {
        return "Login failed";
      }
    } catch (e) {
      return e.toString();
    }
  }

  /// LOGOUT USER
  Future<void> logoutUser() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  /// UPDATE PROFILE
  Future<String?> updateProfile(AppUser updatedUser) async {
    try {
      // Update Firestore document
      await _authService.usersCollection
          .doc(updatedUser.docId)
          .update(updatedUser.toMap());

      _currentUser = updatedUser;
      notifyListeners();
      return null; // success
    } catch (e) {
      return e.toString();
    }
  }

  /// RELOAD CURRENT USER
  Future<void> reloadUser() async {
    if (_currentUser != null && _currentUser!.docId != null) {
      DocumentSnapshot snapshot = await _authService.usersCollection
          .doc(_currentUser!.docId)
          .get();
      _currentUser = AppUser.fromFirestore(snapshot);
      notifyListeners();
    }
  }
}
