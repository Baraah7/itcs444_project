import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/reservation_service.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';

class ReservationScreen extends StatefulWidget {
  final Map<String, dynamic> equipment;
  
  const ReservationScreen({Key? key, required this.equipment}) : super(key: key);
  
  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  final ReservationService _reservationService = ReservationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  int _userTrustScore = 0;
  DateTime? _startDate;
  DateTime? _endDate;
  int _quantity = 1;
  bool _isLoading = false;
  bool _checkingAvailability = false;
  double _calculatedCost = 0.0;
  bool _isAvailable = true;
  String _availabilityMessage = '';
  bool _immediatePickup = false;
  
  // For date range selection
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  
  @override
  void initState() {
    super.initState();
    _initializeDates();
    _loadUserTrustScore(); 
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAvailability();
    });
  }
  
  void _initializeDates() {
    final now = DateTime.now();
    setState(() {
      _startDate = now;
      _endDate = now.add(const Duration(days: 7));
    });
  }
  
  // Get maximum rental days based on item type
  int _getMaxRentalDays() {
    final itemType = widget.equipment['type']?.toString().toLowerCase() ?? '';
    
    switch (itemType) {
      case 'wheelchair':
      case 'walker':
        return 30; // Max 30 days for mobility aids
      case 'hospital bed':
      case 'oxygen machine':
        return 60; // Max 60 days for medical equipment
      case 'crutches':
      case 'cane':
      case 'walking stick':
        return 14; // Max 14 days for temporary aids
      case 'shower chair':
      case 'commode':
        return 21; // Max 21 days for bathroom aids
      default:
        return 30; // Default max 30 days
    }
  }
  
  // Get default duration based on item type
  int _getDefaultDuration() {
    final itemType = widget.equipment['type']?.toString().toLowerCase() ?? '';
    
    switch (itemType) {
      case 'wheelchair':
      case 'walker':
        return 14; // 2 weeks for mobility aids
      case 'hospital bed':
      case 'oxygen machine':
        return 30; // 1 month for medical equipment
      case 'crutches':
      case 'cane':
      case 'walking stick':
        return 7; // 1 week for temporary aids
      case 'shower chair':
      case 'commode':
        return 10; // 10 days for bathroom aids
      default:
        return 7; // Default 1 week
    }
  }
  
  // Load user trust score
  Future<void> _loadUserTrustScore() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user == null) return;
    
    try {
      // Get user's rental history - use docId instead of user.id
      final rentalsSnapshot = await _firestore
          .collection('rentals')
          .where('userId', isEqualTo: user.docId ?? user.id.toString())
          .where('status', whereIn: ['returned', 'checked_out'])
          .get();
      
      final returnedCount = rentalsSnapshot.docs
          .where((doc) => doc['status'] == 'returned')
          .length;
      
      // Calculate trust score (simplified)
      int trustScore = 0;
      if (returnedCount >= 10) trustScore = 3; // Trusted user
      else if (returnedCount >= 5) trustScore = 2; // Regular user
      else if (returnedCount >= 1) trustScore = 1; // New user with history
      
      setState(() {
        _userTrustScore = trustScore;
      });
      
      // Recalculate dates if immediate pickup
      if (_immediatePickup) {
        _recalculateDatesBasedOnTrust();
      }
    } catch (e) {
      print('Error loading trust score: $e');
    }
  }
  
  // Recalculate dates based on trust
  void _recalculateDatesBasedOnTrust() {
    if (!_immediatePickup || _startDate == null) return;
    
    int baseDuration = _getDefaultDuration();
    
    // Adjust based on trust score
    switch (_userTrustScore) {
      case 3: // Trusted user - 50% longer
        baseDuration = (baseDuration * 1.5).ceil();
        break;
      case 2: // Regular user - 25% longer
        baseDuration = (baseDuration * 1.25).ceil();
        break;
      case 1: // New user with history - normal
        break;
      default: // Brand new user - shorter
        baseDuration = (baseDuration * 0.75).ceil();
    }
    
    // Ensure within max limits
    final maxDays = _getMaxRentalDays();
    baseDuration = baseDuration.clamp(1, maxDays);
    
    setState(() {
      _endDate = _startDate!.add(Duration(days: baseDuration));
    });
    
    _checkAvailability();
  }
  
  String _getTrustLevelText() {
    switch (_userTrustScore) {
      case 3: return 'Trusted User (+50% duration)';
      case 2: return 'Regular User (+25% duration)';
      case 1: return 'New User (standard duration)';
      default: return 'First-time User (reduced duration)';
    }
  }
  
  Future<void> _checkAvailability() async {
    if (_startDate == null || _endDate == null) return;
    
    setState(() {
      _checkingAvailability = true;
      _availabilityMessage = 'Checking availability...';
    });
    
    try {
      final isAvailable = await _reservationService.checkAvailability(
        equipmentId: widget.equipment['id'] ?? '',
        startDate: _startDate!,
        endDate: _endDate!,
        quantity: _quantity,
      );
      
      setState(() {
        _isAvailable = isAvailable;
        _availabilityMessage = isAvailable 
            ? 'Equipment is available for your selected dates'
            : 'Not enough equipment available for selected dates';
        _checkingAvailability = false;
      });
      
      _calculateCost();
    } catch (e) {
      setState(() {
        _checkingAvailability = false;
        _availabilityMessage = 'Error checking availability: ${e.toString().replaceAll("Exception: ", "")}';
        _isAvailable = false;
      });
    }
  }
  
  void _calculateCost() {
    if (_startDate == null || _endDate == null) return;
    
    final dailyRate = (widget.equipment['rentalPrice'] ?? 0).toDouble();
    final duration = _endDate!.difference(_startDate!).inDays;
    final total = dailyRate * duration * _quantity;
    
    setState(() {
      _calculatedCost = total;
    });
  }
  
  Future<void> _selectStartDate(BuildContext context) async {
    if (_immediatePickup) return;
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryBlue,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        // If end date is before new start date, adjust it
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = picked.add(const Duration(days: 1));
        }
      });
      await _checkAvailability();
    }
  }
  
  Future<void> _selectEndDate(BuildContext context) async {
    if (_immediatePickup) return;
    
    final maxDays = _getMaxRentalDays();
    final maxDate = (_startDate ?? DateTime.now()).add(Duration(days: maxDays));
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: maxDate,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryBlue,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      final duration = picked.difference(_startDate!).inDays;
      if (duration > maxDays) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Maximum rental period is $maxDays days for this item'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      
      setState(() {
        _endDate = picked;
      });
      await _checkAvailability();
    }
  }
  
  Future<void> _submitReservation() async {
    if (_startDate == null || _endDate == null) return;
    
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to make a reservation'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    
    // Validate date range
    final maxDays = _getMaxRentalDays();
    final duration = _endDate!.difference(_startDate!).inDays;
    if (duration > maxDays) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Maximum rental period is $maxDays days for this item'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    
    if (duration < 1) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rental duration must be at least 1 day'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final rentalId = await _reservationService.createRental(
        equipmentId: widget.equipment['id'] ?? '',
        equipmentName: widget.equipment['name'] ?? 'Equipment',
        itemType: widget.equipment['type'] ?? 'General',
        startDate: _startDate!,
        endDate: _endDate!,
        quantity: _quantity,
        dailyRate: (widget.equipment['rentalPrice'] ?? 0).toDouble(),
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Reservation submitted successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                // Navigate to my reservations
                Navigator.pushNamed(context, '/my-reservations');
              },
            ),
          ),
        );
        
        // Navigate back
        Navigator.pop(context, rentalId);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'),
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
  
  Widget _buildImmediatePickupCard() {
    final now = DateTime.now();
    final duration = _endDate != null && _startDate != null 
        ? _endDate!.difference(_startDate!).inDays 
        : _getDefaultDuration();
    final returnDate = _endDate ?? now.add(Duration(days: duration));
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade100, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on, color: Colors.orange.shade700),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Immediate Pickup Selected',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pickup Date',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        _dateFormat.format(now),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward, color: Colors.grey, size: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Return Date',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        _dateFormat.format(returnDate),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Duration: $duration days (auto-calculated based on:',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              '• Item type: ${widget.equipment['type']}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (_userTrustScore > 0)
              Text(
                '• Your trust level: ${_getTrustLevelText()}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDateSelection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Start Date',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _selectStartDate(context),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _startDate != null 
                                ? _dateFormat.format(_startDate!)
                                : 'Select Date',
                            style: const TextStyle(fontSize: 15),
                          ),
                          Icon(Icons.calendar_today, color: Colors.grey.shade600),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'End Date',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _selectEndDate(context),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _endDate != null 
                                ? _dateFormat.format(_endDate!)
                                : 'Select Date',
                            style: const TextStyle(fontSize: 15),
                          ),
                          Icon(Icons.calendar_today, color: Colors.grey.shade600),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        if (_startDate != null && _endDate != null) ...[
          const SizedBox(height: 16),
          _buildDurationInfo(),
        ],
      ],
    );
  }
  
  Widget _buildDurationInfo() {
    final duration = _endDate!.difference(_startDate!).inDays;
    final maxDays = _getMaxRentalDays();
    final progress = duration / maxDays;
    
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Rental Duration',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '$duration day${duration != 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              color: progress > 1 ? Colors.red : AppColors.primaryBlue,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Minimum: 1 day',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  'Maximum: $maxDays days',
                  style: TextStyle(
                    fontSize: 12,
                    color: progress > 1 ? Colors.red : Colors.grey[600],
                    fontWeight: progress > 1 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
            if (progress > 1) ...[
              const SizedBox(height: 8),
              Text(
                '⚠️ Exceeds maximum rental period',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildAvailabilityStatus() {
    if (_checkingAvailability) {
      return Card(
        color: Colors.blue.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Checking availability...',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Card(
      color: _isAvailable 
          ? Colors.green.withOpacity(0.1)
          : Colors.red.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _isAvailable ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _isAvailable ? Icons.check_circle : Icons.error,
              color: _isAvailable ? Colors.green : Colors.red,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _availabilityMessage,
                style: TextStyle(
                  color: _isAvailable ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProgressStep({
    required int step,
    required String title,
    required bool isCompleted,
    required bool isCurrent,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Row(
          children: [
            // Step Number
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted 
                    ? Colors.green
                    : isCurrent
                        ? AppColors.primaryBlue
                        : Colors.grey.shade300,
                border: Border.all(
                  color: isCompleted 
                      ? Colors.green
                      : isCurrent
                          ? AppColors.primaryBlue
                          : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, size: 18, color: Colors.white)
                    : Text(
                        '$step',
                        style: TextStyle(
                          color: isCurrent ? Colors.white : Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Step Title
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                  color: isCurrent ? AppColors.primaryDark : Colors.grey.shade700,
                ),
              ),
            ),
            
            // Status Indicator
            if (isCompleted)
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
            if (isCurrent && !isCompleted)
              const Icon(Icons.radio_button_checked, color: AppColors.primaryBlue, size: 20),
          ],
        ),
        
        // Connector Line (except for last step)
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 15, top: 4, bottom: 4),
            child: Container(
              width: 2,
              height: 20,
              color: isCompleted ? Colors.green : Colors.grey.shade300,
            ),
          ),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final dailyRate = (widget.equipment['rentalPrice'] ?? 0).toDouble();
    final duration = _endDate != null && _startDate != null 
        ? _endDate!.difference(_startDate!).inDays 
        : 0;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Make Reservation'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Equipment Info Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.equipment['name'] ?? 'Equipment',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (widget.equipment['type'] != null)
                      Text(
                        'Type: ${widget.equipment['type']}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    if (dailyRate > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Daily Rate: \$${dailyRate.toStringAsFixed(2)}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Immediate Pickup Toggle
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.flash_on, color: Colors.orange),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Immediate Pickup',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            'Pick up today with auto-calculated return date',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _immediatePickup,
                      onChanged: (value) {
                        setState(() {
                          _immediatePickup = value;
                          if (value) {
                            final now = DateTime.now();
                            _startDate = now;
                            _endDate = now.add(Duration(days: _getDefaultDuration()));
                            _recalculateDatesBasedOnTrust();
                          }
                        });
                        _checkAvailability();
                      },
                      activeColor: AppColors.primaryBlue,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Date Selection or Immediate Pickup Display
            if (_immediatePickup)
              _buildImmediatePickupCard()
            else
              _buildDateSelection(),
            
            const SizedBox(height: 24),
            
            // Quantity Selector
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quantity',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Number of items needed'),
                        Row(
                          children: [
                            IconButton(
                              icon: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: const Icon(Icons.remove, size: 20),
                              ),
                              onPressed: () {
                                if (_quantity > 1) {
                                  setState(() {
                                    _quantity--;
                                  });
                                  _checkAvailability();
                                }
                              },
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.primaryBlue),
                                borderRadius: BorderRadius.circular(8),
                                color: AppColors.primaryBlue.withOpacity(0.1),
                              ),
                              child: Text(
                                '$_quantity',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primaryBlue,
                                ),
                                child: const Icon(Icons.add, size: 20, color: Colors.white),
                              ),
                              onPressed: () {
                                setState(() {
                                  _quantity++;
                                });
                                _checkAvailability();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Availability Status
            _buildAvailabilityStatus(),
            
            const SizedBox(height: 24),
            
            // Cost Summary
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Cost Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(Icons.receipt, color: AppColors.primaryBlue),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Daily Rate × $_quantity item${_quantity != 1 ? 's' : ''}'),
                        Text('\$${(dailyRate * _quantity).toStringAsFixed(2)}'),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Duration'),
                        Text('$duration day${duration != 1 ? 's' : ''}'),
                      ],
                    ),
                    
                    const Divider(height: 24),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Cost',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '\$${_calculatedCost.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    
                    if (_immediatePickup) ...[
                      const SizedBox(height: 12),
                      Text(
                        '*Return date auto-calculated based on item type and your trust level',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Progress Tracker section
            const SizedBox(height: 24),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reservation Progress',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Progress Steps
                    _buildProgressStep(
                      step: 1,
                      title: 'Select Dates & Quantity',
                      isCompleted: _startDate != null && _endDate != null && _quantity > 0,
                      isCurrent: true,
                    ),
                    
                    _buildProgressStep(
                      step: 2,
                      title: 'Check Availability',
                      isCompleted: !_checkingAvailability && _availabilityMessage.isNotEmpty,
                      isCurrent: false,
                    ),
                    
                    _buildProgressStep(
                      step: 3,
                      title: 'Review & Submit',
                      isCompleted: false,
                      isCurrent: false,
                      isLast: true,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Status Summary
                    if (!_checkingAvailability && _availabilityMessage.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isAvailable ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isAvailable ? Icons.check_circle : Icons.error,
                              color: _isAvailable ? Colors.green : Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _isAvailable 
                                    ? 'Ready to submit reservation'
                                    : 'Cannot proceed: ${_availabilityMessage.toLowerCase()}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _isAvailable ? Colors.green : Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_isLoading || !_isAvailable || duration < 1 || duration > _getMaxRentalDays()) 
                    ? null 
                    : _submitReservation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.handshake),
                          SizedBox(width: 12),
                          Text(
                            'Submit Reservation',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Info Note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _immediatePickup
                          ? 'Your reservation will be processed immediately. Admin approval is required before pickup.'
                          : 'Your reservation request will be sent for admin approval. You\'ll be notified once approved.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    super.dispose();
  }
}

