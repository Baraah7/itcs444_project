

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

                const SizedBox(height: 12),

                // AVAILABILITY STATUS
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('equipment')
                      .doc(equipmentId)
                      .collection('Items')
                      .where('availability', isEqualTo: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final isAvailable = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isAvailable ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isAvailable ? Icons.check_circle : Icons.cancel,
                            size: 16,
                            color: isAvailable ? AppColors.success : AppColors.error,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isAvailable ? "Available" : "Unavailable",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isAvailable ? AppColors.success : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // EQUIPMENT DESCRIPTION CARD
                SizedBox(
                  width: double.infinity,
                  child: Card(
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
                ),

                const SizedBox(height: 24),

                // RESERVE BUTTON
                _buildReserveButton(context, equipmentData),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReserveButton(BuildContext context, Map<String, dynamic> equipmentData) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReservationScreen(
                equipment: {
                  'id': equipmentId,
                  'name': equipmentData['name'] ?? 'Equipment',
                  'type': equipmentData['type'] ?? equipmentData['category'] ?? 'Unknown',
                  'rentalPrice': equipmentData['rentalPrice'] ?? 0,
                },
              ),
            ),
          );
        },
        icon: const Icon(Icons.handshake, size: 20),
        label: const Text("Reserve"),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}