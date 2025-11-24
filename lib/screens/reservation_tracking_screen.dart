import 'package:flutter/material.dart';
import '../models/reservation_model.dart';
import '../widgets/reservation_card.dart';

class ReservationTrackingScreen extends StatefulWidget {
  const ReservationTrackingScreen({super.key});

  @override
  State<ReservationTrackingScreen> createState() => _ReservationTrackingScreenState();
}

class _ReservationTrackingScreenState extends State<ReservationTrackingScreen> {
  final List<Reservation> _reservations = [
    Reservation(
      id: '1001',
      renterId: 'user_123',
      equipmentId: '1',
      renterName: 'John Doe',
      equipmentName: 'Premium Wheelchair',
      startDate: DateTime.now().add(const Duration(days: 1)),
      endDate: DateTime.now().add(const Duration(days: 8)),
      totalDurationDays: 7,
      totalPrice: 111.93,
      status: 'pending',
      requestedAt: DateTime.now().subtract(const Duration(hours: 2)),
      isOverdue: false,
    ),
    Reservation(
      id: '1002',
      renterId: 'user_123',
      equipmentId: '2',
      renterName: 'John Doe',
      equipmentName: 'Walking Frame',
      startDate: DateTime.now().subtract(const Duration(days: 5)),
      endDate: DateTime.now().add(const Duration(days: 2)),
      totalDurationDays: 7,
      totalPrice: 69.93,
      status: 'approved',
      requestedAt: DateTime.now().subtract(const Duration(days: 7)),
      approvedAt: DateTime.now().subtract(const Duration(days: 6)),
      isOverdue: false,
    ),
    Reservation(
      id: '1003',
      renterId: 'user_123',
      equipmentId: '3',
      renterName: 'John Doe',
      equipmentName: 'Hospital Bed',
      startDate: DateTime.now().subtract(const Duration(days: 10)),
      endDate: DateTime.now().subtract(const Duration(days: 3)),
      totalDurationDays: 7,
      totalPrice: 209.93,
      status: 'returned',
      requestedAt: DateTime.now().subtract(const Duration(days: 14)),
      approvedAt: DateTime.now().subtract(const Duration(days: 13)),
      checkedOutAt: DateTime.now().subtract(const Duration(days: 10)),
      returnedAt: DateTime.now().subtract(const Duration(days: 3)),
      isOverdue: false,
    ),
  ];

  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final filteredReservations = _filterReservations();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reservations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: _reservations.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No Reservations Yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your reservation history will appear here',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Filter Chip
                if (_selectedFilter != 'all')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.grey.shade100,
                    child: Row(
                      children: [
                        Text(
                          'Filter: ${_selectedFilter.replaceAll('_', ' ').toUpperCase()}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedFilter = 'all';
                            });
                          },
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  ),
                
                // Reservations List
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredReservations.length,
                    itemBuilder: (context, index) {
                      final reservation = filteredReservations[index];
                      return ReservationCard(
                        reservation: reservation,
                        onTap: () {
                          _showReservationDetails(reservation);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  List<Reservation> _filterReservations() {
    switch (_selectedFilter) {
      case 'pending':
        return _reservations.where((r) => r.status == 'pending').toList();
      case 'approved':
        return _reservations.where((r) => r.status == 'approved').toList();
      case 'checked_out':
        return _reservations.where((r) => r.status == 'checked_out').toList();
      case 'returned':
        return _reservations.where((r) => r.status == 'returned').toList();
      default:
        return _reservations;
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filter Reservations'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFilterOption('all', 'All Reservations'),
              _buildFilterOption('pending', 'Pending Approval'),
              _buildFilterOption('approved', 'Approved'),
              _buildFilterOption('checked_out', 'Checked Out'),
              _buildFilterOption('returned', 'Returned'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(String value, String label) {
    return ListTile(
      leading: Radio<String>(
        value: value,
        groupValue: _selectedFilter,
        onChanged: (String? newValue) {
          setState(() {
            _selectedFilter = newValue!;
          });
          Navigator.of(context).pop();
        },
      ),
      title: Text(label),
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
        Navigator.of(context).pop();
      },
    );
  }

  void _showReservationDetails(Reservation reservation) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Reservation #${reservation.id}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  reservation.equipmentName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _buildDetailItem('Status', reservation.status),
                _buildDetailItem('Start Date', _formatDate(reservation.startDate)),
                _buildDetailItem('End Date', _formatDate(reservation.endDate)),
                _buildDetailItem('Duration', '${reservation.totalDurationDays} days'),
                _buildDetailItem('Total Price', '\$${reservation.totalPrice.toStringAsFixed(2)}'),
                _buildDetailItem('Requested', _formatDateTime(reservation.requestedAt)),
                if (reservation.approvedAt != null)
                  _buildDetailItem('Approved', _formatDateTime(reservation.approvedAt!)),
                if (reservation.checkedOutAt != null)
                  _buildDetailItem('Checked Out', _formatDateTime(reservation.checkedOutAt!)),
                if (reservation.returnedAt != null)
                  _buildDetailItem('Returned', _formatDateTime(reservation.returnedAt!)),
                if (reservation.adminNotes != null)
                  _buildDetailItem('Admin Notes', reservation.adminNotes!),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}