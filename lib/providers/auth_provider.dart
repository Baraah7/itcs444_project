import 'dart:io';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  AppUser? _currentUser;

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  Future<String?> registerUser(AppUser user, {File? profileImage}) async {
    try {
      AppUser? newUser =
          await _authService.registerUser(user, profileImage: profileImage);
      if (newUser != null) {
        _currentUser = newUser;
        notifyListeners();
        return null;
      } else {
        return "Registration failed";
      }
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateProfile(AppUser updatedUser, {File? profileImage}) async {
    try {
      String? result =
          await _authService.updateProfile(updatedUser, profileImage: profileImage);
      if (result == null) {
        _currentUser = updatedUser;
        notifyListeners();
      }
      return result;
    } catch (e) {
      return e.toString();
    }
  }
}
