import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/reservation_model.dart';
import '../../providers/reservation_provider.dart';

class ReservationDetailScreen extends StatelessWidget {
  final Reservation reservation;

  const ReservationDetailScreen({super.key, required this.reservation});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservation Details'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 16),
            _buildEquipmentInfo(),
            const SizedBox(height: 16),
            _buildReservationDetails(),
            const SizedBox(height: 16),
            _buildPriceDetails(),
            if (reservation.notes != null) ...[
              const SizedBox(height: 16),
              _buildNotesSection(),
            ],
            const SizedBox(height: 16),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      color: _getStatusColor(reservation.status),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              _getStatusIcon(reservation.status),
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getStatusText(reservation.status),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getStatusDescription(reservation.status),
                    style: const TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEquipmentInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Equipment Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Icon(Icons.construction, color: Colors.grey),
              ),
              title: Text(
                reservation.equipmentName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text('Reservation ID: ${reservation.id}'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reservation Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildDetailItem('Start Date', _formatDate(reservation.startDate)),
            _buildDetailItem('End Date', _formatDate(reservation.endDate)),
            _buildDetailItem('Duration', '${reservation.durationInDays} days'),
            _buildDetailItem('Created Date', _formatDate(reservation.createdAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Price Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildDetailItem('Total Amount', '\$${reservation.totalPrice.toStringAsFixed(2)}'),
            _buildDetailItem('Payment Status', 'Paid', color: Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Additional Notes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              reservation.notes!,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Consumer<ReservationProvider>(
      builder: (context, reservationProvider, child) {
        if (reservation.status != ReservationStatus.pending) {
          return const SizedBox();
        }

        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _showCancelDialog(context, reservationProvider);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Cancel Reservation'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailItem(String title, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, ReservationProvider reservationProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Reservation'),
          content: const Text('Are you sure you want to cancel this reservation? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Keep Reservation'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await reservationProvider.cancelReservation(reservation.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reservation cancelled successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.of(context).pop();
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error cancelling reservation: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text(
                'Cancel Reservation',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getStatusText(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return 'Pending Approval';
      case ReservationStatus.confirmed:
        return 'Confirmed';
      case ReservationStatus.active:
        return 'Active';
      case ReservationStatus.completed:
        return 'Completed';
      case ReservationStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _getStatusDescription(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return 'Waiting for admin approval';
      case ReservationStatus.confirmed:
        return 'Your reservation has been confirmed';
      case ReservationStatus.active:
        return 'Equipment is currently in use';
      case ReservationStatus.completed:
        return 'Reservation has been completed';
      case ReservationStatus.cancelled:
        return 'This reservation has been cancelled';
    }
  }

  Color _getStatusColor(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return Colors.orange;
      case ReservationStatus.confirmed:
        return Colors.blue;
      case ReservationStatus.active:
        return Colors.green;
      case ReservationStatus.completed:
        return Colors.grey;
      case ReservationStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return Icons.pending_actions;
      case ReservationStatus.confirmed:
        return Icons.check_circle;
      case ReservationStatus.active:
        return Icons.play_circle_fill;
      case ReservationStatus.completed:
        return Icons.done_all;
      case ReservationStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}