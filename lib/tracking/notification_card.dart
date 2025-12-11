import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationCard extends StatelessWidget {
  final String notificationId;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime? createdAt;
  final VoidCallback onTap;
  final String collection; // 'notifications' or 'adminNotifications'

  const NotificationCard({
    super.key,
    required this.notificationId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    required this.onTap,
    required this.collection,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notificationId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      onDismissed: (direction) {
        _deleteNotification();
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        elevation: isRead ? 0 : 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isRead ? Colors.grey.shade200 : _getTypeColor(type).withOpacity(0.3),
            width: isRead ? 1 : 2,
          ),
        ),
        color: isRead ? Colors.grey.shade50 : Colors.white,
        child: InkWell(
          onTap: () {
            _markAsReadAndNavigate(context);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getTypeColor(type).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getTypeIcon(type),
                    color: _getTypeColor(type),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                color: isRead ? Colors.grey.shade700 : Colors.black87,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _getTypeColor(type),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 14,
                          color: isRead ? Colors.grey.shade600 : Colors.grey.shade700,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            createdAt != null ? _formatDate(createdAt!) : '',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getTypeColor(type).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _getTypeLabel(type),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _getTypeColor(type),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _markAsReadAndNavigate(BuildContext context) async {
    // Mark as read and delete
    if (!isRead) {
      await FirebaseFirestore.instance.collection(collection).doc(notificationId).update({'isRead': true});
    }

    // Delete the notification
    await _deleteNotification();

    // Navigate
    onTap();
  }

  Future<void> _deleteNotification() async {
    await FirebaseFirestore.instance.collection(collection).doc(notificationId).delete();
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'donation':
        return Icons.volunteer_activism;
      case 'approval':
        return Icons.check_circle;
      case 'rental_reminder':
        return Icons.alarm;
      case 'overdue':
        return Icons.warning;
      case 'maintenance':
        return Icons.build;
      case 'reservation_submitted':
        return Icons.event_note;
      case 'cancellation':
        return Icons.cancel;
      default:
        return Icons.notifications;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'donation':
        return Colors.green;
      case 'approval':
        return Colors.blue;
      case 'rental_reminder':
        return Colors.orange;
      case 'overdue':
        return Colors.red;
      case 'maintenance':
        return Colors.purple;
      case 'reservation_submitted':
        return Colors.blue;
      case 'cancellation':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'donation':
        return 'Donation';
      case 'approval':
        return 'Rental';
      case 'rental_reminder':
        return 'Reminder';
      case 'overdue':
        return 'Overdue';
      case 'maintenance':
        return 'Maintenance';
      case 'reservation_submitted':
        return 'New Request';
      case 'cancellation':
        return 'Cancelled';
      default:
        return 'Info';
    }
  }

  String _formatDate(DateTime date) {
    try {
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return "${date.day}/${date.month}/${date.year}";
      }
    } catch (e) {
      return '';
    }
  }
}
