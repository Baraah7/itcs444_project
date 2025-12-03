// User data + roles (admin, renter, donor)

import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String? docId;          // Firestore document ID
  final int cpr;
  final String email;
  final String firstName;
  final String lastName;
  final int phoneNumber;
  final String role;
  final String contactPref;
  final int id;
  final String password;
  final String username;

  AppUser({
    this.docId,
    required this.cpr,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.role,
    required this.contactPref,
    required this.id,
    required this.password,
    required this.username,
  });

  /// Convert Firestore DocumentSnapshot → AppUser model
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return AppUser(
      docId: doc.id,
      cpr: data['CPR'] ?? 0,
      email: data['Email'] ?? '',
      firstName: data['First Name'] ?? '',
      lastName: data['Last Name'] ?? '',
      phoneNumber: data['Phone Number'] ?? 0,
      role: data['Role'] ?? '',
      contactPref: data['contact_pref'] ?? '',
      id: data['id'] ?? 0,
      password: data['password'] ?? '',
      username: data['username'] ?? '',
    );
  }

  /// Convert Map → AppUser
  factory AppUser.fromMap(Map<String, dynamic> data, {String? docId}) {
    return AppUser(
      docId: docId,
      cpr: data['CPR'] ?? 0,
      email: data['Email'] ?? '',
      firstName: data['First Name'] ?? '',
      lastName: data['Last Name'] ?? '',
      phoneNumber: data['Phone Number'] ?? 0,
      role: data['Role'] ?? '',
      contactPref: data['contact_pref'] ?? '',
      id: data['id'] ?? 0,
      password: data['password'] ?? '',
      username: data['username'] ?? '',
    );
  }

  /// Convert AppUser → Map<String, dynamic> for Firestore
  Map<String, dynamic> toMap() {
    return {
      'CPR': cpr,
      'Email': email,
      'First Name': firstName,
      'Last Name': lastName,
      'Phone Number': phoneNumber,
      'Role': role,
      'contact_pref': contactPref,
      'id': id,
      'password': password,
      'username': username,
    };
  }
}
