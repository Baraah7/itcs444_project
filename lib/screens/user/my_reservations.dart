import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/reservation_service.dart';
import '../../models/rental_model.dart';
import 'equipment_detail.dart';

class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({Key? key}) : super(key: key);

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen>
    with SingleTickerProviderStateMixin {
  final ReservationService _reservationService = ReservationService();
  late TabController _tabController;

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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Reservations',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Column(
            children: [
              Container(
                color: const Color(0xFFE8ECEF),
                height: 1,
              ),
              TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF2B6C67),
                unselectedLabelColor: const Color(0xFF64748B),
                indicatorColor: const Color(0xFF2B6C67),
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.pending_actions),
                    text: 'Active',
                  ),
                  Tab(
                    icon: Icon(Icons.history),
                    text: 'History',
                  ),
                ],
              ),
            ],
          ),
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
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF2B6C67),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error,
                        size: 60,
                        color: Color(0xFFEF4444),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Error loading reservations',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF1E293B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                );
              }

              List<Rental> rentals = snapshot.data ?? [];

              // Filter by tab
              rentals = rentals.where((r) {
                if (isHistory) {
                  return r.status == 'returned' || r.status == 'cancelled';
                } else {
                  return r.status == 'pending' ||
                      r.status == 'approved' ||
                      r.status == 'checked_out';
                }
              }).toList();

              // Apply filtering
              rentals = _applyFilters(rentals, isHistory: isHistory);

              if (rentals.isEmpty) {
                return _buildEmptyState(isHistory: isHistory);
              }

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: rentals.length,
                itemBuilder: (context, index) {
                  return _buildReservationCard(rentals[index], isHistory);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8ECEF)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A4A47).withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          decoration: const InputDecoration(
            hintText: "Search by equipment name...",
            hintStyle: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: Color(0xFF64748B),
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF1E293B),
          ),
          onChanged: (v) {
            setState(() => _searchQuery = v.trim().toLowerCase());
          },
        ),
      ),
    );
  }

  Widget _buildFilters({required bool isHistory}) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _filterChip("All"),
          if (!isHistory) ...[
            _filterChip("pending"),
            _filterChip("approved"),
            _filterChip("checked_out"),
          ],
          if (isHistory) ...[
            _filterChip("returned"),
            _filterChip("cancelled"),
          ],
          const SizedBox(width: 8),
          _buildDateRangeButton(),
        ],
      ),
    );
  }

  Widget _filterChip(String status) {
    final isSelected = _selectedStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          status == "All" ? "All" : status.capitalize(),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? const Color(0xFF2B6C67) : const Color(0xFF64748B),
          ),
        ),
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            _selectedStatus = status;
          });
        },
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF2B6C67).withOpacity(0.1),
        checkmarkColor: const Color(0xFF2B6C67),
        side: BorderSide(
          color: isSelected ? const Color(0xFF2B6C67) : const Color(0xFFE8ECEF),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildDateRangeButton() {
    return OutlinedButton.icon(
      onPressed: _pickDateRange,
      icon: const Icon(Icons.date_range, size: 18),
      label: Text(
        _startDate != null && _endDate != null
            ? '${DateFormat('MM/dd').format(_startDate!)} - ${DateFormat('MM/dd').format(_endDate!)}'
            : 'Date Range',
        style: const TextStyle(fontSize: 13),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF2B6C67),
        side: const BorderSide(color: Color(0xFFE8ECEF)),
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildReservationCard(Rental rental, bool isHistory) {
    final format = DateFormat('MMM dd, yyyy');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECEF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A4A47).withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header
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
                    border: Border.all(
                      color: rental.statusColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
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
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: rental.statusColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (rental.canBeCancelled && !isHistory)
                  TextButton.icon(
                    onPressed: () => _cancelRental(rental.id),
                    icon: const Icon(Icons.cancel, size: 16),
                    label: const Text('Cancel'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Equipment Name
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
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2B6C67),
                      decoration: TextDecoration.underline,
                      decorationColor: Color(0xFF2B6C67),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rental.itemType,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Dates
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8ECEF)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.event,
                              size: 14,
                              color: Color(0xFF64748B),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Start Date',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          format.format(rental.startDate),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.arrow_forward,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              Icons.event,
                              size: 14,
                              color: Color(0xFF64748B),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'End Date',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          format.format(rental.endDate),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Additional Info
            Row(
              children: [
                Expanded(
                  child: _buildInfoChip(
                    icon: Icons.shopping_cart,
                    label: 'Qty',
                    value: '${rental.quantity}',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoChip(
                    icon: Icons.access_time,
                    label: 'Duration',
                    value: '${rental.endDate.difference(rental.startDate).inDays}d',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoChip(
                    icon: Icons.attach_money,
                    label: 'Cost',
                    value: rental.formattedCost,
                  ),
                ),
              ],
            ),

            if (!isHistory) ...[
              const SizedBox(height: 16),
              _buildProgressTracker(rental),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8ECEF)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

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
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(steps.length, (index) {
            final isActive = index <= currentStep;
            final isLast = index == steps.length - 1;

            return Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive
                                ? const Color(0xFF2B6C67)
                                : const Color(0xFFE8ECEF),
                            border: Border.all(
                              color: isActive
                                  ? const Color(0xFF2B6C67)
                                  : const Color(0xFFE8ECEF),
                              width: 2,
                            ),
                          ),
                          child: isActive
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          steps[index],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isActive
                                ? const Color(0xFF2B6C67)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        height: 2,
                        margin: const EdgeInsets.only(bottom: 24),
                        color: isActive
                            ? const Color(0xFF2B6C67)
                            : const Color(0xFFE8ECEF),
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2022),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2B6C67),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  List<Rental> _applyFilters(List<Rental> rentals, {required bool isHistory}) {
    return rentals.where((r) {
      final matchesSearch =
          r.equipmentName.toLowerCase().contains(_searchQuery) ||
              r.itemType.toLowerCase().contains(_searchQuery);

      final matchesStatus =
          _selectedStatus == "All" || r.status == _selectedStatus;

      final matchesDate =
          (_startDate == null || r.startDate.isAfter(_startDate!)) &&
              (_endDate == null || r.endDate.isBefore(_endDate!));

      return matchesSearch && matchesStatus && matchesDate;
    }).toList();
  }

  Widget _buildEmptyState({required bool isHistory}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFE8ECEF),
                  width: 2,
                ),
              ),
              child: Icon(
                isHistory ? Icons.history : Icons.event_busy,
                size: 64,
                color: const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isHistory ? "No rental history" : "No active reservations",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isHistory
                  ? "Your past reservations will appear here"
                  : "Start by browsing available equipment",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelRental(String rentalId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Cancel Reservation',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        content: const Text(
          'Are you sure you want to cancel this reservation?',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
            ),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _reservationService.cancelRental(rentalId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reservation cancelled successfully'),
              backgroundColor: Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }
}

extension StringX on String {
  String capitalize() =>
      isEmpty ? this : "${this[0].toUpperCase()}${substring(1)}";
}
