import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../notification_screen.dart/notification_screen.dart';

class TestNotificationScreen extends StatelessWidget {
  const TestNotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Test Notifications')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () async {
                await notificationProvider.sendNotification(
                  userId: authProvider.currentUser!.docId!,
                  title: 'Test Notification',
                  message: 'This is a test notification',
                  type: 'approval',
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notification sent!')),
                );
              },
              child: const Text('Send Test Notification'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationScreen()),
                );
              },
              child: const Text('View Notifications'),
            ),
          ],
        ),
      ),
    );
  }
}
