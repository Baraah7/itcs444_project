//View details + make reservation
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../utils/theme.dart';

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

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.data!.exists) {
            return const Center(
              child: Text("Equipment not found"),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          // Simple boolean check - true = available, false = not available
          final bool isAvailable = data['availability'] ?? false;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // IMAGE WITH AVAILABILITY BADGE
                Stack(
                  children: [
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
                        color: Colors.white,
                      ),
                    ),
                    
                    // AVAILABILITY BADGE
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isAvailable 
                              ? AppColors.success.withOpacity(0.95)
                              : AppColors.error.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          isAvailable ? "Available" : "Not Available",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // NAME
                Text(
                  data['name'] ?? "Unnamed Equipment",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 6),

                // CATEGORY
                Text(
                  data['category'] ?? "Unknown Category",
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.neutralGray,
                  ),
                ),

                const SizedBox(height: 20),

                // DETAILS CARD
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

                        // VISUAL AVAILABILITY INDICATOR
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: isAvailable ? AppColors.success : AppColors.error,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isAvailable ? "Available for Rent" : "Currently Unavailable",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isAvailable ? AppColors.success : AppColors.error,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        _infoRow("Condition", data["condition"] ?? "Not specified"),
                        
                        // Quantity row - only show if > 0
                        if ((data["quantity"] ?? 0) > 0)
                          _infoRow("Quantity", data["quantity"]?.toString() ?? "0"),

                        const SizedBox(height: 10),

                        const Divider(),

                        const SizedBox(height: 10),

                        const Text(
                          "Description",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          data["description"] ?? "No description available.",
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // ACTION BUTTONS
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isAvailable 
                            ? () {
                                _addToCart(context, data['name']);
                              }
                            : null,
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text("Add to Cart"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isAvailable 
                              ? AppColors.primaryBlue 
                              : AppColors.neutralGray.withOpacity(0.5),
                          foregroundColor: isAvailable ? Colors.white : Colors.grey[600],
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isAvailable 
                            ? () {
                                _rentNow(context, data['name']);
                              }
                            : null,
                        icon: const Icon(Icons.handshake),
                        label: const Text("Rent Now"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isAvailable 
                              ? AppColors.success 
                              : AppColors.neutralGray.withOpacity(0.5),
                          foregroundColor: isAvailable ? Colors.white : Colors.grey[600],
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              "$label:",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.neutralGray,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _addToCart(BuildContext context, String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name added to cart'),
        backgroundColor: AppColors.primaryBlue,
      ),
    );
  }

  void _rentNow(BuildContext context, String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Rental request sent for $name'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}