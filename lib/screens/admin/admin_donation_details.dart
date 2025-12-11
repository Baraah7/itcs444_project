import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:itcs444_project/models/donation_model.dart';
import 'package:itcs444_project/services/donation_service.dart';

class DonationDetails extends StatefulWidget {
  final String donationID;
  const DonationDetails({super.key, required this.donationID});

  @override
  State<DonationDetails> createState() => _DonationDetailsState();
}

class _DonationDetailsState extends State<DonationDetails> {
  late Future<Donation> _futureDonation;
  bool _isProcessing = false;

  final Map<String, int> defaultIconCodes = {
    'Electronics': Icons.devices.codePoint,
    'Furniture': Icons.chair.codePoint,
    'Books': Icons.book.codePoint,
    'Clothing': Icons.checkroom.codePoint,
    'Sports': Icons.sports.codePoint,
    'Toys': Icons.toys.codePoint,
    'Other': Icons.category.codePoint,
  };

  @override
  void initState() {
    super.initState();
    _futureDonation = DonationService().fetchDonation(widget.donationID);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Donation Details',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFE8ECEF),
            height: 1,
          ),
        ),
      ),
      body: FutureBuilder<Donation>(
        future: _futureDonation,
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
                    Icons.error_outline,
                    size: 64,
                    color: Color(0xFFEF4444),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Error Loading Donation',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
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

          if (!snapshot.hasData) {
            return const Center(
              child: Text(
                'Donation not found',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF64748B),
                ),
              ),
            );
          }

          final d = snapshot.data!;
          final dateFormat = DateFormat('dd-MM-yyyy');
          final bool isPending = d.status == 'Pending';

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(d.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getStatusColor(d.status).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getStatusIcon(d.status),
                              size: 14,
                              color: _getStatusColor(d.status),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              d.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _getStatusColor(d.status),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Main Card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE8ECEF)),
                        ),
                        child: Column(
                          children: [
                            // Item Info Header
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFF2B6C67).withOpacity(0.05),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2B6C67)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      IconData(
                                        d.iconCode ??
                                            defaultIconCodes[d.itemType] ??
                                            Icons.help_outline.codePoint,
                                        fontFamily: 'MaterialIcons',
                                      ),
                                      color: const Color(0xFF2B6C67),
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${d.itemType} Donation',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          d.itemName,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // All Details
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  _buildDetailRow('Item Type', d.itemType),
                                  const Divider(height: 24),
                                  _buildDetailRow('Item Name', d.itemName),
                                  const Divider(height: 24),
                                  _buildDetailRow('Condition', d.condition),
                                  const Divider(height: 24),
                                  _buildDetailRow(
                                      'Quantity', '${d.quantity ?? 1}'),
                                  const Divider(height: 24),
                                  _buildDetailRow(
                                      'Description', d.description ?? 'N/A',
                                      isLong: true),
                                  const Divider(height: 24),
                                  _buildDetailRow('Donor Name', d.donorName),
                                  const Divider(height: 24),
                                  _buildDetailRow(
                                      'Donor Contact', d.donorContact),
                                  const Divider(height: 24),
                                  _buildDetailRow('Submitted On',
                                      dateFormat.format(d.submissionDate)),
                                  const Divider(height: 24),
                                  _buildDetailRow('Status', d.status),
                                  if (d.approvalDate != null) ...[
                                    const Divider(height: 24),
                                    _buildDetailRow('Approved On',
                                        dateFormat.format(d.approvalDate!)),
                                  ],
                                  if (d.rejectionDate != null) ...[
                                    const Divider(height: 24),
                                    _buildDetailRow('Rejected On',
                                        dateFormat.format(d.rejectionDate!)),
                                  ],
                                  const Divider(height: 24),
                                  _buildDetailRow(
                                      'Comments',
                                      (d.comments == null ||
                                              d.comments!.trim().isEmpty)
                                          ? 'N/A'
                                          : d.comments!,
                                      isLong: true),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Images
                      if (d.imagePaths != null && d.imagePaths!.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Text(
                          'Images',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: d.imagePaths!.length,
                            itemBuilder: (context, index) {
                              final url = d.imagePaths![index];
                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    url,
                                    height: 120,
                                    width: 120,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                      height: 120,
                                      width: 120,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFFE8ECEF),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.broken_image,
                                        size: 40,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Action Buttons (Fixed at bottom)
              if (isPending)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Color(0xFFE8ECEF)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing
                              ? null
                              : () => _handleApprove(d.id!),
                          icon: _isProcessing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check_circle, size: 18),
                          label: const Text(
                            'Approve',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed:
                              _isProcessing ? null : () => _handleReject(d.id!),
                          icon: _isProcessing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.cancel, size: 18),
                          label: const Text(
                            'Reject',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isLong = false}) {
    return Row(
      crossAxisAlignment:
          isLong ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleApprove(String donationId) async {
    if (_isProcessing) return;

    final confirm = await _showConfirmDialog(
      title: 'Approve Donation',
      message: 'Are you sure you want to approve this donation?',
      confirmText: 'Approve',
      confirmColor: const Color(0xFF10B981),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);

    try {
      await DonationService().approveDonation(donationId);

      if (mounted) {
        setState(() {
          _futureDonation = DonationService().fetchDonation(donationId);
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Donation approved successfully'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);

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

  Future<void> _handleReject(String donationId) async {
    if (_isProcessing) return;

    final confirm = await _showConfirmDialog(
      title: 'Reject Donation',
      message: 'Are you sure you want to reject this donation?',
      confirmText: 'Reject',
      confirmColor: const Color(0xFFEF4444),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);

    try {
      await DonationService().rejectDonation(donationId);

      if (mounted) {
        setState(() {
          _futureDonation = DonationService().fetchDonation(donationId);
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Donation rejected successfully'),
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);

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

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'approved':
        return const Color(0xFF10B981);
      case 'rejected':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending_actions;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }
}
