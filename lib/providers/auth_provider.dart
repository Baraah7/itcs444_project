//Current user + login state

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

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
}
