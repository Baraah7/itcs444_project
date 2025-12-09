import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SimpleMaintenanceScreen extends StatelessWidget {
  const SimpleMaintenanceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance Management'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('equipment').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allEquipment = snapshot.data!.docs;
          final maintenanceEquipment = allEquipment.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['status'] == 'maintenance';
          }).toList();

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.purple.withOpacity(0.1),
                child: Column(
                  children: [
                    Text('Total Equipment: ${allEquipment.length}', style: const TextStyle(fontSize: 18)),
                    Text('Under Maintenance: ${maintenanceEquipment.length}', 
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple)),
                  ],
                ),
              ),
              Expanded(
                child: maintenanceEquipment.isEmpty
                    ? const Center(child: Text('No equipment under maintenance'))
                    : ListView.builder(
                        itemCount: maintenanceEquipment.length,
                        itemBuilder: (context, index) {
                          final doc = maintenanceEquipment[index];
                          final data = doc.data() as Map<String, dynamic>;
                          return Card(
                            margin: const EdgeInsets.all(8),
                            child: ListTile(
                              leading: const Icon(Icons.build, color: Colors.purple),
                              title: Text(data['name'] ?? 'Unknown'),
                              subtitle: Text('Status: ${data['status']}'),
                              trailing: ElevatedButton(
                                onPressed: () async {
                                  await doc.reference.update({'status': 'available', 'availability': true});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Marked as available')),
                                  );
                                },
                                child: const Text('Complete'),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () async {
                    if (allEquipment.isNotEmpty) {
                      await allEquipment.first.reference.update({'status': 'maintenance', 'availability': false});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Marked first equipment for maintenance')),
                      );
                    }
                  },
                  child: const Text('TEST: Mark First Equipment for Maintenance'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
