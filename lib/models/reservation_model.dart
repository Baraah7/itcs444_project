// Rental reservations + lifecycle tracking
class Reservation {
  final String id;
  final String userId;
  final String equipmentId;
  final String equipmentName;
  final DateTime startDate;
  final DateTime endDate;
  final ReservationStatus status;
  final double totalPrice;
  final DateTime createdAt;
  final String? notes;

  Reservation({
    required this.id,
    required this.userId,
    required this.equipmentId,
    required this.equipmentName,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.totalPrice,
    required this.createdAt,
    this.notes,
  });

  // Convert Reservation object to Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'equipmentId': equipmentId,
      'equipmentName': equipmentName,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status.toString().split('.').last,
      'totalPrice': totalPrice,
      'createdAt': createdAt.toIso8601String(),
      'notes': notes,
    };
  }

  // Create Reservation object from Map
  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      equipmentId: json['equipmentId'] ?? '',
      equipmentName: json['equipmentName'] ?? '',
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      status: _parseReservationStatus(json['status']),
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
      notes: json['notes'],
    );
  }

  // Helper method to parse status string to enum
  static ReservationStatus _parseReservationStatus(String status) {
    switch (status) {
      case 'pending':
        return ReservationStatus.pending;
      case 'confirmed':
        return ReservationStatus.confirmed;
      case 'active':
        return ReservationStatus.active;
      case 'completed':
        return ReservationStatus.completed;
      case 'cancelled':
        return ReservationStatus.cancelled;
      default:
        return ReservationStatus.pending;
    }
  }

  // Copy with method for easy updates
  Reservation copyWith({
    String? id,
    String? userId,
    String? equipmentId,
    String? equipmentName,
    DateTime? startDate,
    DateTime? endDate,
    ReservationStatus? status,
    double? totalPrice,
    DateTime? createdAt,
    String? notes,
  }) {
    return Reservation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      equipmentId: equipmentId ?? this.equipmentId,
      equipmentName: equipmentName ?? this.equipmentName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      totalPrice: totalPrice ?? this.totalPrice,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }

  // Helper methods
  bool get isPending => status == ReservationStatus.pending;
  bool get isConfirmed => status == ReservationStatus.confirmed;
  bool get isActive => status == ReservationStatus.active;
  bool get isCompleted => status == ReservationStatus.completed;
  bool get isCancelled => status == ReservationStatus.cancelled;

  // Calculate duration in days
  int get durationInDays => endDate.difference(startDate).inDays;

  // Check if reservation is currently active
  bool get isCurrentlyActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate) && isConfirmed;
  }
}

enum ReservationStatus {
  pending,
  confirmed,
  active,
  completed,
  cancelled,
}