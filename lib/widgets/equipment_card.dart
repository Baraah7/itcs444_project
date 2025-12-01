//Equipment display card (used in lists)
import 'package:flutter/material.dart';
import '../models/equipment_model.dart';
import '../utils/theme.dart';

class EquipmentCard extends StatelessWidget {
  final Equipment equipment;
  final VoidCallback? onTap;
  final VoidCallback? onReserve;
  final bool showActionButton;

  const EquipmentCard({
    Key? key,
    required this.equipment,
    this.onTap,
    this.onReserve,
    this.showActionButton = true,
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
              // Header with name and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      equipment.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(equipment.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(equipment.status),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _getStatusText(equipment.status),
                      style: TextStyle(
                        color: _getStatusColor(equipment.status),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Type and condition
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      equipment.type.name,
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentMauve.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      equipment.condition,
                      style: TextStyle(
                        color: AppColors.accentMauve,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (equipment.isDonated) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.volunteer_activism, size: 12, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            'Donated',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Description
              Text(
                equipment.description,
                style: TextStyle(
                  color: AppColors.neutralGray,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 12),
              
              // Details row
              Row(
                children: [
                  _buildDetailItem(
                    icon: Icons.location_on,
                    text: equipment.location,
                  ),
                  const SizedBox(width: 16),
                  _buildDetailItem(
                    icon: Icons.inventory,
                    text: 'Qty: ${equipment.quantity}',
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Price and reservation button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (equipment.rentalPricePerDay != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '\$${equipment.rentalPricePerDay!.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        Text(
                          'per day',
                          style: TextStyle(
                            color: AppColors.neutralGray,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Not for rent',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  
                  if (showActionButton && equipment.isAvailable && equipment.isRentable)
                    ElevatedButton.icon(
                      onPressed: onReserve,
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: const Text('Reserve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  
                  if (showActionButton && (!equipment.isAvailable || !equipment.isRentable))
                    OutlinedButton(
                      onPressed: null,
                      child: const Text('Not Available'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.neutralGray,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: AppColors.neutralGray,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(EquipmentStatus status) {
    switch (status) {
      case EquipmentStatus.available:
        return Colors.green;
      case EquipmentStatus.rented:
        return Colors.blue;
      case EquipmentStatus.donated:
        return Colors.purple;
      case EquipmentStatus.underMaintenance:
        return Colors.amber;
      case EquipmentStatus.reserved:
        return Colors.orange;
    }
  }

  String _getStatusText(EquipmentStatus status) {
    switch (status) {
      case EquipmentStatus.available:
        return 'AVAILABLE';
      case EquipmentStatus.rented:
        return 'RENTED';
      case EquipmentStatus.donated:
        return 'DONATED';
      case EquipmentStatus.underMaintenance:
        return 'MAINTENANCE';
      case EquipmentStatus.reserved:
        return 'RESERVED';
    }
  }
}