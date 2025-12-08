import 'package:flutter/material.dart';
import '../models/rental_model.dart';

class RentalTrackingCard extends StatelessWidget {
  final Rental rental;

  const RentalTrackingCard({required this.rental});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    rental.equipmentName,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: rental.statusBadgeColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: rental.statusColor),
                  ),
                  child: Text(
                    rental.statusText,
                    style: TextStyle(color: rental.statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildInfoRow(Icons.calendar_today, 'Period', rental.dateRangeString),
            SizedBox(height: 8),
            _buildInfoRow(Icons.attach_money, 'Total Cost', rental.formattedCost),
            if (rental.status == 'checked_out') ...[
              SizedBox(height: 8),
              _buildProgressBar(),
              SizedBox(height: 8),
              if (rental.daysRemaining != null)
                _buildInfoRow(
                  rental.isOverdue ? Icons.warning : Icons.timer,
                  rental.isOverdue ? 'Overdue' : 'Days Remaining',
                  rental.isOverdue ? '${rental.daysRemaining} days overdue' : '${rental.daysRemaining} days',
                  color: rental.isOverdue ? Colors.red : Colors.green,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey),
        SizedBox(width: 8),
        Text('$label: ', style: TextStyle(color: Colors.grey[600])),
        Text(value, style: TextStyle(fontWeight: FontWeight.w500, color: color)),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Progress', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            Text('${rental.progressPercentage.toStringAsFixed(0)}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        SizedBox(height: 4),
        LinearProgressIndicator(
          value: rental.progressPercentage / 100,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(rental.isOverdue ? Colors.red : Colors.blue),
        ),
      ],
    );
  }
}
