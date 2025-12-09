import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DebugMaintenanceScreen extends StatelessWidget {
  const DebugMaintenanceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug Maintenance')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('RENTALS WITH MAINTENANCE STATUS:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('rentals').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              
              final allRentals = snapshot.data!.docs;
              final maintenanceRentals = allRentals.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['status'] == 'maintenance';
              }).toList();
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Rentals: ${allRentals.length}'),
                  Text('Maintenance Rentals: ${maintenanceRentals.length}'),
                  const SizedBox(height: 8),
                  if (maintenanceRentals.isEmpty)
                    const Text('No rentals with maintenance status found!', style: TextStyle(color: Colors.red)),
                  ...maintenanceRentals.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return Card(
                      child: ListTile(
                        title: Text(data['equipmentName'] ?? 'Unknown'),
                        subtitle: Text('Status: ${data['status']}\nUser: ${data['userFullName']}'),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
          const Divider(height: 32),
          const Text('EQUIPMENT WITH MAINTENANCE STATUS:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('equipment').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              
              final allEquipment = snapshot.data!.docs;
              final maintenanceEquipment = allEquipment.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['status'] == 'maintenance';
              }).toList();
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Equipment: ${allEquipment.length}'),
                  Text('Maintenance Equipment: ${maintenanceEquipment.length}'),
                  const SizedBox(height: 8),
                  if (maintenanceEquipment.isEmpty)
                    const Text('No equipment with maintenance status found!', style: TextStyle(color: Colors.red)),
                  ...maintenanceEquipment.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return Card(
                      child: ListTile(
                        title: Text(data['name'] ?? 'Unknown'),
                        subtitle: Text('Status: ${data['status']}\nType: ${data['type']}'),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
          const Divider(height: 32),
          const Text('ALL RENTAL STATUSES:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('rentals').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              
              final statusCounts = <String, int>{};
              for (var doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final status = data['status'] ?? 'unknown';
                statusCounts[status] = (statusCounts[status] ?? 0) + 1;
              }
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: statusCounts.entries.map((e) => 
                  Text('${e.key}: ${e.value}')
                ).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
