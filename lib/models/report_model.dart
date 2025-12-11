class ReportData {
  final String title;
  final String description;
  final DateTime generatedAt;
  final Map<String, dynamic> data;

  ReportData({
    required this.title,
    required this.description,
    required this.generatedAt,
    required this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'generatedAt': generatedAt.toIso8601String(),
      'data': data,
    };
  }

  factory ReportData.fromMap(Map<String, dynamic> map) {
    return ReportData(
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      generatedAt: DateTime.parse(map['generatedAt']),
      data: map['data'] ?? {},
    );
  }
}

class EquipmentUsageReport {
  final String equipmentId;
  final String equipmentName;
  final int totalRentals;
  final double totalRevenue;
  final double averageRentalDuration;
  final double utilizationRate;
  final int availableQuantity;
  final int totalQuantity;

  EquipmentUsageReport({
    required this.equipmentId,
    required this.equipmentName,
    required this.totalRentals,
    required this.totalRevenue,
    required this.averageRentalDuration,
    required this.utilizationRate,
    required this.availableQuantity,
    required this.totalQuantity,
  });

  bool get isHighPerforming => utilizationRate > 0.8;
  bool get isUnderutilized => utilizationRate < 0.3 && totalRentals > 0;
  
  String get performanceCategory {
    if (isHighPerforming) return 'High Performing';
    if (isUnderutilized) return 'Underutilized';
    return 'Normal';
  }

  Map<String, dynamic> toMap() {
    return {
      'equipmentId': equipmentId,
      'equipmentName': equipmentName,
      'totalRentals': totalRentals,
      'totalRevenue': totalRevenue,
      'averageRentalDuration': averageRentalDuration,
      'utilizationRate': utilizationRate,
      'availableQuantity': availableQuantity,
      'totalQuantity': totalQuantity,
    };
  }
}

class OverdueReport {
  final int totalOverdue;
  final double overdueRate;
  final double totalLateFees;
  final Map<String, int> equipmentOverdueCount;
  final List<OverdueItem> overdueItems;

  OverdueReport({
    required this.totalOverdue,
    required this.overdueRate,
    required this.totalLateFees,
    required this.equipmentOverdueCount,
    required this.overdueItems,
  });

  Map<String, dynamic> toMap() {
    return {
      'totalOverdue': totalOverdue,
      'overdueRate': overdueRate,
      'totalLateFees': totalLateFees,
      'equipmentOverdueCount': equipmentOverdueCount,
      'overdueItems': overdueItems.map((item) => item.toMap()).toList(),
    };
  }
}

class OverdueItem {
  final String rentalId;
  final String equipmentName;
  final String userName;
  final DateTime dueDate;
  final int daysOverdue;
  final double lateFee;

  OverdueItem({
    required this.rentalId,
    required this.equipmentName,
    required this.userName,
    required this.dueDate,
    required this.daysOverdue,
    required this.lateFee,
  });

  Map<String, dynamic> toMap() {
    return {
      'rentalId': rentalId,
      'equipmentName': equipmentName,
      'userName': userName,
      'dueDate': dueDate.toIso8601String(),
      'daysOverdue': daysOverdue,
      'lateFee': lateFee,
    };
  }
}

class MaintenanceReport {
  final String equipmentId;
  final String equipmentName;
  final DateTime maintenanceDate;
  final String userId;
  final String userName;
  final String? notes;
  final String status;

  MaintenanceReport({
    required this.equipmentId,
    required this.equipmentName,
    required this.maintenanceDate,
    required this.userId,
    required this.userName,
    this.notes,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'equipmentId': equipmentId,
      'equipmentName': equipmentName,
      'maintenanceDate': maintenanceDate.toIso8601String(),
      'userId': userId,
      'userName': userName,
      'notes': notes,
      'status': status,
    };
  }
}

class UsageAnalytics {
  final int totalRentals;
  final int totalEquipment;
  final int availableEquipment;
  final double utilizationRate;
  final double totalRevenue;
  final int activeRentals;
  final double averageRevenuePerRental;
  final List<MonthlyTrend> monthlyTrends;

  UsageAnalytics({
    required this.totalRentals,
    required this.totalEquipment,
    required this.availableEquipment,
    required this.utilizationRate,
    required this.totalRevenue,
    required this.activeRentals,
    required this.averageRevenuePerRental,
    required this.monthlyTrends,
  });

  Map<String, dynamic> toMap() {
    return {
      'totalRentals': totalRentals,
      'totalEquipment': totalEquipment,
      'availableEquipment': availableEquipment,
      'utilizationRate': utilizationRate,
      'totalRevenue': totalRevenue,
      'activeRentals': activeRentals,
      'averageRevenuePerRental': averageRevenuePerRental,
      'monthlyTrends': monthlyTrends.map((trend) => trend.toMap()).toList(),
    };
  }
}

class MonthlyTrend {
  final String month;
  final int rentalCount;
  final double revenue;

  MonthlyTrend({
    required this.month,
    required this.rentalCount,
    required this.revenue,
  });

  Map<String, dynamic> toMap() {
    return {
      'month': month,
      'rentalCount': rentalCount,
      'revenue': revenue,
    };
  }
}