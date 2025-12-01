// User data + roles (admin, renter, donor)
class User {
  final String uid;
  final String email;
  final String name;
  final String role; // 'admin' or 'user'
  final String? phoneNumber;
  final String? address;
  final DateTime? createdAt;
  final bool isEmailVerified;

  User({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.phoneNumber,
    this.address,
    this.createdAt,
    this.isEmailVerified = false,
  });

  // Convert User object to Map
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'phoneNumber': phoneNumber,
      'address': address,
      'createdAt': createdAt?.toIso8601String(),
      'isEmailVerified': isEmailVerified,
    };
  }

  // Create User object from Map
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'user',
      phoneNumber: json['phoneNumber'],
      address: json['address'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
      isEmailVerified: json['isEmailVerified'] ?? false,
    );
  }

  // Copy with method for easy updates
  User copyWith({
    String? uid,
    String? email,
    String? name,
    String? role,
    String? phoneNumber,
    String? address,
    DateTime? createdAt,
    bool? isEmailVerified,
  }) {
    return User(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }

  // Helper methods
  bool get isAdmin => role == 'admin';
  bool get isRegularUser => role == 'user';
}