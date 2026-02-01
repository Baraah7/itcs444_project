import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../user/my_reservations.dart';
import '../user/donation_history.dart';
import '../user/reservation_details.dart';
import '../user/user_donation_details.dart';
import '../../tracking/notification_card.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final userId = auth.currentUser?.docId;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: Color(0xFF2B6C67)),
            onPressed: () => _markAllAsRead(userId),
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: userId)
            .where('isRead', isEqualTo: false)
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
                  Icon(Icons.error_outline, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Unable to load notifications',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please try again later',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final isRead = data['isRead'] ?? false;
              final title = data['title'] ?? 'Notification';
              final message = data['message'] ?? '';
              final type = data['type'] ?? 'info';
              final createdAt = (data['createdAt'] is Timestamp)
                  ? (data['createdAt'] as Timestamp).toDate()
                  : (data['createdAt'] is String)
                      ? DateTime.tryParse(data['createdAt'] as String)
                      : null;

              // Get item ID for navigation (rentalId or donationId)
              final itemId = data['rentalId'] ?? data['donationId'] ?? data['itemId'];

              return NotificationCard(
                notificationId: doc.id,
                title: title,
                message: message,
                type: type,
                isRead: isRead,
                createdAt: createdAt,
                collection: 'notifications',
                onTap: () => _handleNotificationTap(context, type, itemId),
              );
            },
          );
        },
      ),
    );
  }

  void _handleNotificationTap(BuildContext context, String type, String? itemId) {
    // Navigate to appropriate screen based on notification type
    switch (type) {
      case 'rental_reminder':
      case 'overdue':
      case 'approval':
      case 'reservation_submitted':
      case 'cancellation':
      case 'checked_out':
      case 'returned':
      case 'extended':
        if (itemId != null && itemId.isNotEmpty) {
          // Navigate to specific reservation details
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ReservationDetailsPage(rentalId: itemId)),
          );
        } else {
          // Fallback to reservations list
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MyReservationsScreen()),
          );
        }
        break;
      case 'donation':
      case 'donation_approved':
      case 'donation_rejected':
        if (itemId != null && itemId.isNotEmpty) {
          // Navigate to specific donation details
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => UserDonationDetails(donationID: itemId)),
          );
        } else {
          // Fallback to donations list
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DonationHistory()),
          );
        }
        break;
      default:
        // For any unknown type, show the reservations screen as fallback
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MyReservationsScreen()),
        );
        break;
    }
  }

  void _markAllAsRead(String? userId) {
    if (userId == null) return;
    FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get()
        .then((snapshot) {
      for (var doc in snapshot.docs) {
        doc.reference.update({'isRead': true});
      }
    });
  }
}
