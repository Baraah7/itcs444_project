// lib/screens/user/my_reservations.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/reservation_service.dart';
import '../../utils/theme.dart';

class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({Key? key}) : super(key: key);
  
  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  final ReservationService _reservationService = ReservationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  final DateFormat _dateTimeFormat = DateFormat('MMM dd, yyyy hh:mm a');
  
  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    
    if (currentUser == null) {
      return _buildSignInRequired();
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reservations'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _reservationService.getUserRentals(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error.toString()}'),
            );
          }
          
          final reservations = snapshot.data ?? [];
          
          if (reservations.isEmpty) {
            return _buildEmptyState();
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reservations.length,
            itemBuilder: (context, index) {
              final reservation = reservations[index];
              return _buildReservationCard(reservation);
            },
          );
        },
      ),
    );
  }
  
  Widget _buildSignInRequired() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 20),
          const Text(
            'Please Sign In',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          const Text(
            'Sign in to view your reservations',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 20),
          const Text(
            'No Reservations Yet',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          const Text(
            'Start renting equipment to see your reservations here',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
  
  Widget _buildReservationCard(Map<String, dynamic> reservation) {
    // NULL-SAFE EXTRACTION WITH DEFAULTS
    final status = (reservation['status'] as String?) ?? 'pending';
    final startDate = (reservation['startDate'] as DateTime?) ?? DateTime.now();
    final endDate = (reservation['endDate'] as DateTime?) ?? 
        DateTime.now().add(const Duration(days: 1));
    final createdAt = (reservation['createdAt'] as DateTime?) ?? DateTime.now();
    final equipmentName = (reservation['equipmentName'] as String?) ?? 'Unknown Equipment';
    final itemName = (reservation['itemName'] as String?) ?? 'Unknown Item';
    final totalPrice = (reservation['totalPrice'] as num?)?.toDouble() ?? 0.0;
    final totalDays = (reservation['totalDays'] as int?) ?? 
        endDate.difference(startDate).inDays + 1;
    final canCancel = status == 'pending';
    
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    final notes = reservation['notes'] as String?;
    final adminNotes = reservation['adminNotes'] as String?;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status and cancel button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        statusIcon,
                        size: 14,
                        color: statusColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (canCancel)
                  TextButton(
                    onPressed: () => _cancelReservation(reservation['id'] as String? ?? ''),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Equipment info
            Text(
              equipmentName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              itemName,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Rental period
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'From',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _dateFormat.format(startDate),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward,
                  size: 18,
                  color: Colors.grey[400],
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'To',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _dateFormat.format(endDate),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Duration and ID
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$totalDays days',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                Text(
                  'ID: ${(reservation['id'] as String? ?? '').substring(0, (reservation['id'] as String? ?? '').length > 8 ? 8 : (reservation['id'] as String? ?? '').length)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Status tracker
            _buildStatusTracker(status, endDate),
            
            const SizedBox(height: 16),
            
            // Price summary
            if (totalPrice > 0)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primaryBlue.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Cost',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    Text(
                      '\$${totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
            
            // User notes
            if (notes != null && notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notes:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notes,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ],
            
            // Admin notes
            if (adminNotes != null && adminNotes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.amber.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: Colors.amber,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Admin Notes:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.amber,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      adminNotes,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
            
            // Created date
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Created: ${_dateTimeFormat.format(createdAt)}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusTracker(String status, DateTime endDate) {
    if (status == 'cancelled') {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.cancel,
              size: 16,
              color: Colors.red,
            ),
            SizedBox(width: 8),
            Text(
              'Reservation Cancelled',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
    
    final steps = ['Requested', 'Approved', 'Picked Up', 'Returned'];
    int currentStep = 0;
    
    switch (status) {
      case 'pending':
        currentStep = 0;
        break;
      case 'confirmed':
      case 'approved':
        currentStep = 1;
        break;
      case 'active':
      case 'checked_out':
        currentStep = 2;
        break;
      case 'completed':
      case 'returned':
        currentStep = 3;
        break;
      default:
        currentStep = 0;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status Progress',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isActive = index <= currentStep;
            
            return Expanded(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 24,
                        width: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive ? AppColors.primaryBlue : Colors.grey[300]!,
                          border: Border.all(
                            color: isActive ? AppColors.primaryBlue : Colors.grey[300]!,
                            width: 2,
                          ),
                        ),
                        child: isActive
                            ? const Icon(Icons.check, size: 14, color: Colors.white)
                            : null,
                      ),
                      if (index < steps.length - 1)
                        Positioned(
                          right: -20,
                          child: Container(
                            height: 2,
                            width: 40,
                            color: index < currentStep 
                                ? AppColors.primaryBlue 
                                : Colors.grey[300]!,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step,
                    style: TextStyle(
                      fontSize: 10,
                      color: isActive ? AppColors.primaryBlue : Colors.grey,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        
        // Progress bar
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: (currentStep + 1) / steps.length,
          backgroundColor: Colors.grey[200],
          color: AppColors.primaryBlue,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${((currentStep + 1) / steps.length * 100).toStringAsFixed(0)}% Complete',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
            if (status == 'checked_out' || status == 'active')
              _buildDaysRemaining(endDate: endDate),
          ],
        ),
      ],
    );
  }
  
  Widget _buildDaysRemaining({required DateTime endDate}) {
    final now = DateTime.now();
    final daysRemaining = endDate.difference(now).inDays;
    final isOverdue = daysRemaining < 0;
    
    return Text(
      isOverdue 
          ? '${daysRemaining.abs()} days overdue' 
          : '$daysRemaining days remaining',
      style: TextStyle(
        fontSize: 11,
        color: isOverdue ? Colors.red : Colors.green,
        fontWeight: FontWeight.w600,
      ),
    );
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
      case 'approved':
        return Colors.green;
      case 'active':
      case 'checked_out':
        return Colors.blue;
      case 'completed':
      case 'returned':
        return Colors.purple;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending;
      case 'confirmed':
      case 'approved':
        return Icons.check_circle;
      case 'active':
      case 'checked_out':
        return Icons.inventory;
      case 'completed':
      case 'returned':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }
  
  Future<void> _cancelReservation(String reservationId) async {
    if (reservationId.isEmpty) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Reservation'),
        content: const Text('Are you sure you want to cancel this reservation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        final success = await _reservationService.cancelReservation(reservationId);
        
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reservation cancelled successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to cancel reservation'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}