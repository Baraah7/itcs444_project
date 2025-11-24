import 'package:flutter/material.dart';
import '../utils/theme.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final Color? backgroundColor;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Text(
                text,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String status;
  
  const StatusBadge({super.key, required this.status});
  
  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    
    switch (status.toLowerCase()) {
      case 'pending':
        backgroundColor = AppTheme.warningColor.withOpacity(0.2);
        textColor = Colors.orange[800]!;
        break;
      case 'approved':
        backgroundColor = AppTheme.successColor.withOpacity(0.2);
        textColor = Colors.green[800]!;
        break;
      case 'checked_out':
        backgroundColor = AppTheme.primaryColor.withOpacity(0.2);
        textColor = AppTheme.primaryColor;
        break;
      case 'returned':
        backgroundColor = Colors.grey.withOpacity(0.2);
        textColor = Colors.grey[800]!;
        break;
      case 'declined':
        backgroundColor = AppTheme.errorColor.withOpacity(0.2);
        textColor = Colors.red[800]!;
        break;
      case 'available':
        backgroundColor = AppTheme.successColor.withOpacity(0.2);
        textColor = Colors.green[800]!;
        break;
      case 'under_maintenance':
        backgroundColor = AppTheme.warningColor.withOpacity(0.2);
        textColor = Colors.orange[800]!;
        break;
      default:
        backgroundColor = Colors.grey.withOpacity(0.2);
        textColor = Colors.grey[800]!;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class EquipmentCard extends StatelessWidget {
  final String name;
  final String type;
  final String imageUrl;
  final String condition;
  final double? pricePerDay;
  final bool isAvailable;
  final VoidCallback onTap;

  const EquipmentCard({
    super.key,
    required this.name,
    required this.type,
    required this.imageUrl,
    required this.condition,
    this.pricePerDay,
    required this.isAvailable,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade200,
                  image: imageUrl.isNotEmpty 
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
                ),
                child: imageUrl.isEmpty 
                  ? const Icon(Icons.medical_services, size: 40, color: Colors.grey)
                  : null,
              ),
              const SizedBox(width: 12),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      type,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getConditionColor(condition),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            condition,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (pricePerDay != null)
                          Text(
                            '\$${pricePerDay!.toStringAsFixed(2)}/day',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          isAvailable ? Icons.check_circle : Icons.remove_circle,
                          size: 16,
                          color: isAvailable ? AppTheme.successColor : AppTheme.errorColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isAvailable ? 'Available' : 'Not Available',
                          style: TextStyle(
                            fontSize: 12,
                            color: isAvailable ? AppTheme.successColor : AppTheme.errorColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'excellent':
        return AppTheme.successColor;
      case 'good':
        return AppTheme.accentColor;
      case 'fair':
        return AppTheme.warningColor;
      case 'poor':
        return AppTheme.errorColor;
      default:
        return Colors.grey;
    }
  }
}