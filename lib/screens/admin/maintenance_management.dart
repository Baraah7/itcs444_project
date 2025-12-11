import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/equipment_service.dart';
import '../../services/reservation_service.dart';
import '../../services/notification_service.dart';
import '../../models/equipment_model.dart';
import '../../models/rental_model.dart';
import '../../utils/theme.dart';

class MaintenanceManagementScreen extends StatefulWidget {
  const MaintenanceManagementScreen({super.key});

  @override
  State<MaintenanceManagementScreen> createState() => _MaintenanceManagementScreenState();
}

class _MaintenanceManagementScreenState extends State<MaintenanceManagementScreen> {
  final EquipmentService _equipmentService = EquipmentService();
  final ReservationService _reservationService = ReservationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Maintenance Management'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle),
              onPressed: () async {
                // Test: Mark first equipment as maintenance
                final equip = await _firestore.collection('equipment').limit(1).get();
                if (equip.docs.isNotEmpty) {
                  await equip.docs.first.reference.update({'status': 'maintenance'});
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Test: Marked first equipment for maintenance')),
                    );
                  }
                }
              },
              tooltip: 'Test: Add Maintenance Item',
            ),
            IconButton(
              icon: const Icon(Icons.bug_report),
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => _DebugScreen(),
              )),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.build), text: 'Under Maintenance'),
              Tab(icon: Icon(Icons.inventory), text: 'All Equipment'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildMaintenanceTab(),
            _buildAllEquipmentTab(),
          ],
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
            
            print('🔧 Maintenance Rentals: ${maintenanceRentals.length}');
            print('🔧 Maintenance Equipment: ${maintenanceEquipment.length}');
            
            if (maintenanceRentals.isEmpty && maintenanceEquipment.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.build_circle, size: 80, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    const Text('No items under maintenance', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text('Rentals: ${rentalSnapshot.data?.docs.length ?? 0}, Equipment: ${equipSnapshot.data?.docs.length ?? 0}', 
                      style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              );
            }
            
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (maintenanceEquipment.isNotEmpty) ...[
                  const Text('Equipment Under Maintenance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...maintenanceEquipment.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.purple.withOpacity(0.1),
                          child: const Icon(Icons.build, color: Colors.purple),
                        ),
                        title: Text(data['name'] ?? 'Unknown'),
                        subtitle: Text('${data['type'] ?? 'N/A'} - ${data['condition'] ?? 'N/A'}'),
                        trailing: ElevatedButton(
                          onPressed: () => _markAsAvailable(doc.id, data['name'] ?? 'Equipment'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          child: const Text('Complete'),
                        ),
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
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No equipment found'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final name = data['name'] ?? 'Unknown';
            final status = data['status'] ?? 'available';
            final condition = data['condition'] ?? 'Good';
            final type = data['type'] ?? 'General';
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: status == 'maintenance' ? Colors.purple.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                  child: Icon(
                    status == 'maintenance' ? Icons.build : Icons.inventory,
                    color: status == 'maintenance' ? Colors.purple : Colors.blue,
                  ),
                ),
                title: Text(name),
                subtitle: Text('$type - $condition - Status: $status'),
                trailing: status == 'maintenance'
                    ? Chip(label: const Text('Maintenance'), backgroundColor: Colors.purple.withOpacity(0.2))
                    : IconButton(
                        icon: const Icon(Icons.build, color: Colors.purple),
                        onPressed: () => _markForMaintenance(doc.id, name),
                        tooltip: 'Mark for Maintenance',
                      ),
              ),
            );
          },
        );
      },
    );
  }
}

class _DebugScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug Maintenance')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('rentals').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final allRentals = snapshot.data!.docs;
          final maintenanceRentals = allRentals.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['status'] == 'maintenance';
          }).toList();
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Total Rentals: ${allRentals.length}', style: const TextStyle(fontSize: 18)),
              Text('Maintenance Rentals: ${maintenanceRentals.length}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(height: 24),
              if (maintenanceRentals.isEmpty)
                const Text('No rentals with maintenance status!', style: TextStyle(color: Colors.red, fontSize: 16)),
              ...maintenanceRentals.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return Card(
                  child: ListTile(
                    title: Text(data['equipmentName'] ?? 'Unknown'),
                    subtitle: Text('Status: ${data['status']}\nUser: ${data['userFullName']}\nID: ${doc.id}'),
                  ),
                );
              }),
              const Divider(height: 24),
              const Text('All Rental Statuses:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ...allRentals.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return ListTile(
                  dense: true,
                  title: Text(data['equipmentName'] ?? 'Unknown'),
                  trailing: Chip(label: Text(data['status'] ?? 'unknown')),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
