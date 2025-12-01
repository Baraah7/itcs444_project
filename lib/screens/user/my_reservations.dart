//Reservation history + status
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/reservation_model.dart';
import '../../providers/reservation_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/reservation_card.dart';
import 'reservation_detail.dart';

class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({Key? key}) : super(key: key);

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  int _selectedTab = 0;
  bool _isLoading = false;
  String _searchQuery = '';

  final List<Map<String, dynamic>> _tabs = [
    {'label': 'All', 'icon': Icons.list, 'filter': null},
    {'label': 'Pending', 'icon': Icons.pending, 'filter': ReservationStatus.pending},
    {'label': 'Approved', 'icon': Icons.check_circle, 'filter': ReservationStatus.approved},
    {'label': 'Active', 'icon': Icons.inventory, 'filter': null}, // Special filter
    {'label': 'Completed', 'icon': Icons.done_all, 'filter': null}, // Special filter
  ];

  @override
  Widget build(BuildContext context) {
    final reservationProvider = Provider.of<ReservationProvider>(context);
    final userReservations = reservationProvider.userReservations;
    final stats = reservationProvider.getUserReservationStats();

    // Filter reservations based on selected tab
    List<Reservation> filteredReservations = _filterReservations(userReservations);
    
    // Apply search filter if query exists
    if (_searchQuery.isNotEmpty) {
      filteredReservations = filteredReservations.where((reservation) {
        return reservation.equipmentName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               reservation.id.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Sort by date (newest first)
    filteredReservations.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reservations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search reservations...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Statistics Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 5,
              childAspectRatio: 0.8,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                _buildStatCard(
                  context,
                  'Total',
                  stats['total'].toString(),
                  Icons.list_alt,
                  AppColors.primaryBlue,
                ),
                _buildStatCard(
                  context,
                  'Pending',
                  stats['pending'].toString(),
                  Icons.pending,
                  Colors.orange,
                ),
                _buildStatCard(
                  context,
                  'Active',
                  stats['active'].toString(),
                  Icons.inventory,
                  Colors.green,
                ),
                _buildStatCard(
                  context,
                  'Completed',
                  stats['completed'].toString(),
                  Icons.done_all,
                  AppColors.success,
                ),
                _buildStatCard(
                  context,
                  'Cancelled',
                  stats['cancelled'].toString(),
                  Icons.cancel,
                  AppColors.error,
                ),
              ],
            ),
          ),

          // Tab Bar
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _tabs.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0),
                  child: ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_tabs[index]['icon'], size: 16),
                        const SizedBox(width: 4),
                        Text(_tabs[index]['label']),
                      ],
                    ),
                    selected: _selectedTab == index,
                    selectedColor: AppColors.primaryBlue,
                    labelStyle: TextStyle(
                      color: _selectedTab == index ? Colors.white : AppColors.neutralGray,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _selectedTab = selected ? index : 0;
                      });
                    },
                  ),
                );
              },
            ),
          ),

          // Warnings
          _buildWarnings(userReservations),

          // Reservations List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryBlue,
                    ),
                  )
                : filteredReservations.isEmpty
                    ? _buildEmptyState(_selectedTab, _searchQuery)
                    : RefreshIndicator(
                        onRefresh: _refreshData,
                        color: AppColors.primaryBlue,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredReservations.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final reservation = filteredReservations[index];
                            return ReservationCard(
                              reservation: reservation,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReservationDetailScreen(
                                      reservation: reservation,
                                    ),
                                  ),
                                );
                              },
                              showActions: reservation.canCancel,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to equipment list
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/equipment-list',
            (route) => false,
          );
        },
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        tooltip: 'New Reservation',
      ),
    );
  }

  List<Reservation> _filterReservations(List<Reservation> reservations) {
    switch (_selectedTab) {
      case 0: // All
        return reservations;
      case 1: // Pending
        return reservations
            .where((r) => r.status == ReservationStatus.pending)
            .toList();
      case 2: // Approved
        return reservations
            .where((r) => r.status == ReservationStatus.approved)
            .toList();
      case 3: // Active (Approved + Checked Out)
        return reservations
            .where((r) => r.status == ReservationStatus.approved || 
                          r.status == ReservationStatus.checkedOut)
            .toList();
      case 4: // Completed (Returned + Cancelled)
        return reservations
            .where((r) => r.status == ReservationStatus.returned || 
                          r.status == ReservationStatus.cancelled)
            .toList();
      default:
        return reservations;
    }
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.neutralGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarnings(List<Reservation> reservations) {
    final overdueReservations = reservations.where((r) => r.isOverdue).toList();
    final pendingReservations = reservations.where((r) => r.status == ReservationStatus.pending).toList();
    
    return Column(
      children: [
        // Overdue Warning
        if (overdueReservations.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: AppColors.error, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Overdue Equipment',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You have ${overdueReservations.length} overdue item(s). Please return immediately to avoid penalties.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Pending Approvals
        if (pendingReservations.isNotEmpty && _selectedTab != 1)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  const Icon(Icons.pending_actions, color: Colors.orange, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pending Approvals',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You have ${pendingReservations.length} reservation(s) waiting for admin approval.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(int tabIndex, String searchQuery) {
    if (searchQuery.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 80,
                color: AppColors.neutralGray.withOpacity(0.5),
              ),
              const SizedBox(height: 24),
              const Text(
                'No matching reservations found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Try a different search term or clear the search',
                style: TextStyle(
                  color: AppColors.neutralGray,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    String message = '';
    String subtitle = '';
    IconData icon = Icons.inventory_2_outlined;

    switch (tabIndex) {
      case 0:
        message = 'No Reservations Yet';
        subtitle = 'Browse equipment and make your first reservation';
        icon = Icons.search;
        break;
      case 1:
        message = 'No Pending Reservations';
        subtitle = 'All your reservations have been processed';
        icon = Icons.check_circle_outline;
        break;
      case 2:
        message = 'No Approved Reservations';
        subtitle = 'Your pending reservations are still under review';
        icon = Icons.pending_actions;
        break;
      case 3:
        message = 'No Active Reservations';
        subtitle = 'You don\'t have any equipment checked out currently';
        icon = Icons.inventory;
        break;
      case 4:
        message = 'No Completed Reservations';
        subtitle = 'Your rental history will appear here';
        icon = Icons.history;
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: AppColors.neutralGray.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (tabIndex == 0)
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/equipment-list',
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('Browse Equipment'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoading = false;
    });
  }
}