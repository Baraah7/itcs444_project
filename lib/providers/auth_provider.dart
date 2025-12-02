// lib/providers/auth_provider.dart
// lib/providers/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  AppUser? _currentUser;
  bool _isLoading = false;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  bool get isLoggedIn => _currentUser != null;

  bool get isAdmin =>
      _currentUser?.role.toLowerCase() == 'admin';

  bool get isRenter =>
      _currentUser?.role.toLowerCase() == 'renter';

  bool get isDonor =>
      _currentUser?.role.toLowerCase() == 'donor';

  bool get isGuest => _currentUser == null;

  // ─────────────────────────────────────────────
  // REGISTER USER
  // ─────────────────────────────────────────────
  Future<bool> register(AppUser user, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      AppUser? createdUser = await _authService.registerUser(user, password);

      if (createdUser != null) {
        _currentUser = createdUser;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // LOGIN USER
  // ─────────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      AppUser? user = await _authService.login(email, password);

      if (user != null) {
        _currentUser = user;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // LOGOUT USER
  // ─────────────────────────────────────────────
  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // UPDATE PROFILE
  // ─────────────────────────────────────────────
  Future<bool> updateProfile(AppUser updatedUser) async {
    try {
      await _authService.usersCollection
          .doc(updatedUser.docId)
          .update(updatedUser.toMap());

      _currentUser = updatedUser;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // RELOAD CURRENT USER
  // ─────────────────────────────────────────────
  Future<void> reloadUser() async {
    if (_currentUser == null || _currentUser!.docId == null) return;

    DocumentSnapshot snapshot = await _authService.usersCollection
        .doc(_currentUser!.docId)
        .get();

    _currentUser = AppUser.fromFirestore(snapshot);
    notifyListeners();
  }
}
