import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class ItemsPage extends StatelessWidget {
  final String toolId;
  final String toolName;

  const ItemsPage({super.key, required this.toolId, required this.toolName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(toolName)),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('equipment')
            .doc(toolId)
            .collection('items')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final items = snapshot.data!.docs;

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                margin: EdgeInsets.all(8),
                child: ListTile(
                  title: Text("Serial: ${item['serial']}"),
                  subtitle: Text("Condition: ${item['condition']} \nDonor: ${item['donor']}"),
                  trailing: item['isAvailable']
                      ? Icon(Icons.check, color: Colors.green)
                      : Icon(Icons.close, color: Colors.red),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
