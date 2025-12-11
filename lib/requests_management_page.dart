import 'package:flutter/material.dart';
import 'package:itcs444_project/models/rental_model.dart';
import 'package:itcs444_project/services/reservation_service.dart';

class RequestsManagementPage extends StatefulWidget {
  const RequestsManagementPage({super.key});

  @override
  State<RequestsManagementPage> createState() => _RequestsManagementPageState();
}

class _RequestsManagementPageState extends State<RequestsManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ReservationService _reservationService = ReservationService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Requests Management"),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "Pending"),
            Tab(text: "Approved"),
            Tab(text: "Active"),
            Tab(text: "Completed"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRequestsList('pending'),
          _buildRequestsList('approved'),
          _buildRequestsList('active'),
          _buildRequestsList('completed'),
        ],
      ),
    );
  }

  Widget _buildRequestsList(String status) {
    return StreamBuilder<List<Rental>>(
      stream: _reservationService.getAllRentals(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No requests found.'));
        }

        final rentals = snapshot.data!.where((r) => r.status == status).toList();

        if (rentals.isEmpty) {
          return Center(child: Text('No requests with status "$status".'));
        }

        return ListView.builder(
          itemCount: rentals.length,
          itemBuilder: (context, index) {
            return _buildRequestCard(rentals[index]);
          },
        );
      },
    );
  }

  Widget _buildRequestCard(Rental rental) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              rental.userFullName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Equipment: ${rental.equipmentName}"),
                Chip(
                  label: Text(rental.status.toUpperCase()),
                  backgroundColor: _getStatusColor(rental.status).withOpacity(.2),
                  labelStyle: TextStyle(
                    color: _getStatusColor(rental.status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Text(
              "From: ${rental.startDate.toLocal().toString().split(' ')[0]}   →   To: ${rental.endDate.toLocal().toString().split(' ')[0]}",
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            _buildActionButtons(rental),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "pending":
        return Colors.orange;
      case "approved":
        return Colors.blue;
      case "active":
      case "checked_out":
        return Colors.green;
      case "completed":
      case "returned":
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  Widget _buildActionButtons(Rental rental) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (rental.status == "pending") ...[
          ElevatedButton(
            onPressed: () => _updateRentalStatus(rental.id, 'approved'),
            child: const Text("Approve"),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: () => _updateRentalStatus(rental.id, 'cancelled'),
            child: const Text("Decline"),
          ),
        ],
        if (rental.status == "approved") ...[
          ElevatedButton(
            onPressed: () => _updateRentalStatus(rental.id, 'checked_out'),
            child: const Text("Pick Up"),
          ),
        ],
        if (rental.status == "active" || rental.status == "checked_out") ...[
          ElevatedButton(
            onPressed: () => _updateRentalStatus(rental.id, 'returned'),
            child: const Text("Mark Returned"),
          ),
        ],
      ],
    );
  }

  void _updateRentalStatus(String rentalId, String newStatus) {
    _reservationService.updateRentalStatus(rentalId: rentalId, status: newStatus)
      .then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rental status updated to $newStatus')),
        );
      })
      .catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $error')),
        );
      });
  }
}

