// User data + roles (admin, renter, donor)

import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String? docId;
  final String cpr;
  final String email;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String role;
  final String contactPref;
  final int id;
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
    required this.username,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return AppUser(
      docId: doc.id,
      cpr: data['CPR'] ?? '',
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      role: data['role'] ?? 'Guest',
      contactPref: data['contact_pref'] ?? '',
      id: data['id'] ?? 0,
      username: data['username'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'CPR': cpr,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'role': role,
      'contact_pref': contactPref,
      'id': id,
      'username': username,
    };
  }

  // ADD THIS ↓
  AppUser copyWith({
    String? docId,
    String? cpr,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? role,
    String? contactPref,
    int? id,
    String? username,
  }) {
    return AppUser(
      docId: docId ?? this.docId,
      cpr: cpr ?? this.cpr,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      contactPref: contactPref ?? this.contactPref,
      id: id ?? this.id,
      username: username ?? this.username,
    );
  }
}
