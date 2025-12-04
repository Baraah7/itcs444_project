import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  AppUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.role.toLowerCase() == 'admin';
  bool get isRenter => _currentUser?.role.toLowerCase() == 'renter';
  bool get isDonor => _currentUser?.role.toLowerCase() == 'donor';
  bool get isGuest => _currentUser == null;

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


  Future<bool> login(String email, String password, {bool rememberMe = false}) async {
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

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  Future<String?> updateProfile(AppUser updatedUser, {File? profileImage}) async {
    try {
      String? result = await _authService.updateProfile(updatedUser, profileImage: profileImage);
      if (result == null) {
        _currentUser = updatedUser;
        notifyListeners();
      }
      return result;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> reloadUser() async {
    if (_currentUser == null || _currentUser!.docId == null) return;

    DocumentSnapshot snapshot = await _authService.usersCollection
        .doc(_currentUser!.docId)
        .get();

    _currentUser = AppUser.fromFirestore(snapshot);
    notifyListeners();
  }
}
