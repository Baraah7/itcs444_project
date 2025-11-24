import 'package:care_center_app/utils/theme.dart';
import 'package:flutter/material.dart';
import '../models/equipment_model.dart';
import '../widgets/common_widgets.dart';
import 'reservation_confirmation_screen.dart';

class EquipmentDetailScreen extends StatefulWidget {
  final Equipment equipment;

  const EquipmentDetailScreen({super.key, required this.equipment});

  @override
  State<EquipmentDetailScreen> createState() => _EquipmentDetailScreenState();
}

class _EquipmentDetailScreenState extends State<EquipmentDetailScreen> {
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  bool _isAvailable = true;
  int _duration = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.equipment.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Share functionality
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageGallery(),
            const SizedBox(height: 20),
            _buildBasicInfo(),
            const SizedBox(height: 20),
            _buildAvailabilitySection(),
            const SizedBox(height: 20),
            _buildDescription(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildImageGallery() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade200,
      ),
      child: widget.equipment.imageUrls.isNotEmpty
          ? PageView.builder(
              itemCount: widget.equipment.imageUrls.length,
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    widget.equipment.imageUrls[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.medical_services, size: 60, color: Colors.grey),
                      );
                    },
                  ),
                );
              },
            )
          : const Center(
              child: Icon(Icons.medical_services, size: 60, color: Colors.grey),
            ),
    );
  }

  Widget _buildBasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.equipment.name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.category, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              widget.equipment.type,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const Spacer(),
            StatusBadge(status: widget.equipment.status),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.place, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              widget.equipment.location,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (widget.equipment.rentalPricePerDay != null)
          Text(
            '\$${widget.equipment.rentalPricePerDay!.toStringAsFixed(2)} per day',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
      ],
    );
  }

  Widget _buildAvailabilitySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Check Availability',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildDatePicker(
              label: 'Start Date',
              selectedDate: _selectedStartDate,
              onDateSelected: (date) {
                setState(() {
                  _selectedStartDate = date;
                  if (_selectedEndDate != null && _selectedEndDate!.isBefore(date)) {
                    _selectedEndDate = null;
                  }
                });
                _checkAvailability();
              },
            ),
            const SizedBox(height: 16),
            _buildDatePicker(
              label: 'End Date',
              selectedDate: _selectedEndDate,
              onDateSelected: (date) {
                setState(() {
                  _selectedEndDate = date;
                });
                _checkAvailability();
              },
              enabled: _selectedStartDate != null,
            ),
            const SizedBox(height: 16),
            _buildAvailabilityStatus(),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? selectedDate,
    required Function(DateTime) onDateSelected,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: enabled ? Colors.black : Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: enabled
              ? () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    onDateSelected(picked);
                  }
                }
              : null,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: enabled ? Colors.white : Colors.grey.shade100,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: enabled ? AppTheme.primaryColor : Colors.grey,
                ),
                const SizedBox(width: 12),
                Text(
                  selectedDate != null
                      ? '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'
                      : 'Select Date',
                  style: TextStyle(
                    color: selectedDate != null ? Colors.black : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvailabilityStatus() {
    if (_selectedStartDate == null || _selectedEndDate == null) {
      return const SizedBox();
    }

    _duration = _selectedEndDate!.difference(_selectedStartDate!).inDays;
    final totalPrice = _duration * (widget.equipment.rentalPricePerDay ?? 0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isAvailable 
            ? AppTheme.successColor.withOpacity(0.1)
            : AppTheme.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isAvailable ? AppTheme.successColor : AppTheme.errorColor,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isAvailable ? Icons.check_circle : Icons.error,
            color: _isAvailable ? AppTheme.successColor : AppTheme.errorColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isAvailable ? 'Available for your dates' : 'Not available for selected dates',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _isAvailable ? AppTheme.successColor : AppTheme.errorColor,
                  ),
                ),
                if (_isAvailable) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Duration: $_duration days • Total: \$${totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(widget.equipment.description),
            const SizedBox(height: 16),
            const Text(
              'Specifications',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildSpecificationItem('Condition', widget.equipment.condition),
            _buildSpecificationItem('Quantity Available', '${widget.equipment.availableQuantity}'),
            if (widget.equipment.tags.isNotEmpty)
              _buildSpecificationItem('Tags', widget.equipment.tags.join(', ')),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecificationItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
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
      child: AppButton(
        text: 'Reserve Now',
        onPressed: () {
          if (_selectedStartDate != null && _selectedEndDate != null && _isAvailable) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReservationConfirmationScreen(
                  equipment: widget.equipment,
                  startDate: _selectedStartDate!,
                  endDate: _selectedEndDate!,
                  duration: _duration,
                ),
              ),
            );
          }
        },
      ),
    );
  }

  void _checkAvailability() {
    if (_selectedStartDate != null && _selectedEndDate != null) {
      setState(() {
        _isAvailable = widget.equipment.availableQuantity > 0;
      });
    }
  }
}