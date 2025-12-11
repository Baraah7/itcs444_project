import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rental_model.dart';

class ReportsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Most frequently rented equipment
  Future<List<Map<String, dynamic>>> getMostRentedEquipment({int limit = 10}) async {
    final snapshot = await _firestore.collection('rentals').get();
    final equipmentCount = <String, Map<String, dynamic>>{};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final equipmentId = data['equipmentId'] as String;
      final equipmentName = data['equipmentName'] as String;
      
      if (equipmentCount.containsKey(equipmentId)) {
        equipmentCount[equipmentId]!['count']++;
      } else {
        equipmentCount[equipmentId] = {
          'id': equipmentId,
          'name': equipmentName,
          'count': 1,
        };
      }
    }

    final sortedList = equipmentCount.values.toList()
      ..sort((a, b) => b['count'].compareTo(a['count']));
    
    return sortedList.take(limit).toList();
  }

  // Most frequently donated equipment
  Future<List<Map<String, dynamic>>> getMostDonatedEquipment({int limit = 10}) async {
    final snapshot = await _firestore.collection('donations').get();
    final equipmentCount = <String, int>{};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final equipmentName = data['equipmentName'] as String? ?? 'Unknown';
      equipmentCount[equipmentName] = (equipmentCount[equipmentName] ?? 0) + 1;
    }

    final sortedList = equipmentCount.entries
        .map((e) => {'name': e.key, 'count': e.value})
        .toList()
      ..sort((a, b) => (b['count'] as int? ?? 0).compareTo(a['count'] as int? ?? 0));
    
    return sortedList.take(limit).toList();
  }

  // Usage analytics
  Future<Map<String, dynamic>> getUsageAnalytics() async {
    final rentalsSnapshot = await _firestore.collection('rentals').get();
    final equipmentSnapshot = await _firestore.collection('equipment').get();
    
    int totalRentals = rentalsSnapshot.docs.length;
    int totalEquipment = 0;
    int availableEquipment = 0;
    double totalRevenue = 0;
    int activeRentals = 0;

    // Calculate equipment stats
    for (var equipDoc in equipmentSnapshot.docs) {
      final equipData = equipDoc.data();
      totalEquipment += (equipData['quantity'] as int? ?? 0);
      availableEquipment += (equipData['availableQuantity'] as int? ?? 0);
    }

    // Calculate rental stats
    for (var rentalDoc in rentalsSnapshot.docs) {
      final rentalData = rentalDoc.data();
      final cost = rentalData['totalCost'];
      if (cost != null) {
        totalRevenue += (cost is int) ? cost.toDouble() : (cost as double? ?? 0.0);
      }
      
      if (rentalData['status'] == 'checked_out' || rentalData['status'] == 'approved') {
        activeRentals++;
      }
    }

    double utilizationRate = totalEquipment > 0 ? ((totalEquipment - availableEquipment) / totalEquipment * 100) : 0;

    return {
      'totalRentals': totalRentals,
      'totalEquipment': totalEquipment,
      'availableEquipment': availableEquipment,
      'utilizationRate': utilizationRate,
      'totalRevenue': totalRevenue,
      'activeRentals': activeRentals,
      'averageRevenuePerRental': totalRentals > 0 ? totalRevenue / totalRentals : 0,
    };
  }

  // Overdue statistics
  Future<Map<String, dynamic>> getOverdueStatistics() async {
    final snapshot = await _firestore.collection('rentals')
        .where('status', isEqualTo: 'checked_out')
        .get();
    
    int overdueCount = 0;
    int totalCheckedOut = snapshot.docs.length;
    double totalLateFees = 0;
    final overdueEquipment = <String, int>{};

    for (var doc in snapshot.docs) {
      try {
        final rental = Rental.fromMap(doc.data());
        if (rental.isOverdue) {
          overdueCount++;
          final lateFee = rental.calculateLateFee(5.0);
          totalLateFees += (lateFee is int) ? lateFee.toDouble() : lateFee;
          
          final equipmentName = rental.equipmentName;
          overdueEquipment[equipmentName] = (overdueEquipment[equipmentName] ?? 0) + 1;
        }
      } catch (e) {
        print('Error processing rental doc: $e');
        continue;
      }
    }

    final overdueRate = totalCheckedOut > 0 ? (overdueCount / totalCheckedOut * 100) : 0;

    return {
      'overdueCount': overdueCount,
      'overdueRate': overdueRate,
      'totalLateFees': totalLateFees,
      'overdueEquipment': overdueEquipment,
    };
  }

  // Maintenance records
  Future<List<Map<String, dynamic>>> getMaintenanceRecords() async {
    final snapshot = await _firestore.collection('rentals')
        .where('status', isEqualTo: 'maintenance')
        .orderBy('updatedAt', descending: true)
        .get();
    
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'equipmentName': data['equipmentName'],
        'equipmentId': data['equipmentId'],
        'userId': data['userId'],
        'userFullName': data['userFullName'],
        'maintenanceDate': data['updatedAt'],
        'adminNotes': data['adminNotes'],
      };
    }).toList();
  }

  // Monthly rental trends
  Future<List<Map<String, dynamic>>> getMonthlyTrends() async {
    final snapshot = await _firestore.collection('rentals').get();
    final monthlyData = <String, int>{};

    for (var doc in snapshot.docs) {
      try {
        final data = doc.data();
        final createdAtStr = data['createdAt'];
        if (createdAtStr != null) {
          final createdAt = DateTime.parse(createdAtStr);
          final monthKey = '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}';
          monthlyData[monthKey] = (monthlyData[monthKey] ?? 0) + 1;
        }
      } catch (e) {
        print('Error processing rental date: $e');
        continue;
      }
    }

    return monthlyData.entries
        .map((e) => {'month': e.key, 'count': e.value})
        .toList()
      ..sort((a, b) => (a['month'] as String).compareTo(b['month'] as String));
  }

  // Equipment efficiency insights
  Future<Map<String, dynamic>> getEfficiencyInsights() async {
    final rentalsSnapshot = await _firestore.collection('rentals').get();
    final equipmentSnapshot = await _firestore.collection('equipment').get();
    
    final equipmentUsage = <String, Map<String, dynamic>>{};
    
    // Initialize equipment data
    for (var equipDoc in equipmentSnapshot.docs) {
      final data = equipDoc.data();
      equipmentUsage[equipDoc.id] = {
        'name': data['name'],
        'totalQuantity': data['quantity'] ?? 0,
        'rentalCount': 0,
        'totalRevenue': 0.0,
        'averageDuration': 0.0,
      };
    }
    
    // Calculate usage stats
    for (var rentalDoc in rentalsSnapshot.docs) {
      final data = rentalDoc.data();
      final equipmentId = data['equipmentId'];
      
      if (equipmentUsage.containsKey(equipmentId)) {
        equipmentUsage[equipmentId]!['rentalCount']++;
        
        final cost = data['totalCost'];
        if (cost != null) {
          final costValue = (cost is int) ? cost.toDouble() : (cost as double? ?? 0.0);
          equipmentUsage[equipmentId]!['totalRevenue'] += costValue;
        }
        
        try {
          final startDateStr = data['startDate'];
          final endDateStr = data['endDate'];
          if (startDateStr != null && endDateStr != null) {
            final startDate = DateTime.parse(startDateStr);
            final endDate = DateTime.parse(endDateStr);
            final duration = endDate.difference(startDate).inDays;
            final currentAvg = equipmentUsage[equipmentId]!['averageDuration'] as double;
            equipmentUsage[equipmentId]!['averageDuration'] = (currentAvg + duration) / 2;
          }
        } catch (e) {
          print('Error parsing rental dates: $e');
        }
      }
    }
    
    // Find insights
    final insights = <String>[];
    final underutilized = <Map<String, dynamic>>[];
    final highPerforming = <Map<String, dynamic>>[];
    
    equipmentUsage.forEach((id, data) {
      final totalQty = data['totalQuantity'] as int? ?? 0;
      final rentalCount = data['rentalCount'] as int? ?? 0;
      final utilizationRate = totalQty > 0 ? (rentalCount / totalQty).toDouble() : 0.0;
      
      if (utilizationRate < 0.3 && rentalCount > 0) {
        underutilized.add({...data, 'id': id, 'utilizationRate': utilizationRate});
      } else if (utilizationRate > 0.8) {
        highPerforming.add({...data, 'id': id, 'utilizationRate': utilizationRate});
      }
    });
    
    if (underutilized.isNotEmpty) {
      insights.add('${underutilized.length} equipment items are underutilized (<30% usage)');
    }
    if (highPerforming.isNotEmpty) {
      insights.add('${highPerforming.length} equipment items have high demand (>80% usage)');
    }
    
    return {
      'insights': insights,
      'underutilized': underutilized,
      'highPerforming': highPerforming,
    };
  }

  // Legacy methods for backward compatibility
  Stream<List<Rental>> getAllRentalsForReports() {
    return _firestore.collection('rentals').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Rental.fromMap(doc.data()))
          .toList();
    });
  }

  Stream<List<Rental>> getCancelledRentals() {
    return _firestore
        .collection('rentals')
        .where('status', isEqualTo: 'cancelled')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Rental.fromMap(doc.data()))
            .toList());
  }

  Stream<List<Rental>> getMaintenanceRentals() {
    return _firestore
        .collection('rentals')
        .where('status', isEqualTo: 'maintenance')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Rental.fromMap(doc.data()))
            .toList());
  }

  Stream<List<Rental>> getCompletedRentals() {
    return _firestore
        .collection('rentals')
        .where('status', whereIn: ['returned', 'cancelled', 'maintenance'])
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Rental.fromMap(doc.data()))
            .toList());
  }

  Future<Map<String, int>> getRentalStatistics() async {
    final snapshot = await _firestore.collection('rentals').get();
    
    final stats = {
      'total': snapshot.docs.length,
      'pending': 0,
      'approved': 0,
      'checked_out': 0,
      'returned': 0,
      'cancelled': 0,
      'maintenance': 0,
      'overdue': 0,
    };

    for (var doc in snapshot.docs) {
      final rental = Rental.fromMap(doc.data());
      stats[rental.status] = (stats[rental.status] ?? 0) + 1;
      
      if (rental.isOverdue) {
        stats['overdue'] = (stats['overdue'] ?? 0) + 1;
      }
    }

    return stats;
  }
}
