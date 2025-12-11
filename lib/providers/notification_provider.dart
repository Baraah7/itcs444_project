import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _service = NotificationService();
  List<NotificationModel> _notifications = [];
  final bool _isLoading = false;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void listenToNotifications(String userId) {
    _service.getUserNotifications(userId).listen((notifications) {
      _notifications = notifications;
      notifyListeners();
    });
  }

  Future<void> markAsRead(String notificationId) async {
    await _service.markAsRead(notificationId);
    notifyListeners();
  }

  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    await _service.sendNotification(
      userId: userId,
      title: title,
      message: message,
      type: type,
      data: data,
    );
  }
}
