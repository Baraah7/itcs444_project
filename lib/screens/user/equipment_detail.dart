// //View details + make reservation
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import '../../utils/theme.dart';
// import '../user/reservation_screen.dart';

// class EquipmentDetailPage extends StatelessWidget {
//   final String equipmentId;

//   const EquipmentDetailPage({super.key, required this.equipmentId});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           "Equipment Details",
//           style: TextStyle(fontWeight: FontWeight.w600),
//         ),
//       ),

//       body: FutureBuilder<DocumentSnapshot>(
//         future: FirebaseFirestore.instance
//             .collection("equipment")
//             .doc(equipmentId)
//             .get(),

//         builder: (context, snapshot) {
//           if (!snapshot.hasData) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!snapshot.data!.exists) {
//             return const Center(
//               child: Text("Equipment not found"),
//             );
//           }

//           final data = snapshot.data!.data() as Map<String, dynamic>;

//           // Simple boolean check - true = available, false = not available
//           final bool isAvailable = data['availability'] ?? false;

//           return SingleChildScrollView(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [

//                 // IMAGE WITH AVAILABILITY BADGE
//                 Stack(
//                   children: [
//                     Container(
//                       height: 200,
//                       width: double.infinity,
//                       decoration: BoxDecoration(
//                         color: AppColors.primaryBlue.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       child: const Icon(
//                         Icons.medical_services,
//                         size: 70,
//                         color: Colors.white,
//                       ),
//                     ),
                    
//                     // AVAILABILITY BADGE
//                     Positioned(
//                       top: 12,
//                       right: 12,
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 12,
//                           vertical: 6,
//                         ),
//                         decoration: BoxDecoration(
//                           color: isAvailable 
//                               ? AppColors.success.withOpacity(0.95)
//                               : AppColors.error.withOpacity(0.95),
//                           borderRadius: BorderRadius.circular(20),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.1),
//                               blurRadius: 4,
//                               offset: const Offset(0, 2),
//                             ),
//                           ],
//                         ),
//                         child: Text(
//                           isAvailable ? "Available" : "Not Available",
//                           style: const TextStyle(
//                             fontSize: 12,
//                             color: Colors.white,
//                             fontWeight: FontWeight.w600,
//                             letterSpacing: 0.5,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),

//                 const SizedBox(height: 20),

//                 // NAME
//                 Text(
//                   data['name'] ?? "Unnamed Equipment",
//                   style: const TextStyle(
//                     fontSize: 22,
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),

//                 const SizedBox(height: 6),

//                 // CATEGORY
//                 Text(
//                   data['category'] ?? "Unknown Category",
//                   style: const TextStyle(
//                     fontSize: 15,
//                     color: AppColors.neutralGray,
//                   ),
//                 ),

//                 const SizedBox(height: 20),

//                 // DETAILS CARD
//                 Card(
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   elevation: 2,
//                   child: Padding(
//                     padding: const EdgeInsets.all(16),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [

//                         // VISUAL AVAILABILITY INDICATOR
//                         Row(
//                           children: [
//                             Container(
//                               width: 12,
//                               height: 12,
//                               decoration: BoxDecoration(
//                                 color: isAvailable ? AppColors.success : AppColors.error,
//                                 shape: BoxShape.circle,
//                               ),
//                             ),
//                             const SizedBox(width: 8),
//                             Text(
//                               isAvailable ? "Available for Rent" : "Currently Unavailable",
//                               style: TextStyle(
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.w600,
//                                 color: isAvailable ? AppColors.success : AppColors.error,
//                               ),
//                             ),
//                           ],
//                         ),

//                         const SizedBox(height: 16),

//                         _infoRow("Condition", data["condition"] ?? "Not specified"),
                        
//                         // Quantity row - only show if > 0
//                         if ((data["quantity"] ?? 0) > 0)
//                           _infoRow("Quantity", data["quantity"]?.toString() ?? "0"),

//                         const SizedBox(height: 10),

//                         const Divider(),

//                         const SizedBox(height: 10),

//                         const Text(
//                           "Description",
//                           style: TextStyle(
//                             fontWeight: FontWeight.w600,
//                             fontSize: 16,
//                           ),
//                         ),

