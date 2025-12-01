import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/reservation_model.dart';
import '../../providers/reservation_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/reservation_card.dart';

class ReservationDetailScreen extends StatefulWidget {
  final Reservation reservation;

  const ReservationDetailScreen({
    Key? key,
    required this.reservation,
  }) : super(key: key);

  @override
  State<ReservationDetailScreen> createState() => _ReservationDetailScreenState();
}

class _ReservationDetailScreenState extends State<ReservationDetailScreen> {
  bool _isCancelling = false;

  @override
  Widget build(BuildContext context) {
    final reservation = widget.reservation;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservation Details'),
        actions: [
          if (reservation.canCancel)
            IconButton(
              icon: const Icon(Icons.cancel_outlined),
              onPressed: () => _showCancelDialog(context, reservation),
              tooltip: 'Cancel Reservation',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reservation Card
            ReservationCard(
              reservation: reservation,
              showUserInfo: true,
            ),
            
            const SizedBox(height: 24),
            
            // Detailed Information
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.timeline, color: AppColors.primaryBlue),
                        const SizedBox(width: 8),
                        Text(
                          'Reservation Timeline',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    _buildTimelineItem(
                      icon: Icons.create,
                      title: 'Created',
                      date: reservation.createdAt,
                      description: 'Reservation request submitted',
                      color: AppColors.neutralGray,
                    ),
                    
                    if (reservation.approvedAt != null)
                      _buildTimelineItem(
                        icon: Icons.check_circle,
                        title: 'Approved',
                        date: reservation.approvedAt!,
                        description: 'Admin approved your request',
                        color: AppColors.success,
                      ),
                    
                    if (reservation.checkedOutAt != null)
                      _buildTimelineItem(
                        icon: Icons.inventory,
                        title: 'Checked Out',
                        date: reservation.checkedOutAt!,
                        description: 'Equipment picked up',
                        color: Colors.blue,
                      ),
                    
                    if (reservation.returnedAt != null)
                      _buildTimelineItem(
                        icon: Icons.assignment_returned,
                        title: 'Returned',
                        date: reservation.returnedAt!,
                        description: 'Equipment returned successfully',
                        color: Colors.purple,
                      ),
                    
                    if (reservation.cancelledAt != null)
                      _buildTimelineItem(
                        icon: Icons.cancel,
                        title: 'Cancelled',
                        date: reservation.cancelledAt!,
                        description: 'Reservation cancelled',
                        color: AppColors.error,
                      ),
                    
                    // Due Date Warning
                    if (reservation.status == ReservationStatus.checkedOut)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: reservation.isOverdue
                              ? AppColors.error.withOpacity(0.1)
                              : Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: reservation.isOverdue
                                ? AppColors.error
                                : Colors.amber,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              reservation.isOverdue ? Icons.warning : Icons.schedule,
                              color: reservation.isOverdue ? AppColors.error : Colors.amber,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    reservation.isOverdue
                                        ? 'OVERDUE - URGENT'
                                        : 'DUE SOON',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: reservation.isOverdue
                                          ? AppColors.error
                                          : Colors.amber,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    reservation.isOverdue
                                        ? 'Equipment was due on ${reservation.formattedEndDate}. Please return immediately.'
                                        : 'Equipment due in ${reservation.daysUntilDue} days (${reservation.formattedEndDate})',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Contact Information
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.contact_support, color: AppColors.primaryBlue),
                        const SizedBox(width: 8),
                        Text(
                          'Contact Information',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    _buildContactItem(
                      icon: Icons.person,
                      label: 'Reserved By:',
                      value: reservation.userName,
                    ),
                    
                    _buildContactItem(
                      icon: Icons.email,
                      label: 'Email:',
                      value: reservation.userEmail,
                    ),
                    
                    _buildContactItem(
                      icon: Icons.phone,
                      label: 'Phone:',
                      value: reservation.userPhone,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.blue),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'For any questions or changes, please contact the care center admin.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Notes Section
            if (reservation.notes != null && reservation.notes!.isNotEmpty)
              Column(
                children: [
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.note, color: AppColors.primaryBlue),
                              const SizedBox(width: 8),
                              Text(
                                'Your Notes',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              reservation.notes!,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            
            // Admin Notes
            if (reservation.adminNotes != null && reservation.adminNotes!.isNotEmpty)
              Column(
                children: [
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.admin_panel_settings, color: AppColors.primaryBlue),
                              const SizedBox(width: 8),
                              Text(
                                'Admin Notes',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.withOpacity(0.2)),
                            ),
                            child: Text(
                              reservation.adminNotes!,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            
            // Action Buttons
            if (reservation.canCancel)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isCancelling ? null : () => _showCancelDialog(context, reservation),
                        icon: const Icon(Icons.cancel_outlined),
                        label: _isCancelling
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Cancel Reservation'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.error,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: AppColors.error),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Contact support
                        },
                        icon: const Icon(Icons.support_agent),
                        label: const Text('Contact Support'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Status-specific instructions
            if (reservation.status == ReservationStatus.approved)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'Ready for Pickup',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your reservation has been approved! Please visit the care center to pick up the equipment during business hours.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bring your ID and this reservation ID: ${reservation.id}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required String title,
    required DateTime date,
    required String description,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(date),
                  style: TextStyle(
                    color: AppColors.neutralGray,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.neutralGray),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    String dateStr;
    if (date == today) {
      dateStr = 'Today';
    } else if (date == today.subtract(const Duration(days: 1))) {
      dateStr = 'Yesterday';
    } else if (date == today.add(const Duration(days: 1))) {
      dateStr = 'Tomorrow';
    } else {
      dateStr = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
    
    final timeStr = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    
    return '$dateStr at $timeStr';
  }

  void _showCancelDialog(BuildContext context, Reservation reservation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Reservation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to cancel this reservation?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Note: Cancellations may be subject to fees if made less than 24 hours before pickup.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No, Keep It'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _cancelReservation(reservation.id);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelReservation(String reservationId) async {
    setState(() {
      _isCancelling = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    final reservationProvider = Provider.of<ReservationProvider>(context, listen: false);
    reservationProvider.cancelReservation(reservationId);

    setState(() {
      _isCancelling = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reservation cancelled successfully'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Navigate back after a delay
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      Navigator.pop(context);
    }
  }
}