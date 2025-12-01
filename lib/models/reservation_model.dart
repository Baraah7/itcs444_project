// Rental reservations + lifecycle tracking
import 'package:flutter/material.dart';

enum ReservationStatus {
  pending,
  approved,
  rejected,
  checkedOut,
  returned,
  cancelled,
  maintenance
}

extension ReservationStatusExtension on ReservationStatus {
  String get name {
    switch (this) {
      case ReservationStatus.pending:
        return 'Pending';
      case ReservationStatus.approved:
        return 'Approved';
      case ReservationStatus.rejected:
        return 'Rejected';
      case ReservationStatus.checkedOut:
        return 'Checked Out';
      case ReservationStatus.returned:
        return 'Returned';
      case ReservationStatus.cancelled:
        return 'Cancelled';
      case ReservationStatus.maintenance:
        return 'Under Maintenance';
    }
  }

  Color get color {
    switch (this) {
      case ReservationStatus.pending:
        return Colors.orange;
      case ReservationStatus.approved:
        return Colors.green;
      case ReservationStatus.rejected:
        return Colors.red;
      case ReservationStatus.checkedOut:
        return Colors.blue;
      case ReservationStatus.returned:
        return Colors.purple;
      case ReservationStatus.cancelled:
        return Colors.grey;
      case ReservationStatus.maintenance:
        return Colors.amber;
    }
  }

  IconData get icon {
    switch (this) {
      case ReservationStatus.pending:
        return Icons.pending;
      case ReservationStatus.approved:
        return Icons.check_circle;
      case ReservationStatus.rejected:
        return Icons.cancel;
      case ReservationStatus.checkedOut:
        return Icons.inventory;
      case ReservationStatus.returned:
        return Icons.assignment_returned;
      case ReservationStatus.cancelled:
        return Icons.cancel_outlined;
      case ReservationStatus.maintenance:
        return Icons.build;
    }
  }
}

class Reservation {
  final String id;
  final String equipmentId;
  final String equipmentName;
  final String equipmentType;
  final String userId;
  final String userName;
  final String userEmail;
  final String userPhone;
  final DateTime startDate;
  final DateTime endDate;
  final int rentalDays;
  final double dailyRate;
  final double totalCost;
  ReservationStatus status;
  final DateTime createdAt;
  final String? notes;
  final String? equipmentImage;
  final String? adminNotes;
  DateTime? approvedAt;
  DateTime? checkedOutAt;
  DateTime? returnedAt;
  DateTime? cancelledAt;

  Reservation({
    required this.id,
    required this.equipmentId,
    required this.equipmentName,
    required this.equipmentType,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.startDate,
    required this.endDate,
    required this.rentalDays,
    required this.dailyRate,
    required this.totalCost,
    required this.status,
    required this.createdAt,
    this.notes,
    this.equipmentImage,
    this.adminNotes,
    this.approvedAt,
    this.checkedOutAt,
    this.returnedAt,
    this.cancelledAt,
  });

  bool get isOverdue {
    if (status != ReservationStatus.checkedOut) return false;
    return DateTime.now().isAfter(endDate);
  }

  int get daysUntilDue {
    final now = DateTime.now();
    return endDate.difference(now).inDays;
  }

  bool get canCheckOut => status == ReservationStatus.approved;
  bool get canReturn => status == ReservationStatus.checkedOut;
  bool get canCancel => status == ReservationStatus.pending || 
                        status == ReservationStatus.approved;

  String get formattedStartDate => '${startDate.day}/${startDate.month}/${startDate.year}';
  String get formattedEndDate => '${endDate.day}/${endDate.month}/${endDate.year}';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'equipmentId': equipmentId,
      'equipmentName': equipmentName,
      'equipmentType': equipmentType,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'rentalDays': rentalDays,
      'dailyRate': dailyRate,
      'totalCost': totalCost,
      'status': status.index,
      'createdAt': createdAt.toIso8601String(),
      'notes': notes,
      'equipmentImage': equipmentImage,
      'adminNotes': adminNotes,
      'approvedAt': approvedAt?.toIso8601String(),
      'checkedOutAt': checkedOutAt?.toIso8601String(),
      'returnedAt': returnedAt?.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
    };
  }

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'] ?? '',
      equipmentId: json['equipmentId'] ?? '',
      equipmentName: json['equipmentName'] ?? '',
      equipmentType: json['equipmentType'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userEmail: json['userEmail'] ?? '',
      userPhone: json['userPhone'] ?? '',
      startDate: DateTime.parse(json['startDate'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(json['endDate'] ?? DateTime.now().add(const Duration(days: 7)).toIso8601String()),
      rentalDays: json['rentalDays'] ?? 7,
      dailyRate: json['dailyRate']?.toDouble() ?? 0.0,
      totalCost: json['totalCost']?.toDouble() ?? 0.0,
      status: ReservationStatus.values[json['status'] ?? 0],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      notes: json['notes'],
      equipmentImage: json['equipmentImage'],
      adminNotes: json['adminNotes'],
      approvedAt: json['approvedAt'] != null ? DateTime.parse(json['approvedAt']) : null,
      checkedOutAt: json['checkedOutAt'] != null ? DateTime.parse(json['checkedOutAt']) : null,
      returnedAt: json['returnedAt'] != null ? DateTime.parse(json['returnedAt']) : null,
      cancelledAt: json['cancelledAt'] != null ? DateTime.parse(json['cancelledAt']) : null,
    );
  }

  Reservation copyWith({
    String? id,
    String? equipmentId,
    String? equipmentName,
    String? equipmentType,
    String? userId,
    String? userName,
    String? userEmail,
    String? userPhone,
    DateTime? startDate,
    DateTime? endDate,
    int? rentalDays,
    double? dailyRate,
    double? totalCost,
    ReservationStatus? status,
    DateTime? createdAt,
    String? notes,
    String? equipmentImage,
    String? adminNotes,
    DateTime? approvedAt,
    DateTime? checkedOutAt,
    DateTime? returnedAt,
    DateTime? cancelledAt,
  }) {
    return Reservation(
      id: id ?? this.id,
      equipmentId: equipmentId ?? this.equipmentId,
      equipmentName: equipmentName ?? this.equipmentName,
      equipmentType: equipmentType ?? this.equipmentType,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userPhone: userPhone ?? this.userPhone,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      rentalDays: rentalDays ?? this.rentalDays,
      dailyRate: dailyRate ?? this.dailyRate,
      totalCost: totalCost ?? this.totalCost,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
      equipmentImage: equipmentImage ?? this.equipmentImage,
      adminNotes: adminNotes ?? this.adminNotes,
      approvedAt: approvedAt ?? this.approvedAt,
      checkedOutAt: checkedOutAt ?? this.checkedOutAt,
      returnedAt: returnedAt ?? this.returnedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
    );
  }
}