import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/reservation_service.dart';
import '../../models/rental_model.dart';
import '../../utils/theme.dart';

class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({Key? key}) : super(key: key);
  
  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  final ReservationService _reservationService = ReservationService();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reservations'),
        actions: [
          StreamBuilder<List<Rental>>(
            stream: _reservationService.getUserRentals(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              final completedRentals = snapshot.data!.where((r) => r.status == 'cancelled' || r.status == 'returned').toList();
              if (completedRentals.isEmpty) return const SizedBox();
              return TextButton.icon(
                onPressed: () => _deleteAllCompleted(completedRentals),
                icon: const Icon(Icons.delete_sweep, color: Colors.red),
                label: const Text('Clear All', style: TextStyle(color: Colors.red)),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Rental>>(
        stream: _reservationService.getUserRentals(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          final rentals = snapshot.data ?? [];
          
          if (rentals.isEmpty) {
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
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rentals.length,
            itemBuilder: (context, index) {
              final rental = rentals[index];
              final format = DateFormat('MMM dd, yyyy');
              
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: rental.statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  rental.statusIcon,
                                  size: 16,
                                  color: rental.statusColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  rental.statusText.toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: rental.statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (rental.canBeCancelled)
                            TextButton(
                              onPressed: () => _cancelRental(rental.id),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          if (rental.status == 'cancelled' || rental.status == 'returned')
                            IconButton(
                              onPressed: () => _deleteRental(rental.id),
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              tooltip: 'Remove',
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Equipment info
                      Text(
                        rental.equipmentName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        rental.itemType,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Dates and details
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'From',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                Text(
                                  format.format(rental.startDate),
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward, color: Colors.grey),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'To',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                Text(
                                  format.format(rental.endDate),
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Duration and quantity
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16),
                              const SizedBox(width: 6),
                              Text('${rental.durationInDays} days'),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.inventory, size: 16),
                              const SizedBox(width: 6),
                              Text('Qty: ${rental.quantity}'),
                            ],
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Progress tracker based on status
                      _buildProgressTracker(rental),
                      
                      const SizedBox(height: 16),
                      
                      // Cost
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Cost',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              rental.formattedCost,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Next action
                      if (rental.nextAction.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: rental.statusColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: rental.statusColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  rental.nextAction,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: rental.statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      // Admin notes if any
                      if (rental.adminNotes != null && rental.adminNotes!.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),
                            const Text(
                              'Admin Notes:',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                            Text(rental.adminNotes!),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
  
  Widget _buildProgressTracker(Rental rental) {
    final steps = ['Requested', 'Approved', 'Checked Out', 'Returned'];
    final currentStep = rental.status == 'pending' ? 0
        : rental.status == 'approved' ? 1
        : rental.status == 'checked_out' ? 2
        : rental.status == 'returned' ? 3
        : rental.status == 'maintenance' ? 3  // Maintenance shows as returned
        : 3;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status Progress',
          style: TextStyle(fontSize: 12, color: Colors.grey),
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
        
        // Progress percentage
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: rental.progressPercentage / 100.0,
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
              '${rental.progressPercentage.toStringAsFixed(0)}% Complete',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
            if (rental.status == 'checked_out' && rental.daysRemaining != null)
              Text(
                '${rental.daysRemaining} days remaining',
                style: TextStyle(
                  fontSize: 11,
                  color: rental.isOverdue ? Colors.red : Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ],
    );
  }
  
  Future<void> _cancelRental(String rentalId) async {
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
        await _reservationService.cancelRental(rentalId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reservation cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteRental(String rentalId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Reservation'),
        content: const Text('Are you sure you want to remove this reservation from your list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Remove'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await _reservationService.deleteRental(rentalId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reservation removed successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteAllCompleted(List<Rental> rentals) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Completed'),
        content: Text('Remove all ${rentals.length} completed reservations?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        for (final rental in rentals) {
          await _reservationService.deleteRental(rental.id);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${rentals.length} reservations removed'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}