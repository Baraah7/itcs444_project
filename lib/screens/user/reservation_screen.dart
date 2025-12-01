import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/equipment_model.dart';
import '../../models/reservation_model.dart';
import '../../providers/equipment_provider.dart';
import '../../providers/reservation_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/equipment_card.dart';

class ReservationScreen extends StatefulWidget {
  final Equipment equipment;
  
  const ReservationScreen({Key? key, required this.equipment}) : super(key: key);

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  late DateTime _startDate;
  late DateTime _endDate;
  int _rentalDays = 7;
  double _totalCost = 0.0;
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;
  String? _availabilityError;
  bool _showDateError = false;

  @override
  void initState() {
    super.initState();
    // Start from tomorrow
    _startDate = DateTime.now().add(const Duration(days: 1));
    _endDate = _startDate.add(Duration(days: _rentalDays));
    _calculateTotal();
    _checkAvailability();
  }

  void _calculateTotal() {
    final dailyRate = widget.equipment.rentalPricePerDay ?? 0.0;
    _totalCost = dailyRate * _rentalDays;
  }

  void _checkAvailability() {
    final reservationProvider = Provider.of<ReservationProvider>(context, listen: false);
    final isAvailable = reservationProvider.isEquipmentAvailable(
      equipmentId: widget.equipment.id,
      startDate: _startDate,
      endDate: _endDate,
    );
    
    setState(() {
      _availabilityError = isAvailable ? null : 'Equipment not available for selected dates';
      _showDateError = _rentalDays < 1 || _rentalDays > 365;
    });
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        if (_endDate.isBefore(picked.add(const Duration(days: 1)))) {
          _endDate = picked.add(Duration(days: _rentalDays));
        }
        _rentalDays = _endDate.difference(_startDate).inDays;
        _calculateTotal();
        _checkAvailability();
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate.add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
        _rentalDays = _endDate.difference(_startDate).inDays;
        _calculateTotal();
        _checkAvailability();
      });
    }
  }

  void _updateDuration(int days) {
    if (days < 1 || days > 365) {
      setState(() {
        _showDateError = true;
      });
      return;
    }
    
    setState(() {
      _rentalDays = days;
      _endDate = _startDate.add(Duration(days: days));
      _calculateTotal();
      _checkAvailability();
      _showDateError = false;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submitReservation() async {
    // Validation
    if (_availabilityError != null) {
      _showError(_availabilityError!);
      return;
    }

    if (_rentalDays < 1 || _rentalDays > 365) {
      _showError('Duration must be between 1 and 365 days');
      return;
    }

    if (_startDate.isBefore(DateTime.now())) {
      _showError('Start date cannot be in the past');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 1));

    final reservationProvider = Provider.of<ReservationProvider>(context, listen: false);
    final equipmentProvider = Provider.of<EquipmentProvider>(context, listen: false);
    
    try {
      // Create reservation
      final reservation = reservationProvider.createReservation(
        equipment: widget.equipment,
        startDate: _startDate,
        endDate: _endDate,
        notes: _notesController.text.trim(),
      );
      
      // Add reservation
      reservationProvider.addReservation(reservation);
      
      // Update equipment quantity (simulate)
      equipmentProvider.updateEquipmentQuantity(
        widget.equipment.id,
        widget.equipment.quantity - 1,
      );
      
      // Show success dialog
      await _showSuccessDialog(reservation);
      
    } catch (e) {
      _showError('Failed to submit reservation. Please try again.');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _showSuccessDialog(Reservation reservation) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Reservation Submitted'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your reservation request has been submitted successfully!'),
              const SizedBox(height: 20),
              _buildSuccessDetail('Reservation ID:', reservation.id),
              _buildSuccessDetail('Equipment:', reservation.equipmentName),
              _buildSuccessDetail('Start Date:', reservation.formattedStartDate),
              _buildSuccessDetail('End Date:', reservation.formattedEndDate),
              _buildSuccessDetail('Duration:', '${reservation.rentalDays} days'),
              _buildSuccessDetail('Total Cost:', '\$${reservation.totalCost.toStringAsFixed(2)}'),
              const SizedBox(height: 20),
              const Text(
                'Next Steps:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('1. The admin will review your request'),
              const Text('2. You will receive a notification when approved'),
              const Text('3. Pick up equipment at the care center'),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Please bring your ID and this reservation ID when picking up the equipment.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to equipment list
            },
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/my-reservations',
                (route) => false,
              );
            },
            child: const Text('View My Reservations'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reservationProvider = Provider.of<ReservationProvider>(context, listen: false);
    final recommendedDays = reservationProvider.getRecommendedDuration(widget.equipment.type.name);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Make Reservation'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Equipment Summary
            EquipmentCard(
              equipment: widget.equipment,
              showActionButton: false,
            ),
            
            const SizedBox(height: 24),
            
            // Availability Warning
            if (_availabilityError != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _availabilityError!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Recommended Duration
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Recommended duration for ${widget.equipment.type.name}: $recommendedDays days',
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _updateDuration(recommendedDays);
                    },
                    child: const Text(
                      'Use this',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
            
            // Rental Duration Card
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
                      'Rental Duration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Quick duration buttons
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _DurationButton(
                            days: 3,
                            currentDays: _rentalDays,
                            onTap: _updateDuration,
                          ),
                          const SizedBox(width: 8),
                          _DurationButton(
                            days: 7,
                            currentDays: _rentalDays,
                            onTap: _updateDuration,
                          ),
                          const SizedBox(width: 8),
                          _DurationButton(
                            days: 14,
                            currentDays: _rentalDays,
                            onTap: _updateDuration,
                          ),
                          const SizedBox(width: 8),
                          _DurationButton(
                            days: 30,
                            currentDays: _rentalDays,
                            onTap: _updateDuration,
                          ),
                          const SizedBox(width: 8),
                          _DurationButton(
                            days: recommendedDays,
                            currentDays: _rentalDays,
                            onTap: _updateDuration,
                            isRecommended: true,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Custom duration input
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Custom Duration (days)',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.calendar_today),
                              errorText: _showDateError ? 'Must be 1-365 days' : null,
                            ),
                            keyboardType: TextInputType.number,
                            initialValue: _rentalDays.toString(),
                            onChanged: (value) {
                              final days = int.tryParse(value) ?? _rentalDays;
                              if (days >= 1 && days <= 365) {
                                _updateDuration(days);
                              } else {
                                setState(() {
                                  _showDateError = true;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primaryBlue),
                          ),
                          child: Text(
                            '$_rentalDays days',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Date Selection Card
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
                      'Select Dates',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
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
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _selectStartDate,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.primaryDark,
                                  minimumSize: const Size.fromHeight(50),
                                  side: const BorderSide(color: AppColors.neutralGray),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.calendar_today, size: 18),
                                    const SizedBox(width: 8),
                                    Text(_formatDate(_startDate)),
                                  ],
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
                              ElevatedButton(
                                onPressed: _selectEndDate,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.primaryDark,
                                  minimumSize: const Size.fromHeight(50),
                                  side: const BorderSide(color: AppColors.neutralGray),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.calendar_today, size: 18),
                                    const SizedBox(width: 8),
                                    Text(_formatDate(_endDate)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Date summary
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$_rentalDays days total',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 16, color: AppColors.neutralGray),
                          const SizedBox(width: 8),
                          Text(
                            'Due: ${_formatDate(_endDate)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Notes Card
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
                      'Additional Notes (Optional)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Add any special requirements or notes for the admin:',
                      style: TextStyle(
                        color: AppColors.neutralGray,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        hintText: 'E.g., Need extra cushion, prefer morning pickup, special requirements...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(16),
                      ),
                      maxLines: 4,
                      maxLength: 500,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Max 500 characters',
                      style: TextStyle(fontSize: 12, color: AppColors.neutralGray),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Summary Card
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
                      'Reservation Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    _SummaryRow(
                      label: 'Equipment:',
                      value: widget.equipment.name,
                    ),
                    _SummaryRow(
                      label: 'Type:',
                      value: widget.equipment.type.name,
                    ),
                    _SummaryRow(
                      label: 'Daily Rate:',
                      value: '\$${(widget.equipment.rentalPricePerDay ?? 0).toStringAsFixed(2)}/day',
                    ),
                    _SummaryRow(
                      label: 'Duration:',
                      value: '$_rentalDays days',
                    ),
                    _SummaryRow(
                      label: 'Start Date:',
                      value: _formatDate(_startDate),
                    ),
                    _SummaryRow(
                      label: 'End Date:',
                      value: _formatDate(_endDate),
                    ),
                    const Divider(height: 24),
                    _SummaryRow(
                      label: 'Total Cost:',
                      value: '\$${_totalCost.toStringAsFixed(2)}',
                      isTotal: true,
                    ),
                    
                    if (widget.equipment.isDonated)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          children: [
                            Icon(Icons.volunteer_activism, size: 16, color: AppColors.success),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'This is a donated item. Your rental supports equipment maintenance.',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
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
            
            const SizedBox(height: 24),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting || _availabilityError != null || _showDateError
                    ? null
                    : _submitReservation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSubmitting || _availabilityError != null || _showDateError
                      ? AppColors.neutralGray
                      : AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Submit Reservation Request',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Terms and Conditions
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: AppColors.neutralGray),
                      SizedBox(width: 8),
                      Text(
                        'Important Information',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.neutralGray,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'By submitting, you agree to our rental terms. The admin will review your request and contact you. Cancellations within 24 hours of pickup may incur fees. Please bring ID for pickup.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.neutralGray,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationButton extends StatelessWidget {
  final int days;
  final int currentDays;
  final Function(int) onTap;
  final bool isRecommended;

  const _DurationButton({
    required this.days,
    required this.currentDays,
    required this.onTap,
    this.isRecommended = false,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentDays == days;
    
    return GestureDetector(
      onTap: () => onTap(days),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryBlue
              : isRecommended
                  ? Colors.blue.withOpacity(0.1)
                  : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryBlue
                : isRecommended
                    ? Colors.blue
                    : AppColors.neutralGray,
            width: isRecommended ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isRecommended)
              const Icon(Icons.star, size: 14, color: Colors.blue),
            if (isRecommended) const SizedBox(width: 4),
            Text(
              '$days days',
              style: TextStyle(
                color: isSelected ? Colors.white : 
                       isRecommended ? Colors.blue : AppColors.primaryDark,
                fontWeight: isSelected || isRecommended ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.neutralGray,
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              fontSize: isTotal ? 18 : 16,
              color: isTotal ? AppColors.primaryBlue : AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}