import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rental_model.dart';

class ReportsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all rentals for reports (including cancelled and maintenance)
  Stream<List<Rental>> getAllRentalsForReports() {
    return _firestore.collection('rentals').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Rental.fromMap(doc.data()))
          .toList();
    });
  }

  // Get cancelled rentals
  Stream<List<Rental>> getCancelledRentals() {
    return _firestore
        .collection('rentals')
        .where('status', isEqualTo: 'cancelled')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Rental.fromMap(doc.data()))
            .toList());
  }

  // Get maintenance rentals
  Stream<List<Rental>> getMaintenanceRentals() {
    return _firestore
        .collection('rentals')
        .where('status', isEqualTo: 'maintenance')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Rental.fromMap(doc.data()))
            .toList());
  }

  // Get completed rentals (returned, cancelled, maintenance)
  Stream<List<Rental>> getCompletedRentals() {
    return _firestore
        .collection('rentals')
        .where('status', whereIn: ['returned', 'cancelled', 'maintenance'])
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Rental.fromMap(doc.data()))
            .toList());
  }

  // Get rental statistics
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
