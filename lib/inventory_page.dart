import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:itcs444_project/models/equipment_model.dart';
import 'package:itcs444_project/services/equipment_service.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final EquipmentService _equipmentService = EquipmentService();
  String _searchQuery = "";
  String _filterStatus = "All";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inventory Management"),
        actions: [
          SizedBox(
            width: 250,
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Search...",
                border: InputBorder.none,
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => _filterStatus = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: "All", child: Text("All")),
              const PopupMenuItem(value: "available", child: Text("Available")),
              const PopupMenuItem(value: "rented", child: Text("Rented")),
              const PopupMenuItem(value: "maintenance", child: Text("Maintenance")),
            ],
            icon: const Icon(Icons.filter_alt),
          ),
        ],
      ),
      body: StreamBuilder<List<Equipment>>(
        stream: _equipmentService.getEquipmentByStatus(_filterStatus),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No equipment found.'));
          }

          final filteredItems = snapshot.data!.where((item) {
            return item.name.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

          return LayoutBuilder(
            builder: (context, constraints) {
              bool isWide = constraints.maxWidth > 700;
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWide ? 3 : 1,
                  childAspectRatio: 2.8,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  final item = filteredItems[index];
                  return Card(
                    child: Row(
                      children: [
                        // Item image
                        Container(
                          width: 90,
                          height: 90,
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[200],
                            image: item.imageUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(item.imageUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: item.imageUrl == null
                              ? const Icon(Icons.image, size: 40, color: Colors.grey)
                              : null,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Text("Type: ${item.type}"),
                                Text("Status: ${item.status}"),
                                Text("Quantity: ${item.quantity}"),
                              ],
                            ),
                          ),
                        ),
                        Column(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _openEquipmentForm(item: item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.more_vert),
                              onPressed: () => _showItemActions(context, item),
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
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEquipmentForm(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showItemActions(BuildContext context, Equipment equipment) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('Set as Available'),
              onTap: () {
                Navigator.pop(context);
                _equipmentService.markEquipmentAvailable(equipment.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.build_circle_outlined),
              title: const Text('Set as Under Maintenance'),
              onTap: () {
                Navigator.pop(context);
                _equipmentService.updateEquipmentStatus(equipment.id, false, 'maintenance');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                // _equipmentService.deleteEquipment(equipment.id);
              },
            ),
          ],
        );
      },
    );
  }

  void _openEquipmentForm({Equipment? item}) {
    // Navigate to equipment form or show dialog
    // Implementation depends on your form structure
  }

  // ======================================================
  // INPUT FIELD WIDGET
  // ======================================================
  Widget _field(TextEditingController c, String label,
      {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: c,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }
}