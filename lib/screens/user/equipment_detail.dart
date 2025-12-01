import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/equipment_model.dart';
import '../../providers/equipment_provider.dart';
import '../../providers/reservation_provider.dart';
import '../../utils/theme.dart';
import 'reservation_screen.dart';

class EquipmentDetailScreen extends StatefulWidget {
  final String equipmentId;

  const EquipmentDetailScreen({
    Key? key,
    required this.equipmentId,
  }) : super(key: key);

  @override
  State<EquipmentDetailScreen> createState() => _EquipmentDetailScreenState();
}

class _EquipmentDetailScreenState extends State<EquipmentDetailScreen> {
  late Equipment _equipment;
  bool _isLoading = true;
  String? _availabilityMessage;

  @override
  void initState() {
    super.initState();
    _loadEquipment();
  }

  void _loadEquipment() {
    final equipmentProvider = Provider.of<EquipmentProvider>(context, listen: false);
    final equipment = equipmentProvider.getEquipmentById(widget.equipmentId);
    
    if (equipment != null) {
      setState(() {
        _equipment = equipment;
        _isLoading = false;
        _checkAvailability();
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _checkAvailability() {
    final reservationProvider = Provider.of<ReservationProvider>(context, listen: false);
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));
    
    final isAvailable = reservationProvider.isEquipmentAvailable(
      equipmentId: _equipment.id,
      startDate: now,
      endDate: nextWeek,
    );
    
    setState(() {
      if (!_equipment.isAvailable) {
        _availabilityMessage = 'Currently Unavailable';
      } else if (!isAvailable) {
        _availabilityMessage = 'Fully Booked for Next Week';
      } else {
        _availabilityMessage = null;
      }
    });
  }

  void _navigateToReservation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReservationScreen(equipment: _equipment),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.neutralGray,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color statusColor;
    String statusText;
    
    if (!_equipment.isAvailable) {
      statusColor = AppColors.error;
      statusText = 'UNAVAILABLE';
    } else if (_availabilityMessage != null) {
      statusColor = Colors.orange;
      statusText = 'LIMITED AVAILABILITY';
    } else {
      statusColor = AppColors.success;
      statusText = 'AVAILABLE';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _equipment.isAvailable ? Icons.check_circle : Icons.error,
            size: 16,
            color: statusColor,
          ),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Equipment Details'),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryBlue,
          ),
        ),
      );
    }

    final equipment = _equipment;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipment Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Share functionality
            },
            tooltip: 'Share',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Equipment Image/Icon
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primaryBlue.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    equipment.type.icon,
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Equipment Name and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    equipment.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                _buildStatusBadge(),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Equipment Type
            Text(
              equipment.type.name,
              style: TextStyle(
                fontSize: 18,
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Availability Message
            if (_availabilityMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _availabilityMessage!,
                        style: const TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Description
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
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      equipment.description,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Equipment Details Card
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
                    const Text(
                      'Equipment Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    _buildInfoRow('Condition:', equipment.condition),
                    _buildInfoRow('Quantity Available:', equipment.quantity.toString()),
                    _buildInfoRow('Location:', equipment.location),
                    
                    if (equipment.rentalPricePerDay != null)
                      _buildInfoRow(
                        'Daily Rental Rate:',
                        '\$${equipment.rentalPricePerDay!.toStringAsFixed(2)}',
                      ),
                    
                    if (equipment.isDonated)
                      _buildInfoRow('Donation Status:', 'This item was generously donated'),
                    
                    // Tags
                    if (equipment.tags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tags:',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: AppColors.neutralGray,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: equipment.tags.map((tag) {
                                return Chip(
                                  label: Text(tag),
                                  backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                                  labelStyle: const TextStyle(
                                    color: AppColors.primaryBlue,
                                    fontSize: 12,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Maintenance Info
            if (equipment.lastMaintenanceDate != null || equipment.nextMaintenanceDate != null)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.only(top: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.build_circle, color: AppColors.primaryBlue),
                          SizedBox(width: 8),
                          Text(
                            'Maintenance Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      if (equipment.lastMaintenanceDate != null)
                        _buildInfoRow(
                          'Last Maintenance:',
                          '${equipment.lastMaintenanceDate!.day}/${equipment.lastMaintenanceDate!.month}/${equipment.lastMaintenanceDate!.year}',
                        ),
                      
                      if (equipment.nextMaintenanceDate != null)
                        _buildInfoRow(
                          'Next Maintenance Due:',
                          '${equipment.nextMaintenanceDate!.day}/${equipment.nextMaintenanceDate!.month}/${equipment.nextMaintenanceDate!.year}',
                        ),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 32),
            
            // Action Buttons
            if (equipment.isAvailable && equipment.isRentable)
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _navigateToReservation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Reserve This Equipment',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        // Contact about equipment
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        side: const BorderSide(color: AppColors.primaryBlue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Contact About Availability',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    // Notify when available
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('We will notify you when this equipment becomes available'),
                        backgroundColor: AppColors.primaryBlue,
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    side: const BorderSide(color: AppColors.neutralGray),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Notify Me When Available',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.neutralGray,
                    ),
                  ),
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Safety Information
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.security, color: Colors.blue, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Important Information',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• All equipment is sanitized before and after each use\n'
                    '• Proper training will be provided if needed\n'
                    '• Contact care center for emergency support\n'
                    '• Return equipment in same condition\n'
                    '• Late returns may incur additional charges',
                    style: TextStyle(fontSize: 12, height: 1.5),
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
}