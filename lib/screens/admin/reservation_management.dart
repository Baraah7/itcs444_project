import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/reservation_service.dart';
import '../../services/equipment_service.dart';
import '../../models/rental_model.dart';
import '../../utils/theme.dart';

class ReservationManagementScreen extends StatefulWidget {
  const ReservationManagementScreen({super.key});

  @override
  State<ReservationManagementScreen> createState() =>
      _ReservationManagementScreenState();
}

class _ReservationManagementScreenState
    extends State<ReservationManagementScreen> {
  final ReservationService _reservationService = ReservationService();
  final EquipmentService _equipmentService = EquipmentService();
  final TextEditingController _searchController = TextEditingController();
  final Map<String, String> _selectedNotes = {};

  String _filterStatus = 'all';
  String _searchQuery = '';

  final List<String> _noteOptions = [
    'None',
    'Equipment in good condition',
    'Equipment needs cleaning',
    'Minor damage detected',
    'Late return',
    'User notified',
    'Approved by supervisor',
    'Urgent request',
  ];

  final List<String> _statusFilters = [
    'all',
    'pending',
    'approved',
    'checked_out',
    'returned',
    'cancelled',
    'maintenance',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _updateRentalStatus({
    required String rentalId,
    required String status,
    String? notes,
  }) async {
    try {
      await _reservationService.updateRentalStatus(
        rentalId: rentalId,
        status: status,
        adminNotes: notes,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showRentalDetails(Rental rental) async {
    final format = DateFormat('MMM dd, yyyy HH:mm');

    return showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Rental Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.3,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: rental.statusBadgeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: rental.statusColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            rental.statusIcon,
                            size: 14,
                            color: rental.statusColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            rental.statusText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: rental.statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _detailRow('ID', '${rental.id.substring(0, 12)}...'),
                _detailRow('User', rental.userFullName),
                _detailRow('Equipment', rental.equipmentName),
                _detailRow('Type', rental.itemType),
                _detailRow('Quantity', rental.quantity.toString()),
                _detailRow('Start Date', format.format(rental.startDate)),
                _detailRow('End Date', format.format(rental.endDate)),
                if (rental.actualReturnDate != null)
                  _detailRow(
                    'Returned Date',
                    format.format(rental.actualReturnDate!),
                  ),
                if (rental.adminNotes != null &&
                    rental.adminNotes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Admin Notes:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE8ECEF)),
                    ),
                    child: Text(rental.adminNotes!),
                  ),
                ],
                if (rental.isOverdue) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.red, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Overdue by ${DateTime.now().difference(rental.endDate).inDays} days',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2B6C67), Color(0xFF1A4A47)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2B6C67).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRentalCard(Rental rental) {
    final format = DateFormat('MMM dd, yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECEF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF2B6C67).withOpacity(0.1),
                      const Color(0xFF1A4A47).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFF2B6C67),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rental.userFullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      rental.equipmentName,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: rental.statusBadgeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: rental.statusColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      rental.statusIcon,
                      size: 14,
                      color: rental.statusColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      rental.statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: rental.statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Details
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8ECEF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Period',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                Text(
                  '${format.format(rental.startDate)} - ${format.format(rental.endDate)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Additional info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9F8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.category,
                      size: 14,
                      color: Color(0xFF2B6C67),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      rental.itemType,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2B6C67),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9F8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.inventory,
                      size: 14,
                      color: Color(0xFF2B6C67),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Qty: ${rental.quantity}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2B6C67),
                      ),
                    ),
                  ],
                ),
              ),
              if (rental.isOverdue) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, size: 14, color: Colors.red),
                      SizedBox(width: 4),
                      Text(
                        'Overdue',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // Action buttons
          _buildActionButtons(rental),

          const SizedBox(height: 8),

          // View details button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showRentalDetails(rental),
              icon: const Icon(Icons.visibility_outlined, size: 16),
              label: const Text('View Details'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2B6C67),
                side: const BorderSide(color: Color(0xFF2B6C67)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Rental rental) {
    switch (rental.status) {
      case 'pending':
        return Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _updateRentalStatus(
                    rentalId: rental.id,
                    status: 'approved',
                  ),
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _updateRentalStatus(
                    rentalId: rental.id,
                    status: 'cancelled',
                  ),
                  icon: const Icon(Icons.cancel, size: 18),
                  label: const Text('Decline'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );

      case 'approved':
        return Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _updateRentalStatus(
                    rentalId: rental.id,
                    status: 'checked_out',
                  ),
                  icon: const Icon(Icons.shopping_bag, size: 18),
                  label: const Text('Pick Up'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _updateRentalStatus(
                  rentalId: rental.id,
                  status: 'cancelled',
                ),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Cancel'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        );

      case 'checked_out':
        return Column(
          children: [
            if (rental.isOverdue)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red, width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Overdue by ${DateTime.now().difference(rental.endDate).inDays} days',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => _updateRentalStatus(
                        rentalId: rental.id,
                        status: 'returned',
                      ),
                      icon: const Icon(Icons.assignment_turned_in, size: 18),
                      label: const Text('Mark Returned'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showExtendDialog(rental),
                    icon: const Icon(Icons.schedule, size: 18),
                    label: const Text('Extend'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2B6C67),
                      side: const BorderSide(
                        color: Color(0xFF2B6C67),
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );

      case 'returned':
        return Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _updateRentalStatus(
                    rentalId: rental.id,
                    status: 'maintenance',
                  ),
                  icon: const Icon(Icons.build, size: 18),
                  label: const Text('Maintenance'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _markEquipmentAvailable(rental),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Available'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );

      case 'maintenance':
        return Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: () => _markEquipmentAvailable(rental),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Mark Available'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );

      default:
        return const SizedBox();
    }
  }

  Future<void> _showExtendDialog(Rental rental) async {
    final newEndDateController = TextEditingController(
      text: DateFormat(
        'yyyy-MM-dd',
      ).format(rental.endDate.add(const Duration(days: 7))),
    );

    return showDialog(
      context: context,
      builder: (dialogContext) => _ExtendRentalDialog(
        rental: rental,
        newEndDateController: newEndDateController,
        reservationService: _reservationService,
      ),
    );
  }

  Future<void> _markEquipmentAvailable(Rental rental) async {
    try {
      await _equipmentService.markEquipmentAvailable(rental.equipmentId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildStatisticsCard() {
    return StreamBuilder<List<Rental>>(
      stream: _reservationService.getAllRentals(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8ECEF)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E293B).withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFF2B6C67)),
            ),
          );
        }

        final rentals = snapshot.data!;
        final pending = rentals.where((r) => r.status == 'pending').length;
        final approved = rentals.where((r) => r.status == 'approved').length;
        final checkedOut =
            rentals.where((r) => r.status == 'checked_out').length;
        final overdue = rentals.where((r) => r.isOverdue).length;
        final returned = rentals.where((r) => r.status == 'returned').length;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8ECEF)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E293B).withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reservation Statistics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _statChip('Total', rentals.length.toString(),
                      const Color(0xFF2B6C67)),
                  _statChip(
                      'Pending', pending.toString(), const Color(0xFFF59E0B)),
                  _statChip(
                      'Approved', approved.toString(), const Color(0xFF3B82F6)),
                  _statChip('Picked Up', checkedOut.toString(),
                      const Color(0xFF10B981)),
                  _statChip(
                      'Overdue', overdue.toString(), const Color(0xFFEF4444)),
                  _statChip(
                      'Returned', returned.toString(), const Color(0xFF64748B)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: $value',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Reservation Management',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: StreamBuilder<List<Rental>>(
        stream: _reservationService.getAllRentals(),
        builder: (context, snapshot) {
          return CustomScrollView(
            slivers: [
              // Search and Filter Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE8ECEF)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1E293B).withOpacity(0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search by user, equipment...',
                              prefixIcon:
                                  const Icon(Icons.search, color: Color(0xFF64748B)),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear,
                                          color: Color(0xFF64748B)),
                                      onPressed: () => _searchController.clear(),
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                              hintStyle: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 14,
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE8ECEF)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1E293B).withOpacity(0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: DropdownButton<String>(
                          value: _filterStatus,
                          onChanged: (String? newValue) {
                            setState(() {
                              _filterStatus = newValue ?? 'all';
                            });
                          },
                          underline: const SizedBox(),
                          items: _statusFilters.map<DropdownMenuItem<String>>((
                            String value,
                          ) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value == 'all'
                                    ? 'All Status'
                                    : value.replaceAll('_', ' ').toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Statistics Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildStatisticsCard(),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Reservations List
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: Builder(
                  builder: (context) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SliverFillRemaining(
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF2B6C67),
                          ),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error,
                                  size: 60, color: Color(0xFFEF4444)),
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

                    final allRentals = snapshot.data ?? [];

                    // Apply filters
                    List<Rental> filteredRentals = allRentals;

                    // Apply status filter
                    if (_filterStatus != 'all') {
                      filteredRentals = filteredRentals
                          .where((r) => r.status == _filterStatus)
                          .toList();
                    }

                    // Apply search filter
                    if (_searchQuery.isNotEmpty) {
                      filteredRentals = filteredRentals.where((rental) {
                        return rental.userFullName
                                .toLowerCase()
                                .contains(_searchQuery.toLowerCase()) ||
                            rental.equipmentName
                                .toLowerCase()
                                .contains(_searchQuery.toLowerCase()) ||
                            rental.itemType
                                .toLowerCase()
                                .contains(_searchQuery.toLowerCase()) ||
                            rental.id
                                .toLowerCase()
                                .contains(_searchQuery.toLowerCase());
                      }).toList();
                    }

                    // Sort: overdue first, then pending, then by date
                    filteredRentals.sort((a, b) {
                      if (a.isOverdue && !b.isOverdue) return -1;
                      if (!a.isOverdue && b.isOverdue) return 1;
                      if (a.status == 'pending' && b.status != 'pending') {
                        return -1;
                      }
                      if (a.status != 'pending' && b.status == 'pending') {
                        return 1;
                      }
                      return b.createdAt.compareTo(a.createdAt);
                    });

                    if (filteredRentals.isEmpty) {
                      return SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.event_available,
                                size: 80,
                                color: Color(0xFFE8ECEF),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                _filterStatus == 'all'
                                    ? 'No reservations found'
                                    : 'No ${_filterStatus.replaceAll('_', ' ')} reservations',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (_searchQuery.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Search: "$_searchQuery"',
                                    style: const TextStyle(
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }

                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return _buildRentalCard(filteredRentals[index]);
                        },
                        childCount: filteredRentals.length,
                      ),
                    );
                  },
                ),
              ),

              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          );
        },
      ),
    );
  }
}

