import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/reservation_service.dart';
import '../../models/rental_model.dart';
import '../../utils/theme.dart';

class ReservationManagementScreen extends StatefulWidget {
  const ReservationManagementScreen({super.key});
  
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
    'confirmed',
    'active',
    'cancelled',
    'returned',
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
    for (var controller in _notesControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
  
  Future<void> _updateReservationStatus({
    required String reservationId,
    required String status,
    String? adminNotes, String? notes,
  }) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _reservationService.updateReservationStatus(
        reservationId: reservationId,
        status: status,
        adminNotes: adminNotes,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reservation status updated to ${status.replaceAll('_', ' ')}'),
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
    required Map<String, dynamic> reservation,
    required String newStatus,
    required String title,
  }) async {
    final notesController = _notesControllers[reservation['id']] ?? TextEditingController();
    _notesControllers[reservation['id']] = notesController;
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Reservation ID: ${reservation['id'].substring(0, 8)}...'),
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
              await _updateReservationStatus(
                reservationId: reservation['id'],
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
  
  Future<void> _showReservationDetails(Map<String, dynamic> reservation) async {
    final format = DateFormat('MMM dd, yyyy HH:mm');
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reservation Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('ID', '${rental.id.substring(0, 12)}...'),
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
                Text(reservation['adminNotes'].toString()),
              ],
              if (_isOverdue(reservation)) ...[
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
                          'Overdue by ${DateTime.now().difference(reservation['endDate']).inDays} days',
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
  
  bool _isOverdue(Map<String, dynamic> reservation) {
    if (reservation['status'] != 'confirmed') return false;
    final endDate = reservation['endDate'] as DateTime;
    return DateTime.now().isAfter(endDate);
  }
  
  String _getStatusText(String status) {
    switch (status) {
      case 'pending': return 'Pending';
      case 'confirmed': return 'Confirmed';
      case 'active': return 'Active';
      case 'cancelled': return 'Cancelled';
      case 'returned': return 'Returned';
      default: return status;
    }
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.blue;
      case 'active': return Colors.green;
      case 'cancelled': return Colors.red;
      case 'returned': return Colors.grey;
      default: return Colors.grey;
    }
  }
  
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending': return Icons.pending;
      case 'confirmed': return Icons.check_circle_outline;
      case 'active': return Icons.inventory;
      case 'cancelled': return Icons.cancel;
      case 'returned': return Icons.done_all;
      default: return Icons.help_outline;
    }
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
  
  Widget _buildReservationCard(Map<String, dynamic> reservation) {
    final format = DateFormat('MMM dd, yyyy');
    final status = reservation['status'] ?? 'pending';
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    final isOverdue = _isOverdue(reservation);
    
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
                        reservation['userName'] ?? 'Unknown User',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${reservation['equipmentName']} - ${reservation['itemName']}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        _getStatusText(status),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
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
                        'Reservation Period',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        '${format.format(reservation['startDate'])} - ${format.format(reservation['endDate'])}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Total Cost',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      '\$${reservation['totalPrice']?.toStringAsFixed(2) ?? '0.00'}',
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
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${reservation['totalDays']} days', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(width: 16),
                const Icon(Icons.rate_review, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(reservation['dailyRate'] != null ? '\$${reservation['dailyRate']}/day' : 'No rate', 
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                if (isOverdue) ...[
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
            _buildActionButtons(reservation),
            
            const SizedBox(height: 8),
            
            // View details button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showReservationDetails(reservation),
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
  
  Widget _buildActionButtons(Map<String, dynamic> reservation) {
    final status = reservation['status'] ?? 'pending';
    
    switch (status) {
      case 'pending':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showStatusUpdateDialog(
                  reservation: reservation,
                  newStatus: 'confirmed',
                  title: 'Confirm Reservation',
                ),
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Confirm'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showStatusUpdateDialog(
                  reservation: reservation,
                  newStatus: 'cancelled',
                  title: 'Cancel Reservation',
                ),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Cancel'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
              ),
            ),
          ],
        );
        
      case 'confirmed':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showStatusUpdateDialog(
                  reservation: reservation,
                  newStatus: 'active',
                  title: 'Mark as Active',
                ),
                icon: const Icon(Icons.play_arrow, size: 18),
                label: const Text('Start Rental'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showStatusUpdateDialog(
                  reservation: reservation,
                  newStatus: 'cancelled',
                  title: 'Cancel Reservation',
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
        
      case 'active':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showStatusUpdateDialog(
                  reservation: reservation,
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
                onPressed: () => _showExtendDialog(reservation),
                icon: const Icon(Icons.schedule, size: 18),
                label: const Text('Extend'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                  side: const BorderSide(color: AppColors.primaryBlue),
                ),
              ),
            ),
          ],
        );
        
      default:
        return const SizedBox();
    }
  }
  
  Future<void> _showExtendDialog(Map<String, dynamic> reservation) async {
    final newEndDateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(reservation['endDate'].add(const Duration(days: 7))),
    );
    
    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final currentEndDate = reservation['endDate'] as DateTime;
          final dailyRate = reservation['dailyRate'] ?? 0.0;
          
          return AlertDialog(
            title: const Text('Extend Reservation'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Current end date: ${DateFormat('MMM dd, yyyy').format(currentEndDate)}'),
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
                            initialDate: currentEndDate.add(const Duration(days: 7)),
                            firstDate: currentEndDate,
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
                  if (newEndDateController.text.isNotEmpty)
                    FutureBuilder<bool>(
                      future: _checkExtensionAvailability(reservation, newEndDateController.text),
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
                          final extraDays = newEndDate.difference(currentEndDate).inDays;
                          final additionalCost = extraDays * dailyRate;
                          
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
                  if (newEndDate == null || newEndDate.isBefore(currentEndDate)) {
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
                    // Extend the reservation by updating end date
                    await _reservationService.updateReservationStatus(
                      reservationId: reservation['id'],
                      status: 'active',
                      adminNotes: 'Extended from ${DateFormat('yyyy-MM-dd').format(currentEndDate)} to ${DateFormat('yyyy-MM-dd').format(newEndDate)}',
                    );
                    
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Reservation extended successfully'),
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
  
  Future<bool> _checkExtensionAvailability(Map<String, dynamic> reservation, String newEndDateString) async {
    try {
      final newEndDate = DateTime.tryParse(newEndDateString);
      if (newEndDate == null) return false;
      
      return await _reservationService.checkItemAvailability(
        itemId: reservation['itemId'],
        equipmentId: reservation['equipmentId'],
        startDate: reservation['startDate'],
        endDate: newEndDate,
        excludeReservationId: reservation['id'],
      );
    } catch (e) {
      debugPrint('Error checking availability: $e');
      return false;
    }
  }
  
  Widget _buildStatisticsCard() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getAllReservationsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        
        final reservations = snapshot.data!;
        final pending = reservations.where((r) => r['status'] == 'pending').length;
        final confirmed = reservations.where((r) => r['status'] == 'confirmed').length;
        final active = reservations.where((r) => r['status'] == 'active').length;
        final overdue = reservations.where((r) => _isOverdue(r)).length;
        final cancelled = reservations.where((r) => r['status'] == 'cancelled').length;
        final returned = reservations.where((r) => r['status'] == 'returned').length;
        
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
                    _statChip('Total', reservations.length.toString(), Colors.blue),
                    _statChip('Pending', pending.toString(), Colors.orange),
                    _statChip('Confirmed', confirmed.toString(), Colors.blue),
                    _statChip('Active', active.toString(), Colors.green),
                    _statChip('Overdue', overdue.toString(), Colors.red),
                    _statChip('Cancelled', cancelled.toString(), Colors.grey),
                    _statChip('Returned', returned.toString(), Colors.purple),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Stream<List<Map<String, dynamic>>> _getAllReservationsStream() {
    return _reservationService.getAllReservationsStream();
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
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _getAllReservationsStream(),
              builder: (context, snapshot) {
                print('=== RESERVATION MANAGEMENT DEBUG ===');
                print('Connection State: ${snapshot.connectionState}');
                print('Has Error: ${snapshot.hasError}');
                print('Error: ${snapshot.error}');
                print('Has Data: ${snapshot.hasData}');
                print('Data Length: ${snapshot.data?.length ?? 0}');
                
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
                print('All Rentals Count: ${allRentals.length}');
                
                // Apply filters
                List<Map<String, dynamic>> filteredReservations = allReservations;
                
                // Apply status filter
                if (_filterStatus != 'all') {
                  filteredReservations = filteredReservations
                      .where((r) => r['status'] == _filterStatus)
                      .toList();
                }
                
                // Apply search filter
                if (_searchQuery.isNotEmpty) {
                  filteredReservations = filteredReservations.where((reservation) {
                    return (reservation['userName']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
                           (reservation['equipmentName']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
                           (reservation['itemName']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
                           (reservation['userEmail']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
                           (reservation['id']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
                  }).toList();
                }
                
                // Sort: overdue first, then pending, then by date
                filteredReservations.sort((a, b) {
                  final aOverdue = _isOverdue(a);
                  final bOverdue = _isOverdue(b);
                  if (aOverdue && !bOverdue) return -1;
                  if (!aOverdue && bOverdue) return 1;
                  if (a['status'] == 'pending' && b['status'] != 'pending') return -1;
                  if (a['status'] != 'pending' && b['status'] == 'pending') return 1;
                  return (b['createdAt'] as DateTime).compareTo(a['createdAt'] as DateTime);
                });
                
                if (filteredReservations.isEmpty) {
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
                  itemCount: filteredReservations.length,
                  itemBuilder: (context, index) {
                    return _buildReservationCard(filteredReservations[index]);
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