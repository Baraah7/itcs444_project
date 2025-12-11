import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tracking_providers.dart';

class AdminTrackingScreen extends StatefulWidget {
  const AdminTrackingScreen({super.key});

  @override
  _AdminTrackingScreenState createState() => _AdminTrackingScreenState();
}

class _AdminTrackingScreenState extends State<AdminTrackingScreen> {
  @override
  void initState() {
    super.initState();
    final trackingProvider = Provider.of<TrackingProvider>(context, listen: false);
    trackingProvider.trackAllRentals();
    trackingProvider.loadAllHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Rentals Tracking'),
      ),
      body: Consumer<TrackingProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'Active Rentals'),
                    Tab(text: 'History'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildActiveRentals(provider.activeRentals),
                      _buildHistory(provider.rentalHistory),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveRentals(List rentals) {
    if (rentals.isEmpty) {
      return const Center(child: Text('No active rentals'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rentals.length,
      itemBuilder: (context, index) {
        final rental = rentals[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: Icon(rental.statusIcon, color: rental.statusColor),
            title: Text(rental.equipmentName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('User: ${rental.userFullName}'),
                Text(rental.dateRangeString),
                if (rental.daysRemaining != null)
                  Text('${rental.daysRemaining} days remaining', 
                    style: TextStyle(color: rental.isOverdue ? Colors.red : Colors.green)),
              ],
            ),
            trailing: Chip(
              label: Text(rental.statusText, style: const TextStyle(fontSize: 10)),
              backgroundColor: rental.statusBadgeColor,
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistory(List rentals) {
    if (rentals.isEmpty) {
      return const Center(child: Text('No rental history'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rentals.length,
      itemBuilder: (context, index) {
        final rental = rentals[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: Icon(rental.statusIcon, color: rental.statusColor),
            title: Text(rental.equipmentName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('User: ${rental.userFullName}'),
                Text(rental.dateRangeString),
              ],
            ),
            trailing: Chip(
              label: Text(rental.statusText, style: const TextStyle(fontSize: 10)),
              backgroundColor: rental.statusBadgeColor,
            ),
          ),
        );
      },
    );
  }
}
