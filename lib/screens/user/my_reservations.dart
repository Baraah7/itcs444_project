//Reservation history + status
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/reservation_model.dart';
import '../../providers/reservation_provider.dart';
import 'reservation_detail.dart';

class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({super.key});

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  ReservationStatus _selectedFilter = ReservationStatus.pending;

  @override
  Widget build(BuildContext context) {
    final reservationProvider = Provider.of<ReservationProvider>(context);

    return Scaffold(
      body: Column(
        children: [
          _buildFilterTabs(),
          Expanded(
            child: _buildReservationsList(reservationProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ReservationStatus.values.map((status) {
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
                label: Text(_getStatusText(status)),
                selected: _selectedFilter == status,
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = status;
                  });
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildReservationsList(ReservationProvider reservationProvider) {
    final filteredReservations = reservationProvider.userReservations
        .where((reservation) => reservation.status == _selectedFilter)
        .toList();

    if (reservationProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (filteredReservations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getStatusIcon(_selectedFilter),
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _getEmptyStateText(_selectedFilter),
              style: const TextStyle(fontSize: 18, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: filteredReservations.length,
      itemBuilder: (context, index) {
        final reservation = filteredReservations[index];
        return _buildReservationCard(reservation);
      },
    );
  }

  Widget _buildReservationCard(Reservation reservation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReservationDetailScreen(
                reservation: reservation,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      reservation.equipmentName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(reservation.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(reservation.status).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildReservationDetailItem(
                Icons.calendar_today,
                '${_formatDate(reservation.startDate)} - ${_formatDate(reservation.endDate)}',
              ),
              const SizedBox(height: 6),
              _buildReservationDetailItem(
                Icons.access_time,
                '${reservation.durationInDays} days',
              ),
              const SizedBox(height: 6),
              _buildReservationDetailItem(
                Icons.attach_money,
                '\$${reservation.totalPrice.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Created: ${_formatDate(reservation.createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (reservation.status == ReservationStatus.pending)
                    TextButton(
                      onPressed: () {
                        _showCancelDialog(context, reservation.id);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Cancel'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReservationDetailItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  void _showCancelDialog(BuildContext context, String reservationId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Reservation'),
          content: const Text('Are you sure you want to cancel this reservation?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await Provider.of<ReservationProvider>(context, listen: false)
                      .cancelReservation(reservationId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reservation cancelled successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Yes, Cancel'),
            ),
          ],
        );
      },
    );
  }

  String _getStatusText(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return 'Pending';
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
        return Icons.check_circle_outline;
      case ReservationStatus.active:
        return Icons.play_circle_outline;
      case ReservationStatus.completed:
        return Icons.done_all;
      case ReservationStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _getEmptyStateText(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return 'No pending reservations';
      case ReservationStatus.confirmed:
        return 'No confirmed reservations';
      case ReservationStatus.active:
        return 'No active reservations';
      case ReservationStatus.completed:
        return 'No completed reservations';
      case ReservationStatus.cancelled:
        return 'No cancelled reservations';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}