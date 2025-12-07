import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ItemsPage extends StatelessWidget {
  final String toolId;
  final String toolName;

  const ItemsPage({super.key, required this.toolId, required this.toolName});

  /// ✅ Generates random serial like: SN-483920
  String _generateRandomSerial() {
    final random = Random();
    final number = 100000 + random.nextInt(900000);
    return "SN-$number";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(toolName)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('equipment')
            .doc(toolId)
            .collection('Items')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!.docs;

          if (items.isEmpty) {
            return const Center(child: Text('لا توجد قطع متاحة'));
          }

          /// ✅ Safe available count
          final availableCount = items.where((item) {
            final data = item.data() as Map<String, dynamic>;
            return data['availability'] == true;
          }).length;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'القطع المتوفرة: $availableCount / ${items.length}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final data = item.data() as Map<String, dynamic>;

                    /// ✅ Safe fields
                    final availability = data['availability'] ?? false;
                    final condition = data['condition']?.toString() ?? 'Unknown';
                    final donor = data['donor']?.toString() ?? 'Unknown';

                    /// ✅ SERIAL FIX (handles int, string, and null)
                    String serial;

                    if (data.containsKey('serial') && data['serial'] != null) {
                      serial = data['serial'].toString(); // ✅ INT -> STRING FIX
                    } else {
                      serial = _generateRandomSerial();

                      /// ✅ Auto save to Firestore
                      item.reference.update({
                        'serial': serial,
                      });
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: ListTile(
                        title: Text("Serial: $serial"),
                        subtitle: Text(
                          "Condition: $condition\nDonor: $donor",
                        ),
                        trailing: availability
                            ? const Icon(Icons.check, color: Colors.green)
                            : const Icon(Icons.close, color: Colors.red),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
