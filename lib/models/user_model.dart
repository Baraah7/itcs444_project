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
  final String? profileImageUrl;
  final bool isBanned;
  final DateTime? bannedUntil;

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
    this.isBanned = false,
    this.bannedUntil,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return AppUser(
      docId: doc.id,
      cpr: (data['CPR'] ?? '').toString(),
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      phoneNumber: (data['phoneNumber'] ?? '').toString(),
      role: data['role'] ?? 'Guest',
      contactPref: data['contact_pref'] ?? '',
      id: data['id'] ?? 0,
      username: data['username'] ?? '',
      profileImageUrl: data['profileImageUrl'],
      isBanned: data['isBanned'] ?? false,
      bannedUntil: data['bannedUntil'] != null
          ? (data['bannedUntil'] as Timestamp).toDate()
          : null,
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
      'profileImageUrl': profileImageUrl,
      'isBanned': isBanned,
      'bannedUntil': bannedUntil != null ? Timestamp.fromDate(bannedUntil!) : null,
    };
  }

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
    String? profileImageUrl,
    bool? isBanned,
    DateTime? bannedUntil,
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
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isBanned: isBanned ?? this.isBanned,
      bannedUntil: bannedUntil ?? this.bannedUntil,
    );
  }
}