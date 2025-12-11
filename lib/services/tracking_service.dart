import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rental_model.dart';

class TrackingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Rental>> trackUserRentals(String userId) {
    return _firestore
        .collection('rentals')
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: ['approved', 'checked_out'])
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Rental.fromMap(doc.data())).toList());
  }

  Stream<List<Rental>> trackAllActiveRentals() {
    return _firestore
        .collection('rentals')
        .where('status', whereIn: ['approved', 'checked_out'])
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Rental.fromMap(doc.data())).toList());
  }

  Future<List<Rental>> getUserRentalHistory(String userId) async {
    final snapshot = await _firestore
        .collection('rentals')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    
    return snapshot.docs.map((doc) => Rental.fromMap(doc.data())).toList();
  }

  Future<List<Rental>> getAllRentalHistory() async {
    final snapshot = await _firestore
        .collection('rentals')
        .orderBy('createdAt', descending: true)
        .get();
    
    return snapshot.docs.map((doc) => Rental.fromMap(doc.data())).toList();
  }

  Future<Map<String, dynamic>> getRentalStats(String userId) async {
    final rentals = await getUserRentalHistory(userId);
    
    return {
      'total': rentals.length,
      'active': rentals.where((r) => r.status == 'checked_out').length,
      'completed': rentals.where((r) => r.status == 'returned').length,
      'overdue': rentals.where((r) => r.isOverdue).length,
    };
  }
}
