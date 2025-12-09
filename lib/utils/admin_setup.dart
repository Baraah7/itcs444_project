import 'package:cloud_firestore/cloud_firestore.dart';

/// One-time function to set a user as admin
/// Call this once with the user's UID
Future<void> setUserAsAdmin(String userId) async {
  try {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({'role': 'admin'});
    print('✅ User $userId is now an admin');
  } catch (e) {
    print('❌ Error setting user as admin: $e');
  }
}

/// List all users to find the UID you want to make admin
Future<void> listAllUsers() async {
  try {
    final users = await FirebaseFirestore.instance.collection('users').get();
    print('📋 All users:');
    for (var user in users.docs) {
      final data = user.data();
      print('  - UID: ${user.id}');
      print('    Email: ${data['email']}');
      print('    Role: ${data['role'] ?? 'user'}');
      print('    Name: ${data['firstName']} ${data['lastName']}');
      print('');
    }
  } catch (e) {
    print('❌ Error listing users: $e');
  }
}
