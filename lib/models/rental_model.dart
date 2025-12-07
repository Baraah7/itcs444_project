import 'package:flutter/material.dart';
class Rental {
  String id;
  String userId;
  String userFullName;
  String equipmentId;
  String equipmentName;
  String itemType;
  DateTime startDate;
  DateTime endDate;
  DateTime? actualReturnDate;
  double totalCost;
  String status; // 'pending', 'approved', 'checked_out', 'returned', 'cancelled', 'maintenance'
  DateTime createdAt;
  DateTime? updatedAt;
  String? adminNotes;
  int quantity;
  
  // Constructor
  Rental({
    required this.id,
    required this.userId,
    required this.userFullName,
    required this.equipmentId,
    required this.equipmentName,
    required this.itemType,
    required this.startDate,
    required this.endDate,
    this.actualReturnDate,
    required this.totalCost,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.adminNotes,
    this.quantity = 1,
  });
  
  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userFullName': userFullName,
      'equipmentId': equipmentId,
      'equipmentName': equipmentName,
      'itemType': itemType,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'actualReturnDate': actualReturnDate?.toIso8601String(),
      'totalCost': totalCost,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'adminNotes': adminNotes,
      'quantity': quantity,
    };
  }
  
  // Create from Map
  factory Rental.fromMap(Map<String, dynamic> map) {
    return Rental(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userFullName: map['userFullName'] ?? '',
      equipmentId: map['equipmentId'] ?? '',
      equipmentName: map['equipmentName'] ?? '',
      itemType: map['itemType'] ?? '',
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      actualReturnDate: map['actualReturnDate'] != null 
          ? DateTime.parse(map['actualReturnDate']) 
          : null,
      totalCost: (map['totalCost'] ?? 0).toDouble(),
      status: map['status'] ?? 'pending',
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt']) 
          : null,
      adminNotes: map['adminNotes'],
      quantity: map['quantity'] ?? 1,
    );
  }
  
  // Get rental duration in days
  int get durationInDays {
    return endDate.difference(startDate).inDays;
  }
  
  // Check if rental is overdue
  bool get isOverdue {
    if (status == 'checked_out' && endDate.isBefore(DateTime.now())) {
      return true;
    }
    return false;
  }
  
  // Calculate days remaining (only for checked_out status)
  int? get daysRemaining {
    if (status == 'checked_out') {
      final now = DateTime.now();
      if (now.isAfter(endDate)) return 0;
      return endDate.difference(now).inDays;
    }
    return null;
  }
  
  // Get days since pickup (for checked_out status)
  int? get daysSincePickup {
    if (status == 'checked_out') {
      final now = DateTime.now();
      return now.difference(startDate).inDays;
    }
    return null;
  }
  
  // Status color for UI
  Color get statusColor {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'checked_out':
        return isOverdue ? Colors.red : Colors.green;
      case 'returned':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      case 'maintenance':
        return Colors.purple;
      default:
        return Colors.black;
    }
  }
  
  // Status icon for UI
  IconData get statusIcon {
    switch (status) {
      case 'pending':
        return Icons.pending;
      case 'approved':
        return Icons.check_circle;
      case 'checked_out':
        return isOverdue ? Icons.warning : Icons.inventory;
      case 'returned':
        return Icons.check;
      case 'cancelled':
        return Icons.cancel;
      case 'maintenance':
        return Icons.build;
      default:
        return Icons.help;
    }
  }
  
  // Status text for display
  String get statusText {
    switch (status) {
      case 'pending':
        return 'Pending Approval';
      case 'approved':
        return 'Approved';
      case 'checked_out':
        return isOverdue ? 'Overdue' : 'Checked Out';
      case 'returned':
        return 'Returned';
      case 'cancelled':
        return 'Cancelled';
      case 'maintenance':
        return 'Under Maintenance';
      default:
        return status;
    }
  }
  
  // Check if rental can be cancelled (only pending or approved)
  bool get canBeCancelled {
    return status == 'pending' || status == 'approved';
  }
  
  // Check if rental can be checked out (only approved)
  bool get canBeCheckedOut {
    return status == 'approved';
  }
  
  // Check if rental can be marked as returned (only checked_out)
  bool get canBeReturned {
    return status == 'checked_out';
  }
  
  // Check if rental can be marked for maintenance (only returned)
  bool get canBeMarkedForMaintenance {
    return status == 'returned';
  }
  
  // Calculate late fee if overdue
  double calculateLateFee(double dailyRate) {
    if (!isOverdue) return 0.0;
    
    final overdueDays = DateTime.now().difference(endDate).inDays;
    return overdueDays * dailyRate * quantity * 1.5; // 50% penalty
  }
  
  // Get rental progress percentage (0-100)
  double get progressPercentage {
    final totalDays = durationInDays;
    if (totalDays == 0) return 0.0;
    
    if (status == 'returned' || status == 'cancelled' || status == 'maintenance') {
      return 100.0;
    }
    
    if (status == 'checked_out') {
      final daysSinceStart = DateTime.now().difference(startDate).inDays;
      return (daysSinceStart / totalDays * 100).clamp(0.0, 100.0);
    }
    
    // For pending/approved, base on status steps
    switch (status) {
      case 'pending':
        return 25.0;
      case 'approved':
        return 50.0;
      default:
        return 0.0;
    }
  }
  
  // Get next expected action
  String get nextAction {
    switch (status) {
      case 'pending':
        return 'Awaiting admin approval';
      case 'approved':
        return 'Ready for pickup';
      case 'checked_out':
        return 'Return by ${endDate.day}/${endDate.month}/${endDate.year}';
      case 'returned':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'maintenance':
        return 'Equipment under maintenance';
      default:
        return '';
    }
  }
  
  // Check if rental is active (approved or checked_out)
  bool get isActive {
    return status == 'approved' || status == 'checked_out';
  }
  
  // Check if rental is completed (returned, cancelled, or maintenance)
  bool get isCompleted {
    return status == 'returned' || status == 'cancelled' || status == 'maintenance';
  }
  
  // Get formatted date range string
  String get dateRangeString {
    final startFormat = '${startDate.day}/${startDate.month}/${startDate.year}';
    final endFormat = '${endDate.day}/${endDate.month}/${endDate.year}';
    return '$startFormat - $endFormat';
  }
  
  // Get formatted cost string
  String get formattedCost {
    return '\$${totalCost.toStringAsFixed(2)}';
  }
  
  // Get status badge color for UI
  Color get statusBadgeColor {
    switch (status) {
      case 'pending':
        return Colors.orange.withOpacity(0.1);
      case 'approved':
        return Colors.blue.withOpacity(0.1);
      case 'checked_out':
        return isOverdue ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1);
      case 'returned':
        return Colors.grey.withOpacity(0.1);
      case 'cancelled':
        return Colors.red.withOpacity(0.1);
      case 'maintenance':
        return Colors.purple.withOpacity(0.1);
      default:
        return Colors.grey.withOpacity(0.1);
    }
  }
  
  // Copy with method for updating
  Rental copyWith({
    String? id,
    String? userId,
    String? userFullName,
    String? equipmentId,
    String? equipmentName,
    String? itemType,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? actualReturnDate,
    double? totalCost,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? adminNotes,
    int? quantity,
  }) {
    return Rental(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userFullName: userFullName ?? this.userFullName,
      equipmentId: equipmentId ?? this.equipmentId,
      equipmentName: equipmentName ?? this.equipmentName,
      itemType: itemType ?? this.itemType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      actualReturnDate: actualReturnDate ?? this.actualReturnDate,
      totalCost: totalCost ?? this.totalCost,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      adminNotes: adminNotes ?? this.adminNotes,
      quantity: quantity ?? this.quantity,
    );
  }
  
  @override
  String toString() {
    return 'Rental(id: $id, equipment: $equipmentName, user: $userFullName, status: $status, dates: $dateRangeString)';
  }
  
  // Equality check
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Rental &&
        other.id == id &&
        other.userId == userId &&
        other.equipmentId == equipmentId &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.status == status;
  }
  
  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        equipmentId.hashCode ^
        startDate.hashCode ^
        endDate.hashCode ^
        status.hashCode;
  }
}