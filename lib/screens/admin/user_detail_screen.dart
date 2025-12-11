import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/rental_model.dart';
import '../../models/donation_model.dart';

class UserDetailScreen extends StatefulWidget {
  final AppUser user;

  const UserDetailScreen({super.key, required this.user});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.user.firstName} ${widget.user.lastName}'),
      ),
      body: Column(
        children: [
          _buildUserHeader(),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Details'),
              Tab(text: 'Reservations'),
              Tab(text: 'Donations'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDetailsTab(),
                _buildReservationsTab(),
                _buildDonationsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.grey[100],
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: widget.user.role == 'admin' ? Colors.red : Colors.blue,
            child: Text(
              widget.user.firstName.isNotEmpty ? widget.user.firstName[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.user.firstName} ${widget.user.lastName}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(widget.user.email, style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.user.role == 'admin' ? Colors.red : Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.user.role.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard('Personal Information', [
          _buildInfoRow('First Name', widget.user.firstName),
          _buildInfoRow('Last Name', widget.user.lastName),
          _buildInfoRow('Username', widget.user.username),
          _buildInfoRow('CPR', widget.user.cpr),
        ]),
        const SizedBox(height: 16),
        _buildInfoCard('Contact Information', [
          _buildInfoRow('Email', widget.user.email),
          _buildInfoRow('Phone', widget.user.phoneNumber),
          _buildInfoRow('Preferred Contact', widget.user.contactPref),
        ]),
        const SizedBox(height: 16),
        _buildInfoCard('Account Information', [
          _buildInfoRow('User ID', widget.user.docId ?? 'N/A'),
          _buildInfoRow('Role', widget.user.role),
        ]),
        const SizedBox(height: 16),
        _buildStatisticsCard(),
      ],
    );
  }

  Widget _buildReservationsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rentals')
          .where('userId', isEqualTo: widget.user.docId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No reservations found'));
        }

        final rentals = snapshot.data!.docs
            .map((doc) => Rental.fromMap(doc.data() as Map<String, dynamic>))
            .toList();

        final active = rentals.where((r) => r.status == 'pending' || r.status == 'approved' || r.status == 'checked_out').toList();
        final history = rentals.where((r) => r.status == 'returned' || r.status == 'cancelled').toList();

        if (active.isEmpty && history.isEmpty) {
          return const Center(child: Text('No reservations found'));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (active.isNotEmpty) ...[
              const Text('Active Reservations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...active.map((rental) => _buildRentalCard(rental)),
              const SizedBox(height: 24),
            ],
            if (history.isNotEmpty) ...[
              const Text('Reservation History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...history.map((rental) => _buildRentalCard(rental)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildDonationsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('donations')
          .where('donorID', isEqualTo: widget.user.docId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No donations found'));
        }

        final donations = snapshot.data!.docs
            .map((doc) => Donation.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: donations.length,
          itemBuilder: (context, index) => _buildDonationCard(donations[index]),
        );
      },
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value.toString(), style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return FutureBuilder<Map<String, int>>(
      future: _getUserStatistics(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
        }

        final stats = snapshot.data!;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Statistics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Total Rentals', stats['totalRentals']!, Colors.blue),
                    _buildStatItem('Active', stats['activeRentals']!, Colors.green),
                    _buildStatItem('Donations', stats['totalDonations']!, Colors.orange),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(value.toString(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  Widget _buildRentalCard(Rental rental) {
    final format = DateFormat('MMM dd, yyyy');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(rental.equipmentName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: rental.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    rental.statusText.toUpperCase(),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: rental.statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(rental.itemType, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${format.format(rental.startDate)} - ${format.format(rental.endDate)}'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.attach_money, size: 14, color: Colors.grey[600]),
                Text('\$${rental.totalCost.toStringAsFixed(2)}'),
                const SizedBox(width: 16),
                Icon(Icons.inventory, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('Qty: ${rental.quantity}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonationCard(Donation donation) {
    final format = DateFormat('MMM dd, yyyy');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(donation.itemName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getDonationStatusColor(donation.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    donation.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getDonationStatusColor(donation.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(donation.itemType, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(format.format(donation.submissionDate)),
                const SizedBox(width: 16),
                Icon(Icons.inventory, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('Qty: ${donation.quantity ?? 1}'),
              ],
            ),
            if (donation.description != null && donation.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(donation.description!, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }

  Color _getDonationStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<Map<String, int>> _getUserStatistics() async {
    final rentalsSnapshot = await FirebaseFirestore.instance
        .collection('rentals')
        .where('userId', isEqualTo: widget.user.docId)
        .get();

    final donationsSnapshot = await FirebaseFirestore.instance
        .collection('donations')
        .where('donorID', isEqualTo: widget.user.docId)
        .get();

    final activeRentals = rentalsSnapshot.docs
        .where((doc) {
          final status = (doc.data())['status'];
          return status == 'approved' || status == 'checked_out';
        })
        .length;

    return {
      'totalRentals': rentalsSnapshot.docs.length,
      'activeRentals': activeRentals,
      'totalDonations': donationsSnapshot.docs.length,
    };
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