//                         const SizedBox(height: 8),

//                         Text(
//                           data["description"] ?? "No description available.",
//                           style: const TextStyle(fontSize: 14),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),

//                 const SizedBox(height: 30),

//                 // ACTION BUTTONS
//                 // Row(
//                 //   children: [
//                 //     Expanded(
//                 //       child: ElevatedButton.icon(
//                 //         onPressed: isAvailable 
//                 //             ? () {
//                 //                 _addToCart(context, data['name']);
//                 //               }
//                 //             : null,
//                 //         icon: const Icon(Icons.add_shopping_cart),
//                 //         label: const Text("Add to Cart"),
//                 //         style: ElevatedButton.styleFrom(
//                 //           backgroundColor: isAvailable 
//                 //               ? AppColors.primaryBlue 
//                 //               : AppColors.neutralGray.withOpacity(0.5),
//                 //           foregroundColor: isAvailable ? Colors.white : Colors.grey[600],
//                 //           padding: const EdgeInsets.symmetric(vertical: 14),
//                 //           shape: RoundedRectangleBorder(
//                 //             borderRadius: BorderRadius.circular(12),
//                 //           ),
//                 //         ),
//                 //       ),
//                 //     ),
//                 //     const SizedBox(width: 12),
//                 //     Expanded(
//                 //       child: ElevatedButton.icon(
//                 //         onPressed: isAvailable 
//                 //             ? () {
//                 //                 _rentNow(context, data['name']);
//                 //               }
//                 //             : null,
//                 //         icon: const Icon(Icons.handshake),
//                 //         label: const Text("Rent Now"),
//                 //         style: ElevatedButton.styleFrom(
//                 //           backgroundColor: isAvailable 
//                 //               ? AppColors.success 
//                 //               : AppColors.neutralGray.withOpacity(0.5),
//                 //           foregroundColor: isAvailable ? Colors.white : Colors.grey[600],
//                 //           padding: const EdgeInsets.symmetric(vertical: 14),
//                 //           shape: RoundedRectangleBorder(
//                 //             borderRadius: BorderRadius.circular(12),
//                 //           ),
//                 //         ),
//                 //       ),
//                 //     ),
//                 //   ],
//                 // ),

//                 //added by Wadeeah
//                 Row(
//   children: [
//     Expanded(
//       child: ElevatedButton.icon(
//         onPressed: isAvailable 
//             ? () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => ReservationScreen(
//                       equipment: {
//                         'id': equipmentId,
//                         'name': data['name'] ?? 'Equipment',
//                         'type': data['category'] ?? 'Unknown',
//                         'rentalPrice': data['rentalPrice'] ?? 0,
//                         // Add other necessary fields
//                       },
//                     ),
//                   ),
//                 );
//               }
//             : null,
//         icon: const Icon(Icons.handshake),
//         label: const Text("Rent Now"),
//         style: ElevatedButton.styleFrom(
//           backgroundColor: isAvailable 
//               ? AppColors.success 
//               : AppColors.neutralGray.withOpacity(0.5),
//           foregroundColor: isAvailable ? Colors.white : Colors.grey[600],
//           padding: const EdgeInsets.symmetric(vertical: 14),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//         ),
//       ),
//     ),
//     const SizedBox(width: 12),
//     Expanded(
//       child: ElevatedButton.icon(
//         onPressed: isAvailable 
//             ? () {
//                 _addToCart(context, data['name']);
//               }
//             : null,
//         icon: const Icon(Icons.add_shopping_cart),
//         label: const Text("Add to Cart"),
//         style: ElevatedButton.styleFrom(
//           backgroundColor: isAvailable 
//               ? AppColors.primaryBlue 
//               : AppColors.neutralGray.withOpacity(0.5),
//           foregroundColor: isAvailable ? Colors.white : Colors.grey[600],
//           padding: const EdgeInsets.symmetric(vertical: 14),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//         ),
//       ),
//     ),
//   ],
// ), 