// Separate stateful widget for the extend rental dialog
class _ExtendRentalDialog extends StatefulWidget {
  final Rental rental;
  final TextEditingController newEndDateController;
  final ReservationService reservationService;

  const _ExtendRentalDialog({
    required this.rental,
    required this.newEndDateController,
    required this.reservationService,
  });

  @override
  State<_ExtendRentalDialog> createState() => _ExtendRentalDialogState();
}

class _ExtendRentalDialogState extends State<_ExtendRentalDialog> {
  String _dateKey = '0';

  Future<bool> _checkExtensionAvailability() async {
    try {
      final newEndDate = DateTime.tryParse(widget.newEndDateController.text);
      if (newEndDate == null ||
          newEndDate.isBefore(widget.rental.endDate) ||
          newEndDate.isAtSameMomentAs(widget.rental.endDate)) {
        return false;
      }

      return await widget.reservationService.checkAvailability(
        equipmentId: widget.rental.equipmentId,
        startDate: widget.rental.endDate,
        endDate: newEndDate,
        quantity: widget.rental.quantity,
        excludeRentalId: widget.rental.id,
      );
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Extend Rental',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Current end date: ${DateFormat('MMM dd, yyyy').format(widget.rental.endDate)}',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: widget.newEndDateController,
                decoration: InputDecoration(
                  labelText: 'New End Date',
                  hintText: 'YYYY-MM-DD',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE8ECEF)),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today,
                        color: Color(0xFF2B6C67)),
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: widget.rental.endDate.add(
                          const Duration(days: 7),
                        ),
                        firstDate:
                            widget.rental.endDate.add(const Duration(days: 1)),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null && mounted) {
                        widget.newEndDateController.text = DateFormat(
                          'yyyy-MM-dd',
                        ).format(picked);
                        setState(() {
                          _dateKey =
                              DateTime.now().millisecondsSinceEpoch.toString();
                        });
                      }
                    },
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _dateKey = DateTime.now().millisecondsSinceEpoch.toString();
                  });
                },
              ),
              const SizedBox(height: 20),
              FutureBuilder<bool>(
                key: ValueKey(_dateKey),
                future: _checkExtensionAvailability(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2B6C67),
                      ),
                    );
                  }

                  if (snapshot.hasError || snapshot.data == false) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              snapshot.hasError
                                  ? 'Error: ${snapshot.error}'
                                  : 'Equipment not available for this period',
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final newEndDate = DateTime.tryParse(
                    widget.newEndDateController.text,
                  );
                  if (newEndDate != null &&
                      newEndDate.isAfter(widget.rental.endDate)) {
                    final extraDays =
                        newEndDate.difference(widget.rental.endDate).inDays;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F9F8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF2B6C67).withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.check_circle,
                                  color: Color(0xFF2B6C67), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Available for extension',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF2B6C67),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Extension: $extraDays additional day${extraDays != 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return const SizedBox();
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2B6C67),
                        side: const BorderSide(color: Color(0xFF2B6C67)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2B6C67), Color(0xFF1A4A47)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2B6C67).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          final newEndDate = DateTime.tryParse(
                            widget.newEndDateController.text,
                          );
                          if (newEndDate == null ||
                              newEndDate.isBefore(widget.rental.endDate) ||
                              newEndDate
                                  .isAtSameMomentAs(widget.rental.endDate)) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Please select a valid future date'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                            return;
                          }

                          // Check availability one more time before extending
                          final isAvailable =
                              await _checkExtensionAvailability();
                          if (!isAvailable) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Equipment not available for this period'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                            return;
                          }

                          try {
                            await widget.reservationService.extendRental(
                              rentalId: widget.rental.id,
                              newEndDate: newEndDate,
                            );

                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Rental extended successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        child: const Text(
                          'Extend Rental',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.newEndDateController.dispose();
    super.dispose();
  }
}
