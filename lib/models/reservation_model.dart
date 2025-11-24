class Reservation {
  final String id;
  final String renterId;
  final String equipmentId;
  final String renterName;
  final String equipmentName;
  final DateTime startDate;
  final DateTime endDate;
  final int totalDurationDays;
  final double totalPrice;
  final String status;
  final DateTime requestedAt;
  final DateTime? approvedAt;
  final DateTime? checkedOutAt;
  final DateTime? returnedAt;
  final String? adminNotes;
  final bool isOverdue;

  Reservation({
    required this.id,
    required this.renterId,
    required this.equipmentId,
    required this.renterName,
    required this.equipmentName,
    required this.startDate,
    required this.endDate,
    required this.totalDurationDays,
    required this.totalPrice,
    required this.status,
    required this.requestedAt,
    this.approvedAt,
    this.checkedOutAt,
    this.returnedAt,
    this.adminNotes,
    this.isOverdue = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'renterId': renterId,
      'equipmentId': equipmentId,
      'renterName': renterName,
      'equipmentName': equipmentName,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'totalDurationDays': totalDurationDays,
      'totalPrice': totalPrice,
      'status': status,
      'requestedAt': requestedAt.millisecondsSinceEpoch,
      'approvedAt': approvedAt?.millisecondsSinceEpoch,
      'checkedOutAt': checkedOutAt?.millisecondsSinceEpoch,
      'returnedAt': returnedAt?.millisecondsSinceEpoch,
      'adminNotes': adminNotes,
      'isOverdue': isOverdue,
    };
  }

  factory Reservation.fromMap(Map<String, dynamic> map) {
    return Reservation(
      id: map['id'],
      renterId: map['renterId'],
      equipmentId: map['equipmentId'],
      renterName: map['renterName'],
      equipmentName: map['equipmentName'],
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate']),
      endDate: DateTime.fromMillisecondsSinceEpoch(map['endDate']),
      totalDurationDays: map['totalDurationDays'],
      totalPrice: map['totalPrice'],
      status: map['status'],
      requestedAt: DateTime.fromMillisecondsSinceEpoch(map['requestedAt']),
      approvedAt: map['approvedAt'] != null ? DateTime.fromMillisecondsSinceEpoch(map['approvedAt']) : null,
      checkedOutAt: map['checkedOutAt'] != null ? DateTime.fromMillisecondsSinceEpoch(map['checkedOutAt']) : null,
      returnedAt: map['returnedAt'] != null ? DateTime.fromMillisecondsSinceEpoch(map['returnedAt']) : null,
      adminNotes: map['adminNotes'],
      isOverdue: map['isOverdue'] ?? false,
    );
  }

  Reservation copyWith({
    String? id,
    String? renterId,
    String? equipmentId,
    String? renterName,
    String? equipmentName,
    DateTime? startDate,
    DateTime? endDate,
    int? totalDurationDays,
    double? totalPrice,
    String? status,
    DateTime? requestedAt,
    DateTime? approvedAt,
    DateTime? checkedOutAt,
    DateTime? returnedAt,
    String? adminNotes,
    bool? isOverdue,
  }) {
    return Reservation(
      id: id ?? this.id,
      renterId: renterId ?? this.renterId,
      equipmentId: equipmentId ?? this.equipmentId,
      renterName: renterName ?? this.renterName,
      equipmentName: equipmentName ?? this.equipmentName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalDurationDays: totalDurationDays ?? this.totalDurationDays,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      checkedOutAt: checkedOutAt ?? this.checkedOutAt,
      returnedAt: returnedAt ?? this.returnedAt,
      adminNotes: adminNotes ?? this.adminNotes,
      isOverdue: isOverdue ?? this.isOverdue,
    );
  }
}