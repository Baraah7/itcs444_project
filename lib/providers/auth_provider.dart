import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      _errorMessage = null;
      notifyListeners();

      AppUser? createdUser = await _authService.registerUser(user, password);

      if (createdUser != null) {
        _currentUser = createdUser;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = "Registration failed. User could not be created.";
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      print('Registration error: $e'); // Debug print
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // UPDATED LOGIN: fetches role from Firestore
Future<bool> login(String email, String password, {bool rememberMe = false}) async {
  try {
    _isLoading = true;
    notifyListeners();

    print('Attempting login for email: $email');

    // Fetch user document from Firestore
    AppUser? user = await _authService.login(email, password);

    if (user != null) {
      _currentUser = user;
      print('User found: ${user.email}, role: ${user.role}, docId: ${user.docId}');

      // Check role
      if (user.role.toLowerCase() == 'admin') {
        print('Admin login detected');
      }

      // Save credentials if "remember me"
      if (rememberMe) {
        await _saveCredentials(email, password);
      } else {
        await _clearCredentials();
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      print('Login failed: user not found or password incorrect');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  } catch (e) {
    print('Login exception: $e');
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

  Future<void> _saveCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedAccounts = prefs.getStringList('saved_accounts') ?? [];
    String account = '$email:$password';
    savedAccounts.remove(account);
    savedAccounts.insert(0, account);
    await prefs.setStringList('saved_accounts', savedAccounts);
  }

  Future<void> _clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_accounts');
  }

  Future<List<Map<String, String>>> getSavedAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedAccounts = prefs.getStringList('saved_accounts') ?? [];
    return savedAccounts.map((account) {
      final parts = account.split(':');
      return {'email': parts[0], 'password': parts[1]};
    }).toList();
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
