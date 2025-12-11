import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/equipment_model.dart';

class EquipmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Update equipment status when rental status changes
  Future<void> syncEquipmentWithRental({
    required String equipmentId,
    required String rentalStatus,
    required int quantity,
  }) async {
    final equipmentRef = _firestore.collection('equipment').doc(equipmentId);
    final equipmentDoc = await equipmentRef.get();
    
    if (!equipmentDoc.exists) return;
    
    final data = equipmentDoc.data() as Map<String, dynamic>;
    final currentAvailable = (data['availableQuantity'] ?? 0) as int;
    final totalQuantity = (data['quantity'] ?? 1) as int;
    
    Map<String, dynamic> updates = {'updatedAt': FieldValue.serverTimestamp()};
    
    switch (rentalStatus) {
      case 'pending':
        // Don't change anything on pending - wait for approval
        break;
        
      case 'approved':
      case 'checked_out':
        // Reserve items only when approved
        updates['availableQuantity'] = (currentAvailable - quantity).clamp(0, totalQuantity);
        updates['status'] = updates['availableQuantity'] == 0 ? 'rented' : 'available';
        updates['availability'] = updates['availableQuantity'] > 0;
        await _updateItemsAvailability(equipmentId, quantity, false);
        break;
        
      case 'returned':
        // Don't release items yet - wait for admin to mark available
        break;
        
      case 'cancelled':
        // Release items immediately on cancel
        updates['availableQuantity'] = (currentAvailable + quantity).clamp(0, totalQuantity);
        updates['status'] = 'available';
        updates['availability'] = true;
        await _updateItemsAvailability(equipmentId, quantity, true);
        break;
        
      case 'maintenance':
        // Mark equipment as under maintenance
        updates['status'] = 'maintenance';
        updates['availability'] = false;
        await _updateAllItemsStatus(equipmentId, 'maintenance', false);
        break;
    }
    
    await equipmentRef.update(updates);
  }

  // Update individual items in subcollection (batch for speed)
  Future<void> _updateItemsAvailability(String equipmentId, int quantity, bool available) async {
    final itemsRef = _firestore.collection('equipment').doc(equipmentId).collection('Items');
    final items = await itemsRef.where('availability', isEqualTo: !available).get();
    
    if (items.docs.isEmpty) return;
    
    final batch = _firestore.batch();
    int count = 0;
    for (var item in items.docs) {
      if (count >= quantity) break;
      batch.update(item.reference, {'availability': available});
      count++;
    }
    await batch.commit();
  }

  // Update all items status (batch for speed)
  Future<void> _updateAllItemsStatus(String equipmentId, String status, bool available) async {
    final itemsRef = _firestore.collection('equipment').doc(equipmentId).collection('Items');
    final items = await itemsRef.get();
    
    if (items.docs.isEmpty) return;
    
    final batch = _firestore.batch();
    for (var item in items.docs) {
      batch.update(item.reference, {
        'status': status,
        'availability': available,
      });
    }
    await batch.commit();
  }

  // Mark equipment as available (from maintenance or returned)
  Future<void> markEquipmentAvailable(String equipmentId) async {
    print('Executing markEquipmentAvailable for equipmentId: $equipmentId');
    await _firestore.collection('equipment').doc(equipmentId).update({
      'status': 'available',
      'availability': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    print('Equipment $equipmentId status updated to available.');
    
    // Update all items to available
    await _updateAllItemsStatus(equipmentId, 'available', true);
    print('Sub-items for $equipmentId updated.');

    // Update related rentals to 'available'
    final rentalsQuery = _firestore
        .collection('rentals')
        .where('equipmentId', isEqualTo: equipmentId)
        .where('status', whereIn: ['pending', 'approved', 'checked_out', 'active', 'returned', 'completed']);
    
    final rentals = await rentalsQuery.get();
    print('Found ${rentals.docs.length} related rentals to update.');

    if (rentals.docs.isEmpty) {
      print('No active or completed rentals found for equipment $equipmentId. Nothing to update.');
      return;
    }

    final batch = _firestore.batch();
    for (final doc in rentals.docs) {
      print('Updating rental ${doc.id} to status: available');
      batch.update(doc.reference, {'status': 'available'});
    }
    await batch.commit();
    print('Batch commit successful for related rentals.');
  }

  // Get equipment by status
  Stream<List<Equipment>> getEquipmentByStatus(String status) {
    Query query = _firestore.collection('equipment');
    if (status != 'All') {
      query = query.where('status', isEqualTo: status.toLowerCase());
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Equipment.fromFirestore(doc)).toList();
    });
  }

  // Get all equipment under maintenance
  Stream<List<Equipment>> getMaintenanceEquipment() {
    return getEquipmentByStatus('maintenance');
  }

  // Check if requested quantity is available (from Items subcollection)
  Future<int> getAvailableQuantity(String equipmentId) async {
    final itemsSnapshot = await _firestore
        .collection('equipment')
        .doc(equipmentId)
        .collection('Items')
        .where('availability', isEqualTo: true)
        .get();
    
    return itemsSnapshot.docs.length;
  }

  Future<void> updateEquipmentStatus(String id, bool isAvailable, String status) async {
    await _firestore.collection('equipment').doc(id).update({
      'availability': isAvailable,
      'status': status,
    });

    if (status == 'maintenance') {
      final rentals = await _firestore
          .collection('rentals')
          .where('equipmentId', isEqualTo: id)
          .where('status', whereIn: ['pending', 'approved', 'checked_out', 'active', 'returned', 'completed'])
          .get();

      final batch = _firestore.batch();
      for (final doc in rentals.docs) {
        batch.update(doc.reference, {'status': 'maintenance'});
      }
      await batch.commit();
    }
  }
  
}
