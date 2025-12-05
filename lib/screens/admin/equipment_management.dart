//Add/edit/delete equipment


import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'item_page.dart';

class Equipment {
  final String id;
  final String name;
  final String description;

  Equipment({required this.id, required this.name, required this.description});

  factory Equipment.fromDoc(doc) {
    return Equipment(
      id: doc.id,
      name: doc['name'] ?? '',
      description: doc['description'] ?? '',
    );
  }
}

class EquipmentPage extends StatelessWidget {
  const EquipmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("المعدات المتوفرة")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('equipment').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final tools = snapshot.data!.docs;

          return ListView.builder(
            itemCount: tools.length,
            itemBuilder: (context, index) {
              final tool = tools[index];
              final toolId = tool.id;

              return Card(
                margin: EdgeInsets.all(8),
                child: ListTile(
                  title: Text(tool['name']),
                  subtitle: Text(tool['description']),
                  trailing: FutureBuilder(
                    future: FirebaseFirestore.instance
                        .collection('equipment')
                        .doc(toolId)
                        .collection('items')
                        .get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return Text("...");
                      final items = snapshot.data!.docs;
                      final availableCount =
                          items.where((item) => item['isAvailable'] == true).length;
                      return Text("$availableCount / ${items.length} متوفر");
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ItemsPage(toolId: toolId, toolName: tool['name']),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
