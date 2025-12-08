import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

class BackgroundNotificationService {
  final NotificationService _notificationService = NotificationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _timer;

  void startMonitoring() {
    _timer = Timer.periodic(Duration(hours: 6), (timer) {
      _checkRentals();
      _checkDonations();
      _checkMaintenance();
    });
  }

  void stopMonitoring() {
    _timer?.cancel();
  }

  Future<void> _checkRentals() async {
    final now = DateTime.now();
    final threeDaysLater = now.add(Duration(days: 3));

    final rentals = await _firestore
        .collection('rentals')
        .where('status', isEqualTo: 'checked_out')
        .get();

    for (var doc in rentals.docs) {
      final data = doc.data();
      final endDate = DateTime.parse(data['endDate']);
      final userId = data['userId'];
      
      // Send reminder for upcoming returns
      if (endDate.isAfter(now) && endDate.isBefore(threeDaysLater)) {
        final daysRemaining = endDate.difference(now).inDays;
        await _notificationService.sendNotification(
          userId: userId,
          title: 'Rental Return Reminder',
          message: 'Your rental "${data['equipmentName']}" is due in $daysRemaining days',
          type: 'rental_reminder',
          data: {'rentalId': doc.id},
        );
        
        // Notify admin
        await _notifyAdmins(
          'Upcoming Return',
          'Rental "${data['equipmentName']}" by ${data['userFullName']} due in $daysRemaining days',
          'rental_reminder',
        );
      }
      
      // Send overdue notifications
      if (endDate.isBefore(now)) {
        final daysOverdue = now.difference(endDate).inDays;
        await _notificationService.sendNotification(
          userId: userId,
          title: 'Overdue Rental',
          message: 'Your rental "${data['equipmentName']}" is $daysOverdue days overdue. Please return immediately.',
          type: 'overdue',
          data: {'rentalId': doc.id},
        );
        
        // Notify admin
        await _notifyAdmins(
          'Overdue Rental',
          'Rental "${data['equipmentName']}" by ${data['userFullName']} is $daysOverdue days overdue',
          'overdue',
        );
      }
    }
  }

  Future<void> _checkDonations() async {
    final donations = await _firestore
        .collection('donations')
        .where('status', isEqualTo: 'pending')
        .get();

    if (donations.docs.isNotEmpty) {
      await _notifyAdmins(
        'Pending Donations',
        'You have ${donations.docs.length} pending donation(s) to review',
        'donation',
      );
    }
  }

  Future<void> _checkMaintenance() async {
    final equipment = await _firestore
        .collection('equipment')
        .where('status', isEqualTo: 'maintenance')
        .get();

    if (equipment.docs.isNotEmpty) {
      await _notifyAdmins(
        'Equipment Maintenance',
        '${equipment.docs.length} equipment item(s) require maintenance',
        'maintenance',
      );
    }
  }

  Future<void> _notifyAdmins(String title, String message, String type) async {
    final admins = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'admin')
        .get();

    for (var admin in admins.docs) {
      await _notificationService.sendNotification(
        userId: admin.id,
        title: title,
        message: message,
        type: type,
      );
    }
  }
}