//                 const SizedBox(height: 30),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _infoRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 10),
//       child: Row(
//         children: [
//           SizedBox(
//             width: 100,
//             child: Text(
//               "$label:",
//               style: const TextStyle(
//                 fontWeight: FontWeight.w600,
//                 color: AppColors.neutralGray,
//               ),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: const TextStyle(fontSize: 14),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _addToCart(BuildContext context, String name) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('$name added to cart'),
//         backgroundColor: AppColors.primaryBlue,
//       ),
//     );
//   }

//   void _rentNow(BuildContext context, String name) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('Rental request sent for $name'),
//         backgroundColor: AppColors.success,
//       ),
//     );
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
                    border: Border.all(
                      color: isAvailable ? AppColors.success : AppColors.error,
                      width: 1,
                    ),
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

            // Check if item has active reservations
            const SizedBox(height: 12),
            _buildReservationStatus(context, itemId),

            // ACTION BUTTONS
            const SizedBox(height: 16),

            if (isAvailable) 
              _buildActionButtons(context, equipmentData, itemId, itemData)
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

  // Build reservation status stream
  Widget _buildReservationStatus(BuildContext context, String itemId) {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('reservations')
        .where('itemId', isEqualTo: itemId)
        .where('status', whereIn: ['confirmed', 'active']) // REMOVED 'pending'
        .snapshots(),
    builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox(); // No active reservations
        }

        final reservations = snapshot.data!.docs;
        final now = DateTime.now();
        
        // Find the soonest upcoming reservation
        Timestamp? nearestEndDate;
        for (final reservation in reservations) {
          final data = reservation.data() as Map<String, dynamic>;
          final endDate = (data['endDate'] as Timestamp).toDate();
          
          if (endDate.isAfter(now)) {
            if (nearestEndDate == null || endDate.isBefore(nearestEndDate.toDate())) {
              nearestEndDate = data['endDate'] as Timestamp;
            }
          }
        }

        if (nearestEndDate == null) {
          return const SizedBox();
        }

        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 14,
                color: AppColors.warning,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Next available: ${DateFormat('MMM dd, yyyy').format(nearestEndDate.toDate())}",
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Build action buttons with availability check
Widget _buildActionButtons(
  BuildContext context,
  Map<String, dynamic> equipmentData,
  String itemId,
  Map<String, dynamic> itemData,
) {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('reservations')
        .where('itemId', isEqualTo: itemId)
        .where('status', whereIn: ['confirmed', 'active']) // REMOVED 'pending'
        .snapshots(),
    builder: (context, reservationSnapshot) {
        bool hasActiveReservations = false;
        String nextAvailableDate = "";
        
        if (reservationSnapshot.hasData) {
          final reservations = reservationSnapshot.data!.docs;
          if (reservations.isNotEmpty) {
            hasActiveReservations = true;
            
            // Calculate next available date
            final now = DateTime.now();
            DateTime? earliestEndDate;
            
            for (final reservation in reservations) {
              final data = reservation.data() as Map<String, dynamic>;
              final endDate = (data['endDate'] as Timestamp).toDate();
              
              if (endDate.isAfter(now)) {
                if (earliestEndDate == null || endDate.isBefore(earliestEndDate)) {
                  earliestEndDate = endDate;
                }
              }
            }
            
            if (earliestEndDate != null) {
              nextAvailableDate = DateFormat('MMM dd, yyyy').format(earliestEndDate);
            }
          }
        }
        
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: hasActiveReservations 
                        ? null 
                        : () {
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
                                    'hasActiveReservations': hasActiveReservations,
                                    'nextAvailableDate': nextAvailableDate,
                                  },
                                ),
                              ),
                            );
                          },
                    icon: const Icon(Icons.handshake, size: 18),
                    label: Text(
                      hasActiveReservations 
                          ? "Currently Reserved" 
                          : "Reserve This Item"
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasActiveReservations 
                          ? AppColors.neutralGray 
                          : AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            if (hasActiveReservations && nextAvailableDate.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  "Next available: $nextAvailableDate",
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.neutralGray,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        );
      },
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

  void _addItemToCart(BuildContext context, String equipmentName, String itemName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $itemName ($equipmentName) to cart'),
        backgroundColor: AppColors.primaryBlue,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}