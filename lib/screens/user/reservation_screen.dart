import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/reservation_service.dart';
import '../../providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;

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
  int _maxAvailableQuantity = 1;
  bool _isLoading = false;
  bool _checkingAvailability = false;
  double _calculatedCost = 0.0;
  bool _isAvailable = true;
  String _availabilityMessage = '';
  bool _immediatePickup = false;
  
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  
  @override
  void initState() {
    super.initState();
    _initializeDates();
    _loadUserTrustScore();
    _loadAvailableQuantity();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAvailability();
    });
  }
  
  Future<void> _loadAvailableQuantity() async {
    final itemsSnapshot = await _firestore
        .collection('equipment')
        .doc(widget.equipment['id'])
        .collection('Items')
        .where('availability', isEqualTo: true)
        .get();
    
    setState(() {
      _maxAvailableQuantity = itemsSnapshot.docs.length;
      if (_maxAvailableQuantity == 0) {
        _maxAvailableQuantity = 1;
      }
      if (_quantity > _maxAvailableQuantity) {
        _quantity = _maxAvailableQuantity;
      }
    });
    
    _checkAvailability();
  }
  
  void _initializeDates() {
    final now = DateTime.now();
    setState(() {
      _startDate = now;
      _endDate = now.add(const Duration(days: 7));
    });
  }
  
  int _getMaxRentalDays() {
    final itemType = widget.equipment['type']?.toString().toLowerCase() ?? '';
    
    switch (itemType) {
      case 'wheelchair':
      case 'walker':
        return 30;
      case 'hospital bed':
      case 'oxygen machine':
        return 60;
      case 'crutches':
      case 'cane':
      case 'walking stick':
        return 14;
      case 'shower chair':
      case 'commode':
        return 21;
      default:
        return 30;
    }
  }
  
  int _getDefaultDuration() {
    final itemType = widget.equipment['type']?.toString().toLowerCase() ?? '';
    
    switch (itemType) {
      case 'wheelchair':
      case 'walker':
        return 14;
      case 'hospital bed':
      case 'oxygen machine':
        return 30;
      case 'crutches':
      case 'cane':
      case 'walking stick':
        return 7;
      case 'shower chair':
      case 'commode':
        return 10;
      default:
        return 7;
    }
  }
  
  Future<void> _loadUserTrustScore() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user == null) return;
    
    try {
      final rentalsSnapshot = await _firestore
          .collection('rentals')
          .where('userId', isEqualTo: user.docId ?? user.id.toString())
          .where('status', whereIn: ['returned', 'checked_out'])
          .get();
      
      final returnedCount = rentalsSnapshot.docs
          .where((doc) => doc['status'] == 'returned')
          .length;
      
      int trustScore = 0;
      if (returnedCount >= 10) trustScore = 3;
      else if (returnedCount >= 5) trustScore = 2;
      else if (returnedCount >= 1) trustScore = 1;
      
      setState(() {
        _userTrustScore = trustScore;
      });
      
      if (_immediatePickup) {
        _recalculateDatesBasedOnTrust();
      }
    } catch (e) {
      print('Error loading trust score: $e');
    }
  }
  
  void _recalculateDatesBasedOnTrust() {
    if (!_immediatePickup || _startDate == null) return;
    
    int baseDuration = _getDefaultDuration();
    
    switch (_userTrustScore) {
      case 3:
        baseDuration = (baseDuration * 1.5).ceil();
        break;
      case 2:
        baseDuration = (baseDuration * 1.25).ceil();
        break;
      case 1:
        break;
      default:
        baseDuration = (baseDuration * 0.75).ceil();
    }
    
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
    
    if (_quantity > _maxAvailableQuantity) {
      setState(() {
        _isAvailable = false;
        _availabilityMessage = 'Only $_maxAvailableQuantity item(s) available. You selected $_quantity.';
        _checkingAvailability = false;
      });
      _calculateCost();
      return;
    }
    
    setState(() {
      _isAvailable = true;
      _availabilityMessage = 'Equipment available - pending admin approval';
      _checkingAvailability = false;
    });
    
    _calculateCost();
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
              primary: Color(0xFF2B6C67),
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
              primary: Color(0xFF2B6C67),
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
              backgroundColor: const Color(0xFFEF4444),
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
    
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to make a reservation'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    
    final duration = _endDate!.difference(_startDate!).inDays;
    if (duration < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rental duration must be at least 1 day'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }
    
    final maxDays = _getMaxRentalDays();
    if (duration > maxDays) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum rental period is $maxDays days for this equipment'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
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
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                Navigator.pushNamed(context, '/my-reservations');
              },
            ),
          ),
        );
        
        Navigator.pop(context, rentalId);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: const Color(0xFFEF4444),
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
  
  @override
  Widget build(BuildContext context) {
    final dailyRate = (widget.equipment['rentalPrice'] ?? 0).toDouble();
    final duration = _endDate != null && _startDate != null 
        ? _endDate!.difference(_startDate!).inDays 
        : 0;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Make Reservation',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFE8ECEF),
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Equipment Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2B6C67), Color(0xFF1A4A47)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A4A47).withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.medical_services,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.equipment['name'] ?? 'Equipment',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (widget.equipment['type'] != null)
                          Text(
                            widget.equipment['type'],
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        if (dailyRate > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            '\$${dailyRate.toStringAsFixed(2)}/day',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Immediate Pickup Toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8ECEF)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A4A47).withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.flash_on,
                      color: Color(0xFFF59E0B),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Immediate Pickup',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Pick up today with auto-calculated return',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
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
                    activeColor: const Color(0xFF2B6C67),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Date Selection
            if (_immediatePickup)
              _buildImmediatePickupCard()
            else
              _buildDateSelection(),
            
            const SizedBox(height: 20),
            
            // Quantity Selector
            _buildQuantitySelector(),
            
            const SizedBox(height: 20),
            
            // Availability Status
            _buildAvailabilityStatus(),
            
            const SizedBox(height: 20),
            
            // Cost Summary
            _buildCostSummary(dailyRate, duration),
            
            const SizedBox(height: 24),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_isLoading || !_isAvailable || duration < 1 || duration > _getMaxRentalDays() || _quantity > _maxAvailableQuantity) 
                    ? null 
                    : _submitReservation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2B6C67),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF94A3B8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
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
                          Icon(Icons.check_circle_outline, size: 24),
                          SizedBox(width: 12),
                          Text(
                            'Submit Reservation',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Info Note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFF15803D),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _immediatePickup
                          ? 'Your reservation will be processed immediately. Admin approval required before pickup.'
                          : 'Your reservation request will be sent for admin approval. You\'ll be notified once approved.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF15803D),
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
  
  Widget _buildImmediatePickupCard() {
    final now = DateTime.now();
    final duration = _endDate != null && _startDate != null 
        ? _endDate!.difference(_startDate!).inDays 
        : _getDefaultDuration();
    final returnDate = _endDate ?? now.add(Duration(days: duration));
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECEF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A4A47).withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pickup Schedule',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pickup Date',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _dateFormat.format(now),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, color: Color(0xFF94A3B8), size: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Return Date',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _dateFormat.format(returnDate),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9F8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Duration: $duration days (auto-calculated)',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF2B6C67),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '• Item type: ${widget.equipment['type']}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                if (_userTrustScore > 0)
                  Text(
                    '• ${_getTrustLevelText()}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDateSelection() {
    final duration = _endDate != null && _startDate != null 
        ? _endDate!.difference(_startDate!).inDays 
        : 0;
    final maxDays = _getMaxRentalDays();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECEF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A4A47).withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rental Period',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Start Date',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _selectStartDate(context),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE8ECEF)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _startDate != null 
                                  ? _dateFormat.format(_startDate!)
                                  : 'Select Date',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const Icon(
                              Icons.calendar_today,
                              color: Color(0xFF64748B),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'End Date',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _selectEndDate(context),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE8ECEF)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _endDate != null 
                                  ? _dateFormat.format(_endDate!)
                                  : 'Select Date',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const Icon(
                              Icons.calendar_today,
                              color: Color(0xFF64748B),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (duration > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9F8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Duration',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2B6C67),
                        ),
                      ),
                      Text(
                        '$duration day${duration != 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2B6C67),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (duration / maxDays).clamp(0.0, 1.0),
                      backgroundColor: const Color(0xFFE8ECEF),
                      color: duration > maxDays ? const Color(0xFFEF4444) : const Color(0xFF2B6C67),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Min: 1 day',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        'Max: $maxDays days',
                        style: TextStyle(
                          fontSize: 11,
                          color: duration > maxDays ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                          fontWeight: duration > maxDays ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildQuantitySelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECEF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A4A47).withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quantity',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Items needed',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: _quantity > 1 ? () {
                      setState(() {
                        _quantity--;
                      });
                      _checkAvailability();
                    } : null,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _quantity > 1 ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _quantity > 1 ? const Color(0xFF2B6C67) : const Color(0xFFE8ECEF),
                        ),
                      ),
                      child: Icon(
                        Icons.remove,
                        size: 20,
                        color: _quantity > 1 ? const Color(0xFF2B6C67) : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2B6C67).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF2B6C67)),
                    ),
                    child: Text(
                      '$_quantity',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2B6C67),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _quantity < _maxAvailableQuantity ? () {
                      setState(() {
                        _quantity++;
                      });
                      _checkAvailability();
                    } : null,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _quantity < _maxAvailableQuantity 
                            ? const Color(0xFF2B6C67) 
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _quantity < _maxAvailableQuantity 
                              ? const Color(0xFF2B6C67) 
                              : const Color(0xFFE8ECEF),
                        ),
                      ),
                      child: Icon(
                        Icons.add,
                        size: 20,
                        color: _quantity < _maxAvailableQuantity 
                            ? Colors.white 
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available: $_maxAvailableQuantity',
                style: TextStyle(
                  fontSize: 12,
                  color: _quantity > _maxAvailableQuantity 
                      ? const Color(0xFFEF4444) 
                      : const Color(0xFF64748B),
                  fontWeight: _quantity > _maxAvailableQuantity 
                      ? FontWeight.w600 
                      : FontWeight.normal,
                ),
              ),
              if (_quantity > _maxAvailableQuantity)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFEF4444)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error, size: 12, color: Color(0xFFEF4444)),
                      SizedBox(width: 4),
                      Text(
                        'Exceeds available',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFFEF4444),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildAvailabilityStatus() {
    if (_checkingAvailability) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF86EFAC)),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF15803D),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Checking availability...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF15803D),
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isAvailable 
            ? const Color(0xFFDCFCE7)
            : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isAvailable 
              ? const Color(0xFF86EFAC)
              : const Color(0xFFFECACA),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isAvailable ? Icons.check_circle : Icons.error,
            color: _isAvailable ? const Color(0xFF15803D) : const Color(0xFFDC2626),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _availabilityMessage,
              style: TextStyle(
                color: _isAvailable ? const Color(0xFF15803D) : const Color(0xFFDC2626),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCostSummary(double dailyRate, int duration) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECEF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A4A47).withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Cost Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2B6C67).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: Color(0xFF2B6C67),
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildCostRow(
            'Daily Rate × $_quantity item${_quantity != 1 ? 's' : ''}',
            '\$${(dailyRate * _quantity).toStringAsFixed(2)}',
          ),
          
          const SizedBox(height: 8),
          
          _buildCostRow(
            'Duration',
            '$duration day${duration != 1 ? 's' : ''}',
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFE8ECEF)),
          ),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Cost',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                '\$${_calculatedCost.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2B6C67),
                ),
              ),
            ],
          ),
          
          if (_immediatePickup) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9F8),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '*Return date auto-calculated based on item type and trust level',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildCostRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
  
  @override
  void dispose() {
    super.dispose();
  }
}

