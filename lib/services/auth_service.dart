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
  Future<AppUser?> registerUser(AppUser user, {File? profileImage}) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: user.email,
        password: user.password,
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
        password: user.password,
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
        password: user.password,
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
}
