import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/reservation_service.dart';
import '../../services/notification_service.dart';
import '../../models/rental_model.dart';
import 'equipment_detail.dart';
import 'equipment_list.dart';

class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({super.key});

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  final ReservationService _reservationService = ReservationService();

  String _searchQuery = "";
  String _selectedStatus = "All";
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showHistory = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2B6C67),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Reservations',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Active/History Selection
            _buildViewSelector(),
            // Search Bar
            _buildSearchBar(),
            // Filters
            _buildFilters(isHistory: _showHistory),
            // Reservations List
            _buildReservationsContent(isHistory: _showHistory),
          ],
        ),
      ),
    );
  }

  Widget _buildViewSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFE8ECEF),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                _viewSelectorButton('Active', !_showHistory),
                const SizedBox(width: 12),
                _viewSelectorButton('History', _showHistory),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _viewSelectorButton(String label, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showHistory = label == 'History';
            _selectedStatus = "All"; // Reset filter when switching views
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color.fromARGB(255, 222, 235, 234) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF2B6C67) : const Color(0xFFE8ECEF),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                label == 'Active' ? Icons.pending_actions : Icons.history,
                size: 18,
                color: isSelected ? const Color(0xFF2B6C67) : const Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF2B6C67) : const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReservationsContent({required bool isHistory}) {
    return StreamBuilder<List<Rental>>(
      stream: _reservationService.getUserRentals(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 200,
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2B6C67),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            height: 200,
            child: Center(
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

        return Column(
          children: rentals.map((rental) => _buildReservationCard(rental, isHistory)).toList(),
        );
      },
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
    // Define status options based on view type
    final List<String> statusOptions = [
      "All",
      if (!isHistory) ...[
        "pending",
        "approved",
        "checked_out",
      ],
      if (isHistory) ...[
        "returned",
        "cancelled",
      ],
    ];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // Status Filter Dropdown
          const SizedBox(width: 9,),
          Container(
            width: 140,
            margin: const EdgeInsets.only(right: 12),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedStatus,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE8ECEF)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE8ECEF)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2B6C67), width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              dropdownColor: Colors.white,
              items: statusOptions.map((status) {
                return DropdownMenuItem<String>(
                  value: status,
                  child: Text(
                    status == "All" ? "All" : status.capitalize(),
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedStatus = value;
                  });
                }
              },
            ),
          ),

          // Date Range Button
          _buildDateRangeButton(),

          const SizedBox(width: 12,),
          // const Spacer(),

          // New Reservation Button
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserEquipmentPage()),
              );
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New Reservation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2B6C67),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ],
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildReservationCard(Rental rental, bool isHistory) {
    final format = DateFormat('MMM dd, yyyy');
    
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
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
              if (rental.status == 'approved' || rental.status == 'checked_out') ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _requestMoreTime(rental),
                    icon: const Icon(Icons.access_time, size: 18),
                    label: const Text('Request More Time'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2B6C67),
                      side: const BorderSide(color: Color(0xFF2B6C67)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
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
    return Padding(
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
    );
  }

  Future<void> _requestMoreTime(Rental rental) async {
    final TextEditingController daysController = TextEditingController(text: '7');
    final TextEditingController reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.access_time, color: Color(0xFF2B6C67)),
            SizedBox(width: 8),
            Text('Request More Time'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Request extension for "${rental.equipmentName}"',
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: daysController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Additional Days',
                hintText: 'Enter number of days',
                prefixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Reason (Optional)',
                hintText: 'Why do you need more time?',
                prefixIcon: const Icon(Icons.comment),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2B6C67),
              foregroundColor: Colors.white,
            ),
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final days = int.tryParse(daysController.text) ?? 7;
      final reason = reasonController.text;

      try {
        // Create extension request in Firestore
        await FirebaseFirestore.instance.collection('extension_requests').add({
          'rentalId': rental.id,
          'equipmentId': rental.equipmentId,
          'equipmentName': rental.equipmentName,
          'userId': rental.userId,
          'userFullName': rental.userFullName,
          'currentEndDate': rental.endDate.toIso8601String(),
          'requestedDays': days,
          'newEndDate': rental.endDate.add(Duration(days: days)).toIso8601String(),
          'reason': reason,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Notify admins
        await createAdminNotification(
          title: 'Extension Request',
          message: '${rental.userFullName} requested $days more days for "${rental.equipmentName}"',
          type: 'extension_request',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Extension request submitted successfully'),
              backgroundColor: Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error submitting request: $e'),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
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
