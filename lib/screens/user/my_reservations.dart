import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/reservation_service.dart';
import '../../models/rental_model.dart';
import '../../utils/theme.dart';
import 'equipment_detail.dart';

class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({super.key});

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen>
    with SingleTickerProviderStateMixin {
  final ReservationService _reservationService = ReservationService();
  late TabController _tabController;

  // 🔵 Search + Filter Variables
  String _searchQuery = "";
  String _selectedStatus = "All";
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        title: const Text('My Reservations'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active', icon: Icon(Icons.pending_actions)),
            Tab(text: 'History', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReservationsList(isHistory: false),
          _buildReservationsList(isHistory: true),
        ],
      ),
    );
  }

  Widget _buildReservationsList({required bool isHistory}) {
    return Column(
      children: [
        _buildSearchBar(),
        _buildFilters(isHistory: isHistory),

        Expanded(
          child: StreamBuilder<List<Rental>>(
            stream: _reservationService.getUserRentals(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              List<Rental> rentals = snapshot.data ?? [];

              // 🔵 FILTER BY TAB (Active vs History)
              rentals = rentals.where((r) {
                if (isHistory) {
                  // History includes: returned, cancelled (maintenance hidden from users)
                  return r.status == 'returned' || r.status == 'cancelled';
                } else {
                  // Active includes: pending, approved, checked_out
                  return r.status == 'pending' ||
                      r.status == 'approved' ||
                      r.status == 'checked_out';
                }
              }).toList();

              // 🔵 APPLY FILTERING
              rentals = _applyFilters(rentals, isHistory: isHistory);

              if (rentals.isEmpty) {
                return _buildEmptyState(isHistory: isHistory);
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: rentals.length,
                itemBuilder: (context, index) {
                  final rental = rentals[index];
                  final format = DateFormat('MMM dd, yyyy');

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // STATUS HEADER
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: rental.statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      rental.statusIcon,
                                      size: 16,
                                      color: rental.statusColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      rental.statusText.toUpperCase(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: rental.statusColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (rental.canBeCancelled && !isHistory)
                                TextButton(
                                  onPressed: () => _cancelRental(rental.id),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // EQUIPMENT NAME
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EquipmentDetailPage(
                                    equipmentId: rental.equipmentId,
                                  ),
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rental.equipmentName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                Text(
                                  rental.itemType,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // DATES
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'From',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      format.format(rental.startDate),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward,
                                color: Colors.grey,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'To',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      format.format(rental.endDate),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // PROGRESS
                          if (!isHistory) _buildProgressTracker(rental),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 🔵 SEARCH BAR
  // -------------------------------------------------------------
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        decoration: InputDecoration(
          hintText: "Search by equipment name...",
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (v) {
          setState(() => _searchQuery = v.trim().toLowerCase());
        },
      ),
    );
  }

  // -------------------------------------------------------------
  // 🔵 FILTER CHIPS (STATUS + DATE RANGE)
  // -------------------------------------------------------------
  Widget _buildFilters({required bool isHistory}) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        children: [
          _filterChip("All"),
          if (!isHistory) ...[
            _filterChip("pending"),
            _filterChip("approved"),
            _filterChip("Picked Up"),
          ],
          if (isHistory) ...[_filterChip("returned"), _filterChip("cancelled")],

          const SizedBox(width: 10),

          // 🔵 Date Range Button
          ElevatedButton.icon(
            onPressed: _pickDateRange,
            icon: const Icon(Icons.date_range),
            label: const Text("Dates"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[200],
              elevation: 0,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String status) {
    final isSelected = _selectedStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(status == "All" ? "All" : status.capitalize()),
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            _selectedStatus = status;
          });
        },
      ),
    );
  }

  // -------------------------------------------------------------
  // 🔵 DATE RANGE PICKER
  // -------------------------------------------------------------
  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2022),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  // -------------------------------------------------------------
  // 🔵 FILTER LOGIC
  // -------------------------------------------------------------
  List<Rental> _applyFilters(List<Rental> rentals, {required bool isHistory}) {
    return rentals.where((r) {
      // Search filter
      final matchesSearch =
          r.equipmentName.toLowerCase().contains(_searchQuery) ||
          r.itemType.toLowerCase().contains(_searchQuery);

      // Status filter
      final matchesStatus =
          _selectedStatus == "All" || r.status == _selectedStatus;

      // Date filter
      final matchesDate =
          (_startDate == null || r.startDate.isAfter(_startDate!)) &&
          (_endDate == null || r.endDate.isBefore(_endDate!));

      return matchesSearch && matchesStatus && matchesDate;
    }).toList();
  }

  // -------------------------------------------------------------
  // 🔵 EMPTY STATE
  // -------------------------------------------------------------
  Widget _buildEmptyState({required bool isHistory}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isHistory ? Icons.history : Icons.event_busy,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 20),
          Text(
            isHistory ? "No rental history" : "No active reservations",
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 🔵 PROGRESS TRACKER (your original code)
  // -------------------------------------------------------------
  Widget _buildProgressTracker(Rental rental) {
    final steps = ['Requested', 'Approved', 'Picked Up', 'Returned'];
    final currentStep = rental.status == 'pending'
        ? 0
        : rental.status == 'approved'
        ? 1
        : rental.status == 'checked_out'
        ? 2
        : 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status Progress',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Row(
          children: steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isActive = index <= currentStep;

            return Expanded(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: isActive
                        ? AppColors.primaryBlue
                        : Colors.grey[300],
                    child: isActive
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step,
                    style: TextStyle(
                      fontSize: 10,
                      color: isActive ? AppColors.primaryBlue : Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 🔵 CANCEL RESERVATION
  // -------------------------------------------------------------
  Future<void> _cancelRental(String rentalId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Reservation'),
        content: const Text(
          'Are you sure you want to cancel this reservation?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _reservationService.cancelRental(rentalId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reservation cancelled'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// 🔵 Helper capitalize
extension StringX on String {
  String capitalize() =>
      isEmpty ? this : "${this[0].toUpperCase()}${substring(1)}";
}
