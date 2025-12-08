import 'package:flutter/material.dart';
import '../../services/equipment_service.dart';
import '../../services/reservation_service.dart';
import '../../models/equipment_model.dart';
import '../../models/rental_model.dart';
import '../../utils/theme.dart';

class MaintenanceManagementScreen extends StatefulWidget {
  const MaintenanceManagementScreen({super.key});

  @override
  State<MaintenanceManagementScreen> createState() => _MaintenanceManagementScreenState();
}

class _MaintenanceManagementScreenState extends State<MaintenanceManagementScreen> {
  final EquipmentService _equipmentService = EquipmentService();
  final ReservationService _reservationService = ReservationService();

  Future<void> _markAsAvailable(String equipmentId, String equipmentName) async {
    try {
      await _equipmentService.markEquipmentAvailable(equipmentId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$equipmentName marked as available'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance Management'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Equipment under maintenance
          Expanded(
            child: StreamBuilder<List<Equipment>>(
              stream: _equipmentService.getMaintenanceEquipment(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final equipment = snapshot.data ?? [];

                if (equipment.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.build_circle, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        const Text(
                          'No equipment under maintenance',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: equipment.length,
                  itemBuilder: (context, index) {
                    final item = equipment[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.purple.withOpacity(0.1),
                          child: const Icon(Icons.build, color: Colors.purple),
                        ),
                        title: Text(item.name),
                        subtitle: Text('${item.type} - ${item.category}'),
                        trailing: ElevatedButton.icon(
                          onPressed: () => _markAsAvailable(item.id, item.name),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Mark Available'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // Rentals under maintenance
          Expanded(
            child: StreamBuilder<List<Rental>>(
              stream: _reservationService.getAllRentals(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final rentals = (snapshot.data ?? [])
                    .where((r) => r.status == 'maintenance')
                    .toList();

                if (rentals.isEmpty) {
                  return const Center(
                    child: Text('No rentals under maintenance'),
                  );
                }

                return Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Rentals Under Maintenance',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: rentals.length,
                        itemBuilder: (context, index) {
                          final rental = rentals[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: const Icon(Icons.build, color: Colors.purple),
                              title: Text(rental.equipmentName),
                              subtitle: Text('User: ${rental.userFullName}'),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
