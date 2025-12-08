import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tracking_providers.dart';
import '../providers/auth_provider.dart';

class TrackingScreen extends StatefulWidget {
  @override
  _TrackingScreenState createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final trackingProvider = Provider.of<TrackingProvider>(context, listen: false);
    
    if (authProvider.currentUser != null) {
      trackingProvider.trackUserRentals(authProvider.currentUser!.docId!);
      trackingProvider.loadUserHistory(authProvider.currentUser!.docId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Rentals'),
      ),
      body: Consumer<TrackingProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsCard(provider.stats),
                SizedBox(height: 20),
                Text('Active Rentals', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                ...provider.activeRentals.map((rental) => _buildRentalCard(rental)),
                SizedBox(height: 20),
                Text('Rental History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                ...provider.rentalHistory.map((rental) => _buildRentalCard(rental)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsCard(Map<String, dynamic> stats) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Total', stats['total'] ?? 0, Colors.blue),
            _buildStatItem('Active', stats['active'] ?? 0, Colors.green),
            _buildStatItem('Completed', stats['completed'] ?? 0, Colors.grey),
            _buildStatItem('Overdue', stats['overdue'] ?? 0, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(value.toString(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildRentalCard(rental) {
    return Card(
      margin: EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(rental.statusIcon, color: rental.statusColor),
        title: Text(rental.equipmentName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(rental.dateRangeString),
            if (rental.daysRemaining != null)
              Text('${rental.daysRemaining} days remaining', style: TextStyle(color: rental.isOverdue ? Colors.red : Colors.green)),
          ],
        ),
        trailing: Chip(
          label: Text(rental.statusText, style: TextStyle(fontSize: 10)),
          backgroundColor: rental.statusBadgeColor,
        ),
      ),
    );
  }
}
