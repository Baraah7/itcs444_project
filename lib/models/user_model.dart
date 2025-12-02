import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String? docId;
<<<<<<< HEAD
  final int cpr;
=======
  final String cpr;
>>>>>>> 1af87b0e8dcab503301128a9e672f7ac5633563b
  final String email;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String role;
  final String contactPref;
  final int id;
  final String username;
  final String? profileImageUrl; // New field

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
    this.profileImageUrl,
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
      profileImageUrl: data['profileImageUrl'], // Fetch URL
    );
  }

<<<<<<< HEAD
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
      profileImageUrl: data['profileImageUrl'],
    );
  }

=======
>>>>>>> 1af87b0e8dcab503301128a9e672f7ac5633563b
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
      'profileImageUrl': profileImageUrl, // Save URL
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
