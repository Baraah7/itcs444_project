import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/reservation_service.dart';
import '../../utils/theme.dart';

class ReservationScreen extends StatefulWidget {
  final Map<String, dynamic> equipment;
  
  const ReservationScreen({super.key, required this.equipment});

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  final ReservationService _reservationService = ReservationService();
  final TextEditingController _notesController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  DateTime? _startDate;
  DateTime? _endDate;
  bool _checkingAvailability = false;
  bool _creatingReservation = false;
  bool _isLoading = false;
  String? _availabilityError;
  String? _reservationError;
  String? _reservationSuccess;
  
  // User trust score for auto-calculation
  int _userTrustScore = 0;
  bool _canChangeDuration = true;
  int _maxExtensionDays = 7;
  
  // Default daily rate (you can get this from equipment data)
  double _dailyRate = 0.0;
  int _totalDays = 0;
  double _totalPrice = 0.0;
  int _defaultDuration = 7;
  int _maxRentalDays = 30;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _loadUserTrustScore();
  }

  void _initializeData() {
    // Set default dates
    final now = DateTime.now();
    _startDate = now.add(const Duration(days: 1)); // Tomorrow
    _endDate = now.add(const Duration(days: 8)); // Default 7 days
    
    // Get daily rate from equipment or use default
    _dailyRate = (widget.equipment['rentalPrice'] as num?)?.toDouble() ?? 50.0;
    
    // Calculate max rental days based on equipment type
    _maxRentalDays = _getMaxRentalDays();
    _defaultDuration = _getDefaultDuration();
    
    _calculateTotal();
    _checkAvailability();
  }

  // Load user trust score from Firestore
  Future<void> _loadUserTrustScore() async {
    try {
      // TODO: Replace with actual user ID from your auth system
      const userId = 'current_user_id';
      
      // Get user's rental history
      final rentalsSnapshot = await _firestore
          .collection('reservations')
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: ['returned', 'completed'])
          .get();
      
      final returnedCount = rentalsSnapshot.docs.length;
      
      // Calculate trust score
      if (returnedCount >= 10) {
        _userTrustScore = 5; // Trusted user
        _canChangeDuration = true;
        _maxExtensionDays = 14;
      } else if (returnedCount >= 5) {
        _userTrustScore = 3; // Regular user
        _canChangeDuration = true;
        _maxExtensionDays = 7;
      } else if (returnedCount >= 1) {
        _userTrustScore = 1; // New user with history
        _canChangeDuration = true;
        _maxExtensionDays = 3;
      } else {
        _userTrustScore = 0; // First-time user
        _canChangeDuration = false;
        _maxExtensionDays = 0;
      }
      
      // Auto-calculate duration based on trust score
      _autoCalculateDuration();
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error loading trust score: $e');
    }
  }

  // Get maximum rental days based on equipment type
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
        return 14;
      case 'shower chair':
        return 21;
      default:
        return 30;
    }
  }

  // Get default duration based on equipment type
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
        return 7;
      case 'shower chair':
        return 10;
      default:
        return 7;
    }
  }

  // Auto-calculate duration based on item type and trust score
  void _autoCalculateDuration() {
    if (_startDate == null) return;
    
    int calculatedDuration = _getDefaultDuration();
    
    // Adjust based on trust score
    switch (_userTrustScore) {
      case 5: // Trusted user
        calculatedDuration = (calculatedDuration * 1.5).ceil();
        break;
      case 3: // Regular user
        calculatedDuration = (calculatedDuration * 1.25).ceil();
        break;
      case 1: // New user
        calculatedDuration = calculatedDuration;
        break;
      default: // First-time user
        calculatedDuration = (calculatedDuration * 0.75).ceil();
    }
    
    // Ensure within max limits
    calculatedDuration = calculatedDuration.clamp(1, _maxRentalDays);
    
    setState(() {
      _endDate = _startDate!.add(Duration(days: calculatedDuration - 1));
    });
    
    _calculateTotal();
    _checkAvailability();
  }

  void _calculateTotal() {
    if (_startDate == null || _endDate == null) return;
    
    _totalDays = _endDate!.difference(_startDate!).inDays + 1;
    _totalPrice = _totalDays * _dailyRate;
    
    if (mounted) {
      setState(() {});
    }
  }

  // Check availability when dates are selected
  Future<void> _checkAvailability() async {
    if (_startDate == null || _endDate == null) return;
    
    // Validate dates
    if (_startDate!.isBefore(DateTime.now())) {
      setState(() {
        _availabilityError = 'Start date cannot be in the past';
      });
      return;
    }
    
    if (_endDate!.isBefore(_startDate!)) {
      setState(() {
        _availabilityError = 'End date must be after start date';
      });
      return;
    }
    
    // Check if reservation is within max days
    if (_totalDays > _maxRentalDays) {
      setState(() {
        _availabilityError = 'Maximum rental period is $_maxRentalDays days for this equipment';
      });
      return;
    }
    
    setState(() {
      _checkingAvailability = true;
      _availabilityError = null;
      _isLoading = true;
    });
    
    final isAvailable = await _reservationService.checkItemAvailability(
      itemId: widget.equipment['itemId']!,
      equipmentId: widget.equipment['id']!,
      startDate: _startDate!,
      endDate: _endDate!,
    );
    
    setState(() {
      _checkingAvailability = false;
      _isLoading = false;
      if (!isAvailable) {
        _availabilityError = 'This item is not available for the selected dates. Please choose different dates.';
      } else {
        _calculateTotal();
      }
    });
  }

  // Create reservation
  Future<void> _createReservation() async {
    if (_startDate == null || _endDate == null) {
      setState(() {
        _reservationError = 'Please select start and end dates';
      });
      return;
    }
    
    if (_availabilityError != null) {
      return;
    }
    
    // Validate total days
    if (_totalDays < 1) {
      setState(() {
        _reservationError = 'Rental duration must be at least 1 day';
      });
      return;
    }
    
    if (_totalDays > _maxRentalDays) {
      setState(() {
        _reservationError = 'Maximum rental period is $_maxRentalDays days for this equipment';
      });
      return;
    }
    
    setState(() {
      _creatingReservation = true;
      _reservationError = null;
      _reservationSuccess = null;
      _isLoading = true;
    });
    
    // TODO: Get actual user data from your auth provider
    const userId = 'current_user_id'; // Replace with actual user ID
    const userEmail = 'user@example.com'; // Replace with actual email
    const userName = 'User Name'; // Replace with actual name
    
    final result = await _reservationService.createReservation(
      userId: userId,
      equipmentId: widget.equipment['id']!,
      itemId: widget.equipment['itemId']!,
      equipmentName: widget.equipment['name']!,
      itemName: widget.equipment['itemName']!,
      startDate: _startDate!,
      endDate: _endDate!,
      userEmail: userEmail,
      userName: userName,
      dailyRate: _dailyRate,
      notes: _notesController.text.trim(),
    );
    
    setState(() {
      _creatingReservation = false;
      _isLoading = false;
    });
    
    if (result['success'] == true) {
      setState(() {
        _reservationSuccess = result['message'];
      });
      
      // Navigate back after success
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(context, true); // Return success
        }
      });
    } else {
      setState(() {
        _reservationError = result['message'];
      });
    }
  }

  // Show duration change dialog
  Future<void> _showChangeDurationDialog() async {
    if (!_canChangeDuration) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Duration change is not available for your account level'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    final durationController = TextEditingController(text: _totalDays.toString());
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Rental Duration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current duration: $_totalDays days'),
            const SizedBox(height: 16),
            TextField(
              controller: durationController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'New duration (days)',
                border: OutlineInputBorder(),
                hintText: 'Enter number of days',
                suffixText: 'days',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You can change duration within ±$_maxExtensionDays days',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newDuration = int.tryParse(durationController.text);
              if (newDuration == null || newDuration < 1) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid number of days'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              final currentDuration = _totalDays;
              final change = newDuration - currentDuration;
              
              if (change.abs() > _maxExtensionDays) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('You can only change duration by ±$_maxExtensionDays days'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              if (newDuration > _maxRentalDays) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Maximum rental period is $_maxRentalDays days'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              setState(() {
                _endDate = _startDate!.add(Duration(days: newDuration - 1));
              });
              
              Navigator.pop(context);
              _checkAvailability();
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Make Reservation'),
        actions: [
          if (_userTrustScore > 0)
            Tooltip(
              message: 'Trust Level: $_userTrustScore/5',
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified, size: 14, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      'Level $_userTrustScore',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: _isLoading && !_checkingAvailability
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          if (widget.equipment['itemName'] != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.inventory_2,
                                    size: 14,
                                    color: AppColors.neutralGray,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Item: ${widget.equipment['itemName']}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.neutralGray,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          if (widget.equipment['serial'] != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.confirmation_number,
                                    size: 14,
                                    color: AppColors.neutralGray,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Serial: ${widget.equipment['serial']}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.neutralGray,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          if (widget.equipment['condition'] != null)
                            Row(
                              children: [
                                Icon(
                                  Icons.health_and_safety,
                                  size: 14,
                                  color: AppColors.neutralGray,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Condition: ${widget.equipment['condition']}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.neutralGray,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  // Progress Tracker
                  _buildProgressTracker(),
                  
                  const SizedBox(height: 24),

                  // Date Selection Section
                  const Text(
                    "Select Rental Period",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  
                  const SizedBox(height: 16),

                  // Start Date
                  Card(
                    elevation: 1,
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today, color: AppColors.primaryBlue),
                      title: const Text("Start Date"),
                      subtitle: Text(
                        _startDate == null 
                            ? 'Select date'
                            : DateFormat('EEEE, MMMM d, yyyy').format(_startDate!),
                      ),
                      trailing: const Icon(Icons.arrow_drop_down),
                      onTap: () async {
                        final selectedDate = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now().add(const Duration(days: 1)),
                          firstDate: DateTime.now().add(const Duration(days: 1)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        
                        if (selectedDate != null) {
                          setState(() {
                            _startDate = selectedDate;
                            // Auto-calculate end date based on trust score
                            _autoCalculateDuration();
                          });
                          _checkAvailability();
                        }
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 12),

                  // End Date with Change Duration Button
                  Card(
                    elevation: 1,
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today, color: AppColors.primaryBlue),
                      title: const Text("End Date"),
                      subtitle: Text(
                        _endDate == null 
                            ? 'Select date'
                            : DateFormat('EEEE, MMMM d, yyyy').format(_endDate!),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_canChangeDuration && _userTrustScore > 0)
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18),
                              onPressed: _showChangeDurationDialog,
                              tooltip: 'Change Duration',
                            ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                      onTap: () async {
                        final selectedDate = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? _startDate?.add(Duration(days: _defaultDuration - 1)) ?? DateTime.now().add(Duration(days: _defaultDuration)),
                          firstDate: _startDate ?? DateTime.now().add(const Duration(days: 1)),
                          lastDate: (_startDate ?? DateTime.now().add(const Duration(days: 1))).add(Duration(days: _maxRentalDays)),
                        );
                        
                        if (selectedDate != null) {
                          final newDuration = selectedDate.difference(_startDate!).inDays + 1;
                          
                          if (newDuration > _maxRentalDays) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Maximum rental period is $_maxRentalDays days'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          
                          // Check if user can change duration
                          if (_canChangeDuration) {
                            final currentDuration = _totalDays;
                            final change = newDuration - currentDuration;
                            
                            if (change.abs() > _maxExtensionDays && _userTrustScore > 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('You can only change duration by ±$_maxExtensionDays days'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                          }
                          
                          setState(() {
                            _endDate = selectedDate;
                          });
                          _checkAvailability();
                        }
                      },
                    ),
                  ),
                  
                  // Duration Info
                  if (_startDate != null && _endDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Duration: $_totalDays day${_totalDays != 1 ? 's' : ''}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          if (_canChangeDuration)
                            TextButton(
                              onPressed: _showChangeDurationDialog,
                              child: const Row(
                                children: [
                                  Icon(Icons.edit, size: 14),
                                  SizedBox(width: 4),
                                  Text('Change Duration'),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 20),

                  // Availability Check
                  if (_checkingAvailability)
                    const Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 8),
                          Text("Checking availability..."),
                        ],
                      ),
                    ),
                    
                  if (_availabilityError != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.error.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _availabilityError!,
                              style: TextStyle(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 24),

                  // Price Summary
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Price Summary",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          _priceRow("Daily Rate", "\$$_dailyRate/day"),
                          _priceRow("Rental Period", "$_totalDays days"),
                          const Divider(),
                          _priceRow(
                            "Total Price",
                            "\$${_totalPrice.toStringAsFixed(2)}",
                            isTotal: true,
                          ),
                          
                          // Auto-calculation info
                          if (_userTrustScore > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                _getTrustLevelInfo(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green[700],
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  // Notes (Optional)
                  const Text(
                    "Additional Notes (Optional)",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Any special requests or instructions...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),

                  // Reservation Messages
                  if (_reservationError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _reservationError!,
                                style: TextStyle(
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                  if (_reservationSuccess != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _reservationSuccess!,
                                style: TextStyle(
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_startDate != null && 
                                _endDate != null && 
                                _availabilityError == null &&
                                !_creatingReservation && 
                                !_checkingAvailability)
                          ? _createReservation
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _creatingReservation
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text("Creating Reservation..."),
                              ],
                            )
                          : const Text(
                              "Confirm Reservation",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),

                  // Cancel Button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          color: AppColors.neutralGray,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProgressTracker() {
    final steps = ['Select Dates', 'Check Availability', 'Confirm'];
    final completedSteps = [
      _startDate != null && _endDate != null,
      !_checkingAvailability && _availabilityError == null,
      false, // Confirmation is last step
    ];
    
    return Card(
      elevation: 2,
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
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: steps.asMap().entries.map((entry) {
                final index = entry.key;
                final step = entry.value;
                final isCompleted = completedSteps[index];
                final isCurrent = index == 0 
                    ? _startDate == null
                    : index == 1 
                        ? _startDate != null && !_checkingAvailability
                        : false;
                
                return Column(
                  children: [
                    // Step circle
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted 
                            ? AppColors.success
                            : isCurrent
                                ? AppColors.primaryBlue
                                : Colors.grey[300] ?? Colors.grey,
                        border: Border.all(
                          color: isCompleted 
                              ? AppColors.success
                              : isCurrent
                                  ? AppColors.primaryBlue
                                  : Colors.grey[400] ?? Colors.grey,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(Icons.check, size: 20, color: Colors.white)
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: isCurrent ? Colors.white : Colors.grey[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      step,
                      style: TextStyle(
                        fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                        color: isCurrent ? AppColors.primaryDark : Colors.grey[600],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            
            // Progress bar
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: completedSteps.where((c) => c).length / steps.length,
              backgroundColor: Colors.grey[200],
              color: AppColors.primaryBlue,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 8),
            Text(
              'Step ${completedSteps.where((c) => c).length} of ${steps.length}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTrustLevelInfo() {
    switch (_userTrustScore) {
      case 5:
        return '🌟 Trusted User: You can change duration by ±14 days';
      case 3:
        return '👍 Regular User: You can change duration by ±7 days';
      case 1:
        return '👋 New User: You can change duration by ±3 days';
      default:
        return '🔒 First-time User: Standard rental period applies';
    }
  }

  Widget _priceRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.neutralGray,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
              color: isTotal ? AppColors.success : AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}