

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../user/reservation_screen.dart';

class EquipmentDetailPage extends StatelessWidget {
  final String equipmentId;

  const EquipmentDetailPage({super.key, required this.equipmentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Equipment Details",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection("equipment")
            .doc(equipmentId)
            .get(),

        builder: (context, equipmentSnapshot) {
          if (equipmentSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!equipmentSnapshot.hasData || !equipmentSnapshot.data!.exists) {
            return const Center(child: Text("Equipment not found"));
          }

          final equipmentData = equipmentSnapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // IMAGE
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.medical_services,
                    size: 70,
                    color: AppColors.primaryBlue,
                  ),
                ),

                const SizedBox(height: 20),

                // EQUIPMENT NAME AND TYPE
                Text(
                  equipmentData['name'] ?? "Unnamed Equipment",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  equipmentData['type'] ?? equipmentData['category'] ?? "Unknown Type",
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.neutralGray,
                  ),
                ),

                const SizedBox(height: 20),

                // EQUIPMENT DESCRIPTION CARD
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Description",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          equipmentData["description"] ?? "No description available.",
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ITEMS LIST SECTION
                const Text(
                  "Available Items",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 12),

                // ITEMS LIST - FETCH FROM SUBCOLLECTION
                _buildItemsList(context, equipmentData),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  // Method to build the items list from the Items subcollection
  Widget _buildItemsList(BuildContext context, Map<String, dynamic> equipmentData) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('equipment')
          .doc(equipmentId)
          .collection('Items')
          .snapshots(),
      builder: (context, itemsSnapshot) {
        if (itemsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!itemsSnapshot.hasData || itemsSnapshot.data!.docs.isEmpty) {
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 50,
                    color: AppColors.neutralGray.withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "No items available",
                    style: TextStyle(
                      color: AppColors.neutralGray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Check back later for available items",
                    style: TextStyle(
                      color: AppColors.neutralGray.withOpacity(0.8),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final items = itemsSnapshot.data!.docs;

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final itemDoc = items[index];
            final itemData = itemDoc.data() as Map<String, dynamic>;
            final isAvailable = itemData['availability'] ?? false;

            return _buildItemCard(
              context,
              equipmentData: equipmentData,
              itemId: itemDoc.id,
              itemData: itemData,
              isAvailable: isAvailable,
            );
          },
        );
      },
    );
  }

  // Build individual item card
  Widget _buildItemCard(
    BuildContext context, {
    required Map<String, dynamic> equipmentData,
    required String itemId,
    required Map<String, dynamic> itemData,
    required bool isAvailable,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER WITH AVAILABILITY BADGE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    itemData['name'] ?? equipmentData['name'] ?? "Unnamed Item",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAvailable 
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    // border: Border.all(
                    //   color: isAvailable ? AppColors.success : AppColors.error,
                    //   width: 1,
                    // ),
                  ),
                  child: Text(
                    isAvailable ? "Available" : "Unavailable",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isAvailable ? AppColors.success : AppColors.error,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ITEM DETAILS
            if (itemData['serial'] != null)
              _itemDetailRow("Serial Number", itemData['serial']!),

            if (itemData['condition'] != null)
              _itemDetailRow("Condition", itemData['condition']!),

            if (itemData['description'] != null && itemData['description']!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    "Item Description:",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.neutralGray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    itemData['description']!,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),

            // ACTION BUTTONS
            const SizedBox(height: 16),

            if (isAvailable) 
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReservationScreen(
                              equipment: {
                                'id': equipmentId,
                                'itemId': itemId,
                                'name': equipmentData['name'] ?? 'Equipment',
                                'itemName': itemData['name'] ?? equipmentData['name'] ?? 'Item',
                                'type': equipmentData['type'] ?? equipmentData['category'] ?? 'Unknown',
                                'serial': itemData['serial'] ?? 'N/A',
                                'condition': itemData['condition'] ?? 'N/A',
                              },
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.handshake, size: 18),
                      label: const Text("Reserve This Item"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.neutralGray.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    "Currently unavailable for reservation",
                    style: TextStyle(
                      color: AppColors.neutralGray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _itemDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              "$label:",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.neutralGray,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}