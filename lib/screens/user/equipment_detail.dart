import 'package:flutter/material.dart';
import '../../models/equipment_model.dart';
import 'reservation_screen.dart';

class EquipmentDetailScreen extends StatefulWidget {
  final Equipment equipment;

  const EquipmentDetailScreen({super.key, required this.equipment});

  @override
  State<EquipmentDetailScreen> createState() => _EquipmentDetailScreenState();
}

class _EquipmentDetailScreenState extends State<EquipmentDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.equipment.name),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEquipmentImage(),
                  const SizedBox(height: 16),
                  _buildEquipmentInfo(),
                  const SizedBox(height: 16),
                  _buildEquipmentDescription(),
                  const SizedBox(height: 16),
                  _buildSpecifications(),
                ],
              ),
            ),
          ),
          _buildReservationButton(),
        ],
      ),
    );
  }

  Widget _buildEquipmentImage() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12.0),
        image: widget.equipment.imageUrl.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(widget.equipment.imageUrl),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: widget.equipment.imageUrl.isEmpty
          ? const Icon(Icons.construction, size: 80, color: Colors.grey)
          : null,
    );
  }

  Widget _buildEquipmentInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.equipment.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: widget.equipment.isAvailable
                        ? const Color(0xFFE8F5E8)
                        : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.equipment.isAvailable
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                  child: Text(
                    widget.equipment.isAvailable ? 'Available' : 'Not Available',
                    style: TextStyle(
                      color: widget.equipment.isAvailable
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.category, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  widget.equipment.category,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  widget.equipment.location,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Daily Rate:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '\$${widget.equipment.price?.toStringAsFixed(2)}/day',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
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

  Widget _buildEquipmentDescription() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.equipment.description,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecifications() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Specifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildSpecificationItem('Category', widget.equipment.category),
            _buildSpecificationItem('Location', widget.equipment.location),
            _buildSpecificationItem(
              'Availability',
              widget.equipment.isAvailable ? 'Available' : 'Not Available',
            ),
            _buildSpecificationItem(
              'Added Date',
              widget.equipment.createdAt != null
                  ? '${widget.equipment.createdAt!.day}/${widget.equipment.createdAt!.month}/${widget.equipment.createdAt!.year}'
                  : 'Not specified',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecificationItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$title:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationButton() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: widget.equipment.isAvailable
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReservationScreen(
                        equipment: widget.equipment,
                      ),
                    ),
                  );
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1976D2),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Make Reservation',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}