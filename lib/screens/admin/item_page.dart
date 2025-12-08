import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_edit_item.dart';

class ItemsPage extends StatelessWidget {
  final String toolId;
  final String toolName;

  const ItemsPage({super.key, required this.toolId, required this.toolName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(toolName),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditItemPage(
                    toolId: toolId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
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

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!.docs;

          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('لا توجد قطع متاحة'),
                  SizedBox(height: 8),
                  Text('إضغط على + لإضافة قطع جديدة'),
                ],
              ),
            );
          }

          // 🔴 **هذا هو التصحيح: إزالة المسافة بعد availability**
          final availableCount = items.where((item) {
            final data = item.data() as Map<String, dynamic>;
            return data['availability'] == true; // 🔴 بدون مساحة
          }).length;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              '$availableCount',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const Text('متاحة'),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              '${items.length - availableCount}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const Text('غير متاحة'),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              '${items.length}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const Text('إجمالي'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final data = item.data() as Map<String, dynamic>;

                    final serial = data['serial'] ?? 'N/A';
                    final condition = data['condition'] ?? 'N/A';
                    final donor = data['donor'] ?? 'N/A';
                    final availability = data['availability'] ?? false; // 🔴 بدون مساحة
                    final notes = data['notes'] ?? '';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        title: Text("Serial:$serial"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("الحالة: $condition"),
                            Text("المانح: $donor"),
                            if (notes.isNotEmpty) Text("ملاحظات: $notes"),
                          ],
                        ),
                        leading: availability
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : const Icon(Icons.cancel, color: Colors.red),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'edit') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddEditItemPage(
                                    toolId: toolId,
                                    itemId: item.id,
                                    initialSerial: serial,
                                    initialCondition: condition,
                                    initialDonor: donor,
                                    initialAvailability: availability,
                                    initialNotes: notes,
                                  ),
                                ),
                              );
                            } else if (value == 'delete') {
                              await _showDeleteDialog(context, toolId, item.id, serial);
                            } else if (value == 'toggle_availability') {
                              await FirebaseFirestore.instance
                                  .collection('equipment')
                                  .doc(toolId)
                                  .collection('Items')
                                  .doc(item.id)
                                  .update({
                                'availability': !availability,
                              });
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 20),
                                  SizedBox(width: 8),
                                  Text('تعديل'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'toggle_availability',
                              child: Row(
                                children: [
                                  Icon(
                                    availability ? Icons.block : Icons.check,
                                    size: 20,
                                    color: availability ? Colors.red : Colors.green,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(availability ? 'غير متاح' : 'متاح'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red, size: 20),
                                  SizedBox(width: 8),
                                  Text('حذف', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
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

  Future<void> _showDeleteDialog(
      BuildContext context, String toolId, String itemId, String serial) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف القطعة'),
        content: Text('هل أنت متأكد من حذف القطعة ذات السريال "$serial"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('equipment')
                    .doc(toolId)
                    .collection('Items')
                    .doc(itemId)
                    .delete();

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم حذف القطعة بنجاح')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطأ: $e')),
                  );
                }
              }
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}