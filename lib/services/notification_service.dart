import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> createAdminNotification({
  required String title,
  required String message,
  required String type, // e.g., 'reservation', 'donation', 'equipment', 'reservationDue'
}) {
  return FirebaseFirestore.instance.collection('adminNotifications').add({
    'title': title,
    'message': message,
    'type': type,
    'createdAt': FieldValue.serverTimestamp(),
    'isRead': false,
  });
}
class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    print('📧 Creating notification for user: $userId');
    print('📧 Title: $title');
    print('📧 Message: $message');
    
    final notification = NotificationModel(
      id: _firestore.collection('notifications').doc().id,
      userId: userId,
      title: title,
      message: message,
      type: type,
      createdAt: DateTime.now(),
      data: data,
    );
    
    await _firestore.collection('notifications').doc(notification.id).set(notification.toMap());
    print('✅ Notification saved to Firestore with ID: ${notification.id}');
  }

  Future<void> sendAdminNotification({
  required String title,
  required String message,
  required String type,
  Map<String, dynamic>? data,
}) async {
  print('📢 Creating ADMIN notification');
  print('📢 Title: $title');
  print('📢 Message: $message');

  final id = _firestore.collection('adminNotifications').doc().id;

  await _firestore.collection('adminNotifications').doc(id).set({
    'id': id,
    'title': title,
    'message': message,
    'type': type,
    'createdAt': DateTime.now(),
    'isRead': false,
    'data': data,
  });
Stream<List<NotificationModel>> getAdminNotifications() {
  return _firestore
      .collection('adminNotifications')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => NotificationModel.fromMap(doc.data())).toList());
}

  print('✅ ADMIN Notification saved with ID: $id');
}


  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => NotificationModel.fromMap(doc.data())).toList());
  }

  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({'isRead': true});
  }

  Future<void> checkAndSendRentalReminders() async {
    final now = DateTime.now();
    final threeDaysLater = now.add(Duration(days: 3));

    final rentals = await _firestore
        .collection('rentals')
        .where('status', isEqualTo: 'checked_out')
        .get();

    for (var doc in rentals.docs) {
      final data = doc.data();
      final endDate = DateTime.parse(data['endDate']);
      
      if (endDate.isAfter(now) && endDate.isBefore(threeDaysLater)) {
        await sendNotification(
          userId: data['userId'],
          title: 'Rental Return Reminder',
          message: 'Your rental "${data['equipmentName']}" is due in ${endDate.difference(now).inDays} days',
          type: 'rental_reminder',
          data: {'rentalId': doc.id},
        );
      }
    }
  }

  Future<void> checkAndSendOverdueNotifications() async {
    final now = DateTime.now();
    final rentals = await _firestore
        .collection('rentals')
        .where('status', isEqualTo: 'checked_out')
        .get();

    for (var doc in rentals.docs) {
      final data = doc.data();
      final endDate = DateTime.parse(data['endDate']);
      
      if (endDate.isBefore(now)) {
        await sendNotification(
          userId: data['userId'],
          title: 'Overdue Rental',
          message: 'Your rental "${data['equipmentName']}" is overdue. Please return it immediately.',
          type: 'overdue',
          data: {'rentalId': doc.id},
        );
      }
    }
  }
}
