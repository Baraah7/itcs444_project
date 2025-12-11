import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload profile image to Firebase Storage
  Future<String?> uploadProfileImage(File imageFile, String userId) async {
    try {
      Reference ref = _storage.ref().child('profile_images/$userId.jpg');
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Upload Image Error: $e");
      return null;
    }
  }

  /// REGISTER USER (Auth + Firestore + Image)
  Future<AppUser?> registerUser(AppUser user, String password, {File? profileImage}) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: user.email,
        password: password,
      );

      String? imageUrl;
      if (profileImage != null) {
        imageUrl = await uploadProfileImage(profileImage, cred.user!.uid);
      }

      AppUser newUser = AppUser(
        docId: cred.user!.uid,
        cpr: user.cpr,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        phoneNumber: user.phoneNumber,
        role: user.role,
        contactPref: user.contactPref,
        id: user.id,
        username: user.username,
        profileImageUrl: imageUrl,
      );

      await usersCollection.doc(cred.user!.uid).set(newUser.toMap());
      return newUser;
    } catch (e) {
      print("Register Error: $e");
      return null;
    }
  }

  /// UPDATE PROFILE WITH IMAGE
  Future<String?> updateProfile(AppUser user, {File? profileImage}) async {
    try {
      String? imageUrl = user.profileImageUrl;
      if (profileImage != null && user.docId != null) {
        imageUrl = await uploadProfileImage(profileImage, user.docId!);
      }

      AppUser updatedUser = AppUser(
        docId: user.docId,
        cpr: user.cpr,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        phoneNumber: user.phoneNumber,
        role: user.role,
        contactPref: user.contactPref,
        id: user.id,
        username: user.username,
        profileImageUrl: imageUrl,
      );

      await usersCollection.doc(user.docId).update(updatedUser.toMap());
      return null; // success
    } catch (e) {
      return e.toString();
    }
  }

  // LOGIN and LOGOUT remain the same...
  // ─────────────────────────────────────────────
  // LOGIN USER
  // ─────────────────────────────────────────────
Future<AppUser?> login(String email, String password) async {
  try {
    UserCredential userCredential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);

    // Use UID to fetch user profile
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userCredential.user!.uid)
        .get();

    if (doc.exists) {
      return AppUser.fromFirestore(doc);
    } else {
      return null;
    }
  } catch (e) {
    print('Login exception: $e');
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
