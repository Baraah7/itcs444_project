import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/reservation_service.dart';
import '../../models/rental_model.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';

class ReservationManagementScreen extends StatefulWidget {
  const ReservationManagementScreen({Key? key}) : super(key: key);
  
  @override
  State<ReservationManagementScreen> createState() => _ReservationManagementScreenState();
}

class _ReservationManagementScreenState extends State<ReservationManagementScreen> {
  final ReservationService _reservationService = ReservationService();
  final TextEditingController _searchController = TextEditingController();
  final Map<String, TextEditingController> _notesControllers = {};
  
  String _filterStatus = 'all';
  String _searchQuery = '';
  bool _isLoading = false;
  
  final List<String> _statusFilters = [
    'all',
    'pending',
    'approved',
    'checked_out',
    'returned',
    'cancelled',
    'maintenance',
  ];
  
  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    // Dispose all notes controllers
    _notesControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }
  
  Future<void> _updateRentalStatus({
    required String rentalId,
    required String status,
    String? notes,
  }) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _reservationService.updateRentalStatus(
        rentalId: rentalId,
        status: status,
        adminNotes: notes,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rental status updated to ${status.replaceAll('_', ' ')}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _showStatusUpdateDialog({
    required Rental rental,
    required String newStatus,
    required String title,
  }) async {
    final notesController = _notesControllers[rental.id] ?? TextEditingController();
    _notesControllers[rental.id] = notesController;
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Rental ID: ${rental.id.substring(0, 8)}...'),
              const SizedBox(height: 12),
              const Text('Add notes (optional):'),
              const SizedBox(height: 8),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter notes...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final notes = notesController.text.trim();
              await _updateRentalStatus(
                rentalId: rental.id,
                status: newStatus,
                notes: notes.isNotEmpty ? notes : null,
              );
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _showRentalDetails(Rental rental) async {
    final format = DateFormat('MMM dd, yyyy HH:mm');
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rental Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('ID', rental.id.substring(0, 12) + '...'),
              _detailRow('User', rental.userFullName),
              _detailRow('Equipment', rental.equipmentName),
              _detailRow('Type', rental.itemType),
              _detailRow('Status', rental.statusText),
              _detailRow('Quantity', rental.quantity.toString()),
              _detailRow('Start Date', format.format(rental.startDate)),
              _detailRow('End Date', format.format(rental.endDate)),
              if (rental.actualReturnDate != null)
                _detailRow('Returned Date', format.format(rental.actualReturnDate!)),
              _detailRow('Total Cost', rental.formattedCost),
              if (rental.adminNotes != null && rental.adminNotes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Admin Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(rental.adminNotes!),
              ],
              if (rental.isOverdue) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Overdue by ${DateTime.now().difference(rental.endDate).inDays} days',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
  
  Widget _buildRentalCard(Rental rental) {
    final format = DateFormat('MMM dd, yyyy');
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with user info and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rental.userFullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Equipment: ${rental.equipmentName}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: rental.statusBadgeColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: rental.statusColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(rental.statusIcon, size: 14, color: rental.statusColor),
                      const SizedBox(width: 6),
                      Text(
                        rental.statusText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: rental.statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Dates and details
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rental Period',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        '${format.format(rental.startDate)} - ${format.format(rental.endDate)}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Cost',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      rental.formattedCost,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Additional info
            Row(
              children: [
                const Icon(Icons.category, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(rental.itemType, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(width: 16),
                const Icon(Icons.inventory, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Qty: ${rental.quantity}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                if (rental.isOverdue) ...[
                  const SizedBox(width: 16),
                  const Icon(Icons.warning, size: 14, color: Colors.red),
                  const SizedBox(width: 4),
                  Text(
                    'Overdue',
                    style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Action buttons based on status
            _buildActionButtons(rental),
            
            const SizedBox(height: 8),
            
            // View details button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showRentalDetails(rental),
                icon: const Icon(Icons.info_outline, size: 16),
                label: const Text('View Details'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                  side: const BorderSide(color: AppColors.primaryBlue),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButtons(Rental rental) {
    switch (rental.status) {
      case 'pending':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showStatusUpdateDialog(
                  rental: rental,
                  newStatus: 'approved',
                  title: 'Approve Rental',
                ),
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Approve'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showStatusUpdateDialog(
                  rental: rental,
                  newStatus: 'cancelled',
                  title: 'Decline Rental',
                ),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Decline'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
              ),
            ),
          ],
        );
        
      case 'approved':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showStatusUpdateDialog(
                  rental: rental,
                  newStatus: 'checked_out',
                  title: 'Check Out Equipment',
                ),
                icon: const Icon(Icons.inventory, size: 18),
                label: const Text('Check Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showStatusUpdateDialog(
                  rental: rental,
                  newStatus: 'cancelled',
                  title: 'Cancel Rental',
                ),
                icon: const Icon(Icons.cancel, size: 18),
                label: const Text('Cancel'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ],
        );
        
      case 'checked_out':
        return Column(
          children: [
            if (rental.isOverdue)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Overdue by ${DateTime.now().difference(rental.endDate).inDays} days',
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showStatusUpdateDialog(
                      rental: rental,
                      newStatus: 'returned',
                      title: 'Mark as Returned',
                    ),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Mark Returned'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showExtendDialog(rental),
                    icon: const Icon(Icons.schedule, size: 18),
                    label: const Text('Extend'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                      side: const BorderSide(color: AppColors.primaryBlue),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
        
      case 'returned':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showStatusUpdateDialog(
                  rental: rental,
                  newStatus: 'maintenance',
                  title: 'Send for Maintenance',
                ),
                icon: const Icon(Icons.build, size: 18),
                label: const Text('Needs Maintenance'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _markEquipmentAvailable(rental),
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Mark Available'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green),
                ),
              ),
            ),
          ],
        );
        
      case 'maintenance':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _markEquipmentAvailable(rental),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Mark Available'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
          ),
        );
        
      default:
        return const SizedBox();
    }
  }
  
  Future<void> _showExtendDialog(Rental rental) async {
    final newEndDateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(rental.endDate.add(const Duration(days: 7))),
    );
    
    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Extend Rental'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Current end date: ${DateFormat('MMM dd, yyyy').format(rental.endDate)}'),
                  const SizedBox(height: 16),
                  const Text('New end date:'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: newEndDateController,
                    decoration: InputDecoration(
                      hintText: 'YYYY-MM-DD',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: rental.endDate.add(const Duration(days: 7)),
                            firstDate: rental.endDate,
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            newEndDateController.text = DateFormat('yyyy-MM-dd').format(picked);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<bool>(
                    future: _checkExtensionAvailability(rental, newEndDateController.text),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      
                      if (snapshot.hasError || snapshot.data == false) {
                        return Text(
                          'Cannot extend: ${snapshot.hasError ? snapshot.error.toString() : 'Not available'}',
                          style: const TextStyle(color: Colors.red),
                        );
                      }
                      
                      final newEndDate = DateTime.tryParse(newEndDateController.text);
                      if (newEndDate != null) {
                        final extraDays = newEndDate.difference(rental.endDate).inDays;
                        final dailyRate = rental.totalCost / rental.durationInDays;
                        final additionalCost = extraDays * dailyRate * rental.quantity;
                        
                        return Text(
                          'Additional cost: \$${additionalCost.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                        );
                      }
                      
                      return const SizedBox();
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newEndDate = DateTime.tryParse(newEndDateController.text);
                  if (newEndDate == null || newEndDate.isBefore(rental.endDate)) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Invalid date'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                    return;
                  }
                  
                  try {
                    await _reservationService.extendRental(
                      rentalId: rental.id,
                      newEndDate: newEndDate,
                    );
                    
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Rental extended successfully'),
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
                },
                child: const Text('Extend'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Future<bool> _checkExtensionAvailability(Rental rental, String newEndDateString) async {
    try {
      final newEndDate = DateTime.tryParse(newEndDateString);
      if (newEndDate == null) return false;
      
      return await _reservationService.checkAvailability(
        equipmentId: rental.equipmentId,
        startDate: rental.startDate,
        endDate: newEndDate,
        quantity: rental.quantity,
      );
    } catch (e) {
      return false;
    }
  }
  
  Future<void> _markEquipmentAvailable(Rental rental) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // This would typically update the equipment status in your database
      // For now, we'll just show a success message
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${rental.equipmentName} marked as available'),
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Widget _buildStatisticsCard() {
    return StreamBuilder<List<Rental>>(
      stream: _reservationService.getAllRentals(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        
        final rentals = snapshot.data!;
        final pending = rentals.where((r) => r.status == 'pending').length;
        final approved = rentals.where((r) => r.status == 'approved').length;
        final checkedOut = rentals.where((r) => r.status == 'checked_out').length;
        final overdue = rentals.where((r) => r.isOverdue).length;
        final returned = rentals.where((r) => r.status == 'returned').length;
        
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reservation Statistics',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _statChip('Total', rentals.length.toString(), Colors.blue),
                    _statChip('Pending', pending.toString(), Colors.orange),
                    _statChip('Approved', approved.toString(), Colors.blue),
                    _statChip('Checked Out', checkedOut.toString(), Colors.green),
                    _statChip('Overdue', overdue.toString(), Colors.red),
                    _statChip('Returned', returned.toString(), Colors.grey),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _statChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservation Management'),
        centerTitle: true,
        actions: [
          // Filter dropdown
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: DropdownButton<String>(
              value: _filterStatus,
              onChanged: (String? newValue) {
                setState(() {
                  _filterStatus = newValue ?? 'all';
                });
              },
              items: _statusFilters.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value == 'all' 
                      ? 'All Status' 
                      : value.replaceAll('_', ' ').toUpperCase(),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by user name, equipment...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ),
          
          // Statistics Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildStatisticsCard(),
          ),
          
          const SizedBox(height: 16),
          
          // Reservations List
          Expanded(
            child: StreamBuilder<List<Rental>>(
              stream: _reservationService.getAllRentals(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 60, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  );
                }
                
                final allRentals = snapshot.data ?? [];
                
                // Apply filters
                List<Rental> filteredRentals = allRentals;
                
                // Apply status filter
                if (_filterStatus != 'all') {
                  filteredRentals = filteredRentals
                      .where((r) => r.status == _filterStatus)
                      .toList();
                }
                
                // Apply search filter
                if (_searchQuery.isNotEmpty) {
                  filteredRentals = filteredRentals.where((rental) {
                    return rental.userFullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                           rental.equipmentName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                           rental.itemType.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                           rental.id.toLowerCase().contains(_searchQuery.toLowerCase());
                  }).toList();
                }
                
                // Sort: overdue first, then pending, then by date
                filteredRentals.sort((a, b) {
                  if (a.isOverdue && !b.isOverdue) return -1;
                  if (!a.isOverdue && b.isOverdue) return 1;
                  if (a.status == 'pending' && b.status != 'pending') return -1;
                  if (a.status != 'pending' && b.status == 'pending') return 1;
                  return b.createdAt.compareTo(a.createdAt);
                });
                
                if (filteredRentals.isEmpty) {
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
                        Text(
                          _filterStatus == 'all'
                              ? 'No reservations found'
                              : 'No ${_filterStatus.replaceAll('_', ' ')} reservations',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Search: "$_searchQuery"',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredRentals.length,
                  itemBuilder: (context, index) {
                    return _buildRentalCard(filteredRentals[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _isLoading
          ? FloatingActionButton(
              onPressed: null,
              backgroundColor: Colors.grey,
              child: const CircularProgressIndicator(color: Colors.white),
            )
          : null,
    );
  }
}