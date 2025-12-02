//Login, logout, user registration

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');

  /// REGISTER USER (Auth + Firestore)
  Future<AppUser?> registerUser(AppUser user) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: user.email,
        password: user.password,
      );

      // Save to Firestore using UID
      await usersCollection.doc(cred.user!.uid).set(user.toMap());

      return user;
    } catch (e) {
      print("Register Error: $e");
      return null;
    }
  }

  /// LOGIN USER
  Future<AppUser?> login(String email, String password) async {
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      DocumentSnapshot snapshot =
          await usersCollection.doc(cred.user!.uid).get();

      return AppUser.fromFirestore(snapshot);
    } catch (e) {
      print("Login Error: $e");
      return null;
    }
  }

  /// LOGOUT USER
  Future<void> logout() async {
    await _auth.signOut();
  }
}
