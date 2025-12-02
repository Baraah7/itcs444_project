//Login, logout, user registration

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');

  // ─────────────────────────────────────────────
  // REGISTER USER
  // ─────────────────────────────────────────────
  Future<AppUser?> registerUser(AppUser user, String password) async {
    try {
      // Create account in FirebaseAuth
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: user.email,
        password: password,
      );

      String uid = cred.user!.uid;

      // Add user to Firestore
      await usersCollection.doc(uid).set({
        'CPR': user.cpr,
        'email': user.email,
        'firstName': user.firstName,
        'lastName': user.lastName,
        'phoneNumber': user.phoneNumber,
        'role': user.role,
        'contact_pref': user.contactPref,
        'id': user.id,
        'username': user.username,
        'createdAt': DateTime.now(),
      });

      // return user with docId
      return user.copyWith(docId: uid);

    } catch (e) {
      print("❌ Registration error: $e");
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // LOGIN USER
  // ─────────────────────────────────────────────
  Future<AppUser?> login(String email, String password) async {
    try {
      // Firebase authentication
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = cred.user!.uid;

      // Fetch user data from Firestore
      DocumentSnapshot snapshot = await usersCollection.doc(uid).get();

      if (!snapshot.exists) return null;

      return AppUser.fromFirestore(snapshot);

    } catch (e) {
      print("❌ Login error: $e");
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // LOGOUT USER
  // ─────────────────────────────────────────────
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ─────────────────────────────────────────────
  // GET CURRENT USER DATA
  // ─────────────────────────────────────────────
  Future<AppUser?> fetchCurrentUser() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return null;

      DocumentSnapshot snapshot =
          await usersCollection.doc(user.uid).get();

      if (!snapshot.exists) return null;

      return AppUser.fromFirestore(snapshot);

    } catch (e) {
      print("❌ Fetch user error: $e");
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // UPDATE USER DATA
  // ─────────────────────────────────────────────
  Future<bool> updateUser(AppUser updatedUser) async {
    try {
      await usersCollection.doc(updatedUser.docId).update(updatedUser.toMap());
      return true;
    } catch (e) {
      print("❌ Update user error: $e");
      return false;
    }
  }
}
