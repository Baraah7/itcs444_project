import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../screens/admin/donation_management.dart';
import '../../screens/admin/reservation_management.dart';
import '../../screens/admin/maintenance_management.dart';
import '../tracking/notification_card.dart';

class AdminNotificationsScreen extends StatelessWidget {
  const AdminNotificationsScreen({super.key});

  void _handleNotificationTap(BuildContext context, String type) {
    // Navigate to appropriate screen based on notification type
    switch (type) {
      case 'donation':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DonationList()),
        );
        break;
      case 'reservation_submitted':
      case 'cancellation':
      case 'overdue':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ReservationManagementScreen()),
        );
        break;
      case 'maintenance':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MaintenanceManagementScreen()),
        );
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Notifications"),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () async {
              final batch = FirebaseFirestore.instance.batch();
              final unreadDocs = await FirebaseFirestore.instance
                  .collection('adminNotifications')
                  .where('isRead', isEqualTo: false)
                  .get();

              for (var doc in unreadDocs.docs) {
                batch.update(doc.reference, {'isRead': true});
              }
              await batch.commit();
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('adminNotifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text("Error: ${snapshot.error}"),
                ],
              ),
            );
          }

          // Get current admin's ID to filter out their own notifications
          final currentAdminId = FirebaseAuth.instance.currentUser?.uid;

          // Filter out notifications where current admin is excluded
          final filteredDocs = (snapshot.data?.docs ?? []).where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final excludeAdminId = data['excludeAdminId'] as String?;
            // Show notification only if excludeAdminId is null or doesn't match current admin
            return excludeAdminId == null || excludeAdminId != currentAdminId;
          }).toList();

          if (filteredDocs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No notifications yet",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "You'll be notified about new donations,\nreservations, and cancellations",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) {
              final doc = filteredDocs[index];
              final data = doc.data() as Map<String, dynamic>;
              final title = data['title'] ?? 'Notification';
              final message = data['message'] ?? '';
              final type = data['type'] ?? '';
              final isRead = data['isRead'] ?? false;
              final date = (data['createdAt'] is Timestamp)
                  ? (data['createdAt'] as Timestamp).toDate()
                  : (data['createdAt'] is String)
                      ? DateTime.tryParse(data['createdAt'] as String)
                      : null;

              return NotificationCard(
                notificationId: doc.id,
                title: title,
                message: message,
                type: type,
                isRead: isRead,
                createdAt: date,
                collection: 'adminNotifications',
                onTap: () => _handleNotificationTap(context, type),
              );
            },
          );
        },
      ),
    );
  }
}
