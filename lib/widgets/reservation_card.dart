import 'package:flutter/material.dart';
import '../models/reservation_model.dart';
import '../utils/theme.dart';
import 'common_widgets.dart';

class ReservationCard extends StatelessWidget {
  final Reservation reservation;
  final VoidCallback? onTap;

  const ReservationCard({
    super.key,
    required this.reservation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      reservation.equipmentName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  StatusBadge(status: reservation.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Reservation #${reservation.id}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 12),
              _buildDetailRow('Dates', 
                  '${_formatDate(reservation.startDate)} - ${_formatDate(reservation.endDate)}'),
              _buildDetailRow('Duration', '${reservation.totalDurationDays} days'),
              _buildDetailRow('Total', '\$${reservation.totalPrice.toStringAsFixed(2)}'),
              _buildDetailRow('Requested', _formatDate(reservation.requestedAt)),
              if (reservation.adminNotes != null && reservation.adminNotes!.isNotEmpty)
                _buildDetailRow('Admin Notes', reservation.adminNotes!),
              if (reservation.isOverdue)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.errorColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: AppTheme.errorColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Overdue',
                        style: TextStyle(
                          color: AppTheme.errorColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(value),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}