//Reservation summary card
import 'package:flutter/material.dart';
import '../models/reservation_model.dart';
import '../utils/theme.dart';

class ReservationCard extends StatelessWidget {
  final Reservation reservation;
  final VoidCallback? onTap;
  final bool showUserInfo;
  final bool showActions;

  const ReservationCard({
    Key? key,
    required this.reservation,
    this.onTap,
    this.showUserInfo = false,
    this.showActions = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with equipment name and status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Equipment icon/placeholder
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getEquipmentIcon(reservation.equipmentType),
                      color: AppColors.primaryBlue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reservation.equipmentName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reservation.equipmentType,
                          style: TextStyle(
                            color: AppColors.neutralGray,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: reservation.status.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: reservation.status.color,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          reservation.status.icon,
                          size: 14,
                          color: reservation.status.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          reservation.status.name.toUpperCase(),
                          style: TextStyle(
                            color: reservation.status.color,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Reservation details
              _buildDetailRow(
                icon: Icons.calendar_today,
                label: 'Dates:',
                value: '${reservation.formattedStartDate} - ${reservation.formattedEndDate}',
              ),
              
              _buildDetailRow(
                icon: Icons.timer,
                label: 'Duration:',
                value: '${reservation.rentalDays} days',
              ),
              
              _buildDetailRow(
                icon: Icons.attach_money,
                label: 'Total:',
                value: '\$${reservation.totalCost.toStringAsFixed(2)}',
              ),
              
              if (showUserInfo)
                _buildDetailRow(
                  icon: Icons.person,
                  label: 'Reserved by:',
                  value: reservation.userName,
                ),
              
              // Notes preview
              if (reservation.notes != null && reservation.notes!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.note,
                        size: 16,
                        color: AppColors.neutralGray,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          reservation.notes!,
                          style: const TextStyle(fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Overdue/Upcoming warning
              if (reservation.status == ReservationStatus.checkedOut)
                Container(
                  margin: const EdgeInsets.only(top: 12),
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
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        reservation.isOverdue ? Icons.warning : Icons.info,
                        size: 16,
                        color: reservation.isOverdue
                            ? AppColors.error
                            : Colors.amber,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          reservation.isOverdue
                              ? 'OVERDUE - Please return immediately'
                              : 'Due in ${reservation.daysUntilDue} days',
                          style: TextStyle(
                            color: reservation.isOverdue
                                ? AppColors.error
                                : Colors.amber,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Quick actions
              if (showActions && reservation.canCancel)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onTap,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.neutralGray),
                          ),
                          child: const Text(
                            'View Details',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          // Handle cancel - this would trigger a dialog
                        },
                        icon: const Icon(Icons.cancel, size: 16),
                        label: const Text('Cancel'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.error),
                          foregroundColor: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Reservation ID
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'ID: ${reservation.id}',
                  style: TextStyle(
                    color: AppColors.neutralGray,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.neutralGray,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: AppColors.neutralGray,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getEquipmentIcon(String equipmentType) {
    switch (equipmentType.toLowerCase()) {
      case 'wheelchair':
        return Icons.accessible;
      case 'walker':
        return Icons.directions_walk;
      case 'crutches':
        return Icons.medical_services;
      case 'hospital bed':
        return Icons.bed;
      case 'oxygen machine':
        return Icons.air;
      case 'shower chair':
        return Icons.chair;
      case 'commode':
        return Icons.bathroom;
      default:
        return Icons.medical_services;
    }
  }
}