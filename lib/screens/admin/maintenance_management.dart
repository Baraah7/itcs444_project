import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/equipment_service.dart';
import '../../services/reservation_service.dart';
import '../../services/notification_service.dart';
import '../../models/equipment_model.dart';

class MaintenanceManagementScreen extends StatefulWidget {
  const MaintenanceManagementScreen({super.key});

  @override
  State<MaintenanceManagementScreen> createState() => _MaintenanceManagementScreenState();
}

class _MaintenanceManagementScreenState extends State<MaintenanceManagementScreen> {
  final EquipmentService _equipmentService = EquipmentService();
  final ReservationService _reservationService = ReservationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedView = 'maintenance'; // 'maintenance' or 'all'

  Future<void> _markAsAvailable(String equipmentId, String equipmentName) async {
    final notes = await _showNotesDialog('Complete Maintenance', 'Add completion notes (optional)');
    if (notes == null) return;

    try {
      // Get current admin's email
      final currentUser = FirebaseAuth.instance.currentUser;
      final adminEmail = currentUser?.email ?? 'An admin';

      await _equipmentService.markEquipmentAvailable(equipmentId);
      await _addMaintenanceLog(equipmentId, 'completed', notes);

      // Notify other admins (excluding the current admin)
      await createAdminNotification(
        title: 'Maintenance Completed',
        message: '$adminEmail completed maintenance for "$equipmentName". ${notes.isNotEmpty ? "Notes: $notes" : ""}',
        type: 'maintenance',
        excludeAdminId: currentUser?.uid, // Exclude current admin from receiving notification
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$equipmentName marked as available'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addMaintenanceLog(String equipmentId, String action, String notes) async {
    await _firestore.collection('maintenance_logs').add({
      'equipmentId': equipmentId,
      'action': action,
      'notes': notes,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<String?> _showNotesDialog(String title, String hint) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: hint),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteEquipmentDialog(String equipmentId, String equipmentName) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Equipment'),
          ],
        ),
        content: Text('Are you sure you want to delete "$equipmentName"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _firestore.collection('equipment').doc(equipmentId).delete();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$equipmentName deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting equipment: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showMaintenanceDetails(Equipment equipment) async {
    final logs = await _firestore
        .collection('maintenance_logs')
        .where('equipmentId', isEqualTo: equipment.id)
        .orderBy('timestamp', descending: true)
        .limit(10)
        .get();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.build_circle, size: 32, color: Colors.purple),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(equipment.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('${equipment.type} - ${equipment.category}', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              const Text('Maintenance History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Expanded(
                child: logs.docs.isEmpty
                    ? const Center(child: Text('No maintenance history'))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: logs.docs.length,
                        itemBuilder: (context, index) {
                          final log = logs.docs[index].data();
                          final timestamp = (log['timestamp'] as Timestamp?)?.toDate();
                          return Card(
                            child: ListTile(
                              leading: Icon(
                                log['action'] == 'completed' ? Icons.check_circle : Icons.build,
                                color: log['action'] == 'completed' ? Colors.green : Colors.orange,
                              ),
                              title: Text(log['action'].toString().toUpperCase()),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (log['notes']?.toString().isNotEmpty ?? false)
                                    Text(log['notes']),
                                  if (timestamp != null)
                                    Text(
                                      DateFormat('MMM dd, yyyy - hh:mm a').format(timestamp),
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _markForMaintenance(String equipmentId, String equipmentName) async {
    final notes = await _showNotesDialog('Mark for Maintenance', 'Enter maintenance reason');
    if (notes == null) return;

    try {
      // Get current admin's email
      final currentUser = FirebaseAuth.instance.currentUser;
      final adminEmail = currentUser?.email ?? 'An admin';

      await _firestore.collection('equipment').doc(equipmentId).update({
        'status': 'maintenance',
        'availability': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _addMaintenanceLog(equipmentId, 'started', notes);

      // Notify other admins (excluding the current admin)
      await createAdminNotification(
        title: 'Equipment Under Maintenance',
        message: '$adminEmail marked "$equipmentName" for maintenance. Reason: $notes',
        type: 'maintenance',
        excludeAdminId: currentUser?.uid, // Exclude current admin from receiving notification
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$equipmentName marked for maintenance'), backgroundColor: Colors.purple),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2B6C67),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Maintenance Management',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildViewSelector(),
          Expanded(
            child: _selectedView == 'maintenance'
                ? _buildMaintenanceTab()
                : _buildAllEquipmentTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildViewSelector() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _viewSelectorButton('Under Maintenance', _selectedView == 'maintenance'),
          const SizedBox(width: 12),
          _viewSelectorButton('All Equipment', _selectedView == 'all'),
        ],
      ),
    );
  }

  Widget _viewSelectorButton(String label, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedView = label == 'Under Maintenance' ? 'maintenance' : 'all';
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color.fromARGB(255, 222, 235, 234) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF2B6C67) : const Color(0xFFE8ECEF),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                label == 'Under Maintenance' ? Icons.build_circle_outlined : Icons.inventory_2_outlined,
                size: 18,
                color: isSelected ? const Color(0xFF2B6C67) : const Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF2B6C67) : const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMaintenanceTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('rentals').snapshots(),
      builder: (context, rentalSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('equipment').snapshots(),
          builder: (context, equipSnapshot) {
            if (rentalSnapshot.connectionState == ConnectionState.waiting || 
                equipSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (rentalSnapshot.hasError) {
              return Center(child: Text('Rental Error: ${rentalSnapshot.error}'));
            }
            if (equipSnapshot.hasError) {
              return Center(child: Text('Equipment Error: ${equipSnapshot.error}'));
            }
            
            final maintenanceRentals = rentalSnapshot.data?.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['status'] == 'maintenance';
            }).toList() ?? [];
            
            final maintenanceEquipment = equipSnapshot.data?.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['status'] == 'maintenance';
            }).toList() ?? [];
            
            if (maintenanceRentals.isEmpty && maintenanceEquipment.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.build_circle_outlined, size: 80, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    const Text(
                      'No items under maintenance',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'All equipment is currently available',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }
            
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (maintenanceEquipment.isNotEmpty) ...[
                  const Text(
                    'Equipment Under Maintenance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...maintenanceEquipment.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE8ECEF)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1E293B).withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF8B5CF6).withOpacity(0.1),
                                      const Color(0xFF7C3AED).withOpacity(0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.build_circle_outlined,
                                  color: Color(0xFF8B5CF6),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['name'] ?? 'Unknown',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${data['type'] ?? 'N/A'} • ${data['condition'] ?? 'N/A'}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B5CF6).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
                                ),
                                child: const Text(
                                  'MAINTENANCE',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF8B5CF6),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _markAsAvailable(doc.id, data['name'] ?? 'Equipment'),
                                  icon: const Icon(Icons.check_circle_outline, size: 18),
                                  label: const Text('Mark Complete'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFFEF4444)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  onPressed: () => _showDeleteEquipmentDialog(doc.id, data['name'] ?? 'Equipment'),
                                  icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                                  tooltip: 'Delete Equipment',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                ],
                if (maintenanceRentals.isNotEmpty) ...[
                  const Text('Rentals Under Maintenance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...maintenanceRentals.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFE1BEE7),
                          child: Icon(Icons.build, color: Colors.purple),
                        ),
                        title: Text(data['equipmentName'] ?? 'Unknown'),
                        subtitle: Text('User: ${data['userFullName'] ?? 'Unknown'}\nRental ID: ${doc.id}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.check_circle, color: Colors.green),
                          onPressed: () async {
                            await _firestore.collection('rentals').doc(doc.id).update({'status': 'returned'});
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Rental marked as returned')),
                              );
                            }
                          },
                        ),
                      ),
                    );
                  }),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildAllEquipmentTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('equipment').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF2B6C67)),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Color(0xFFEF4444)),
                const SizedBox(height: 16),
                const Text(
                  'Error loading equipment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 80, color: Color(0xFFE8ECEF)),
                SizedBox(height: 16),
                Text(
                  'No equipment found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final name = data['name'] ?? 'Unknown';
            final status = data['status'] ?? 'available';
            final condition = data['condition'] ?? 'Good';
            final type = data['type'] ?? 'General';
            
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8ECEF)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E293B).withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              (status == 'maintenance' ? const Color(0xFF8B5CF6) : const Color(0xFF3B82F6)).withOpacity(0.1),
                              (status == 'maintenance' ? const Color(0xFF7C3AED) : const Color(0xFF1D4ED8)).withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          status == 'maintenance' ? Icons.build_circle_outlined : Icons.inventory_2_outlined,
                          color: status == 'maintenance' ? const Color(0xFF8B5CF6) : const Color(0xFF3B82F6),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$type • $condition',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              (status == 'maintenance' ? const Color(0xFF8B5CF6) : const Color(0xFF10B981)).withOpacity(0.1),
                              (status == 'maintenance' ? const Color(0xFF8B5CF6) : const Color(0xFF10B981)).withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: (status == 'maintenance' ? const Color(0xFF8B5CF6) : const Color(0xFF10B981)).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: status == 'maintenance' ? const Color(0xFF8B5CF6) : const Color(0xFF10B981),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (status != 'maintenance')
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _markForMaintenance(doc.id, name),
                            icon: const Icon(Icons.build_outlined, size: 18),
                            label: const Text('Mark for Maintenance'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B5CF6),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.build_circle_outlined, size: 18, color: Color(0xFF8B5CF6)),
                                SizedBox(width: 8),
                                Text(
                                  'Under Maintenance',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF8B5CF6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFEF4444)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () => _showDeleteEquipmentDialog(doc.id, name),
                          icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                          tooltip: 'Delete Equipment',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

