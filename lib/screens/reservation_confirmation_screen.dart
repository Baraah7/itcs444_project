import 'package:care_center_app/utils/theme.dart';
import 'package:flutter/material.dart';
import '../models/equipment_model.dart';
import '../models/reservation_model.dart';
import '../widgets/common_widgets.dart';

class ReservationConfirmationScreen extends StatefulWidget {
  final Equipment equipment;
  final DateTime startDate;
  final DateTime endDate;
  final int duration;

  const ReservationConfirmationScreen({
    super.key,
    required this.equipment,
    required this.startDate,
    required this.endDate,
    required this.duration,
  });

  @override
  State<ReservationConfirmationScreen> createState() => _ReservationConfirmationScreenState();
}

class _ReservationConfirmationScreenState extends State<ReservationConfirmationScreen> {
  int _adjustedDuration = 0;
  double _totalPrice = 0;
  bool _isSubmitting = false;
  final int _minDuration = 1;
  final int _maxDuration = 30;

  @override
  void initState() {
    super.initState();
    _adjustedDuration = widget.duration;
    _calculatePrice();
  }

  void _calculatePrice() {
    setState(() {
      _totalPrice = _adjustedDuration * (widget.equipment.rentalPricePerDay ?? 0);
    });
  }

  void _adjustDuration(int change) {
    final newDuration = _adjustedDuration + change;
    if (newDuration >= _minDuration && newDuration <= _maxDuration) {
      setState(() {
        _adjustedDuration = newDuration;
        _calculatePrice();
      });
    }
  }

  Future<void> _submitReservation() async {
    setState(() {
      _isSubmitting = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    final reservation = Reservation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      renterId: 'user_123', // This would come from auth
      equipmentId: widget.equipment.id,
      renterName: 'John Doe', // This would come from user profile
      equipmentName: widget.equipment.name,
      startDate: widget.startDate,
      endDate: widget.startDate.add(Duration(days: _adjustedDuration)),
      totalDurationDays: _adjustedDuration,
      totalPrice: _totalPrice,
      status: 'pending',
      requestedAt: DateTime.now(),
      isOverdue: false,
    );

    setState(() {
      _isSubmitting = false;
    });

    // Show success dialog
    _showSuccessDialog(reservation);
  }

  void _showSuccessDialog(Reservation reservation) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppTheme.successColor),
              SizedBox(width: 8),
              Text('Reservation Submitted'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your reservation for ${widget.equipment.name} has been submitted.'),
              const SizedBox(height: 8),
              Text('Reservation ID: #${reservation.id}'),
              const SizedBox(height: 8),
              Text('Status: Pending Admin Approval'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Back to Equipment'),
            ),
            AppButton(
              text: 'View My Reservations',
              isFullWidth: false,
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, '/reservation_tracking');
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Reservation'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Equipment Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade200,
                        image: widget.equipment.imageUrls.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(widget.equipment.imageUrls.first),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: widget.equipment.imageUrls.isEmpty
                          ? const Icon(Icons.medical_services, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.equipment.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            widget.equipment.type,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Rental Period
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rental Period',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDateInfo('Start Date', widget.startDate),
                    _buildDateInfo('Original End Date', widget.endDate),
                    const SizedBox(height: 16),
                    
                    // Duration Adjustment
                    const Text(
                      'Adjust Duration (within range)',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: _adjustedDuration > _minDuration
                              ? () => _adjustDuration(-1)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                          color: _adjustedDuration > _minDuration
                              ? AppTheme.primaryColor
                              : Colors.grey,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$_adjustedDuration days',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _adjustedDuration < _maxDuration
                              ? () => _adjustDuration(1)
                              : null,
                          icon: const Icon(Icons.add_circle_outline),
                          color: _adjustedDuration < _maxDuration
                              ? AppTheme.primaryColor
                              : Colors.grey,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Allowed range: $_minDuration to $_maxDuration days',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Price Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Price Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildPriceRow('Daily Rate', '\$${(widget.equipment.rentalPricePerDay ?? 0).toStringAsFixed(2)}'),
                    _buildPriceRow('Duration', '$_adjustedDuration days'),
                    const Divider(),
                    _buildPriceRow(
                      'Total Amount',
                      '\$${_totalPrice.toStringAsFixed(2)}',
                      isTotal: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Terms and Conditions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Terms & Conditions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Reservation subject to admin approval\n'
                      '• Equipment must be returned in same condition\n'
                      '• Late returns may incur additional charges\n'
                      '• Please inspect equipment upon pickup',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppButton(
              text: 'Submit Reservation',
              isLoading: _isSubmitting,
              onPressed: () {
                if (!_isSubmitting) {
                  _submitReservation();
                }
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _isSubmitting
                  ? null
                  : () {
                      Navigator.pop(context);
                    },
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateInfo(String label, DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text('${date.day}/${date.month}/${date.year}'),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label),
          const Spacer(),
          Text(
            value,
            style: isTotal
                ? const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  )
                : null,
          ),
        ],
      ),
    );
  }
}