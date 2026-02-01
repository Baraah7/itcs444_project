import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF2B6C67),
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection("equipment")
            .doc(equipmentId)
            .get(),

        builder: (context, equipmentSnapshot) {
          if (equipmentSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF2B6C67)));
          }

          if (!equipmentSnapshot.hasData || !equipmentSnapshot.data!.exists) {
            return const Center(
              child: Text(
                "Equipment not found",
                style: TextStyle(
                  color: Color(0xFF475569),
                ),
              ),
            );
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
                    color: const Color(0xFFF0F9F8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE8ECEF)),
                  ),
                  child: const Icon(
                    Icons.medical_services,
                    size: 70,
                    color: Color(0xFF2B6C67),
                  ),
                ),

                const SizedBox(height: 20),

                // EQUIPMENT NAME AND TYPE
                Text(
                  equipmentData['name'] ?? "Unnamed Equipment",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  equipmentData['type'] ?? equipmentData['category'] ?? "Unknown Type",
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF64748B),
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
                        color: isAvailable 
                          ? const Color(0xFF10B981).withOpacity(0.1) 
                          : const Color(0xFFEF4444).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isAvailable 
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isAvailable ? Icons.check_circle : Icons.cancel,
                            size: 16,
                            color: isAvailable 
                              ? const Color(0xFF10B981) 
                              : const Color(0xFFEF4444),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isAvailable ? "Available" : "Unavailable",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isAvailable 
                                ? const Color(0xFF10B981) 
                                : const Color(0xFFEF4444),
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
                      side: const BorderSide(color: Color(0xFFF1F5F9)),
                    ),
                    elevation: 0,
                    color: Colors.white,
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
                              color: Color(0xFF1E293B),
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            equipmentData["description"] ?? "No description available.",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF475569),
                            ),
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
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('equipment')
          .doc(equipmentId)
          .collection('Items')
          .where('availability', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        final isAvailable = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
        
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isAvailable
                ? () {
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
                  }
                : () {
                    // Show snackbar notification when equipment is unavailable
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.white, size: 20),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text('This equipment is currently unavailable'),
                            ),
                          ],
                        ),
                        backgroundColor: const Color(0xFFEF4444),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  },
            icon: Icon(
              Icons.handshake, 
              size: 20, 
              color: isAvailable ? Colors.white : const Color(0xFFCBD5E1),
            ),
            label: Text(
              isAvailable ? "Reserve" : "Unavailable",
              style: TextStyle(
                color: isAvailable ? Colors.white : const Color(0xFFCBD5E1),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isAvailable
                  ? const Color(0xFF2B6C67)
                  : const Color(0xFF94A3B8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      },
    );
  }
}