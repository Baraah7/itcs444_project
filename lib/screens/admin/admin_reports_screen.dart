import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/reports_service.dart';
import '../../models/rental_model.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final ReportsService _reportsService = ReportsService();
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          PopupMenuButton<String>(
            initialValue: _selectedFilter,
            onSelected: (value) => setState(() => _selectedFilter = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Rentals')),
              const PopupMenuItem(value: 'completed', child: Text('Completed')),
              const PopupMenuItem(value: 'cancelled', child: Text('Cancelled')),
              const PopupMenuItem(value: 'maintenance', child: Text('Maintenance')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Card
          FutureBuilder<Map<String, int>>(
            future: _reportsService.getRentalStatistics(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              
              final stats = snapshot.data!;
              return Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Statistics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _statChip('Total', stats['total'].toString(), Colors.blue),
                          _statChip('Returned', stats['returned'].toString(), Colors.green),
                          _statChip('Cancelled', stats['cancelled'].toString(), Colors.red),
                          _statChip('Maintenance', stats['maintenance'].toString(), Colors.purple),
                          _statChip('Overdue', stats['overdue'].toString(), Colors.orange),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          // Rentals List
          Expanded(
            child: StreamBuilder<List<Rental>>(
              stream: _getFilteredStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final rentals = snapshot.data ?? [];
                if (rentals.isEmpty) {
                  return Center(child: Text('No ${_selectedFilter} rentals'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: rentals.length,
                  itemBuilder: (context, index) => _buildRentalCard(rentals[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<List<Rental>> _getFilteredStream() {
    switch (_selectedFilter) {
      case 'completed':
        return _reportsService.getCompletedRentals();
      case 'cancelled':
        return _reportsService.getCancelledRentals();
      case 'maintenance':
        return _reportsService.getMaintenanceRentals();
      default:
        return _reportsService.getAllRentalsForReports();
    }
  }

  Widget _statChip(String label, String value, Color color) {
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildRentalCard(Rental rental) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(rental.statusIcon, color: rental.statusColor),
        title: Text(rental.equipmentName),
        subtitle: Text('${rental.userFullName} • ${DateFormat('MMM dd').format(rental.startDate)}'),
        trailing: Chip(
          label: Text(rental.statusText),
          backgroundColor: rental.statusBadgeColor,
          labelStyle: TextStyle(color: rental.statusColor, fontSize: 12),
        ),
      ),
    );
  }
}
