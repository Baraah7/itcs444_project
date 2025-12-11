// 
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:itcs444_project/models/donation_model.dart';
import 'package:itcs444_project/screens/shared/donation_form.dart';
import 'package:itcs444_project/services/donation_service.dart';

class UserDonationDetails extends StatefulWidget {
  final String donationID;
  const UserDonationDetails({super.key, required this.donationID});

  @override
  State<UserDonationDetails> createState() => _UserDonationDetailsState();
}

class _UserDonationDetailsState extends State<UserDonationDetails> {
  late Future<Donation> _futureDonation;

  final Map<String, int> defaultIconCodes = {
    'Wheelchair': Icons.accessible.codePoint,
    'Electrical Bed': Icons.hotel.codePoint,
    'Mechanical Bed': Icons.bed.codePoint,
    'Shower Chair': Icons.bathroom.codePoint,
    'Walker': Icons.directions_walk.codePoint,
    'Walker with Wheels': Icons.accessible_forward.codePoint,
    'Crutches': Icons.healing.codePoint,
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
                    Icons.error,
                    size: 60,
                    color: Color(0xFFEF4444),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Error loading donation',
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
          final dateFormat = DateFormat('MMM dd, yyyy');

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Badge
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(d.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _getStatusColor(d.status).withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getStatusIcon(d.status),
                                size: 16,
                                color: _getStatusColor(d.status),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                d.status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _getStatusColor(d.status),
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Item Information Section
                      _buildSection(
                        title: 'Item Information',
                        icon: Icons.inventory_2,
                        child: Column(
                          children: [
                            _buildInfoRow(
                              label: 'Item Type',
                              value: d.itemType,
                              icon: IconData(
                                d.iconCode ??
                                    defaultIconCodes[d.itemType] ??
                                    Icons.help_outline.codePoint,
                                fontFamily: 'MaterialIcons',
                              ),
                            ),
                            _buildDivider(),
                            _buildInfoRow(
                              label: 'Item Name',
                              value: d.itemName,
                              icon: Icons.label,
                            ),
                            _buildDivider(),
                            _buildInfoRow(
                              label: 'Condition',
                              value: d.condition,
                              icon: Icons.star,
                            ),
                            _buildDivider(),
                            _buildInfoRow(
                              label: 'Quantity',
                              value: '${d.quantity ?? 1}',
                              icon: Icons.numbers,
                            ),
                            if (d.description != null &&
                                d.description!.isNotEmpty) ...[
                              _buildDivider(),
                              _buildInfoRow(
                                label: 'Description',
                                value: d.description!,
                                icon: Icons.description,
                                isMultiline: true,
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Donor Information Section
                      _buildSection(
                        title: 'Donor Information',
                        icon: Icons.person,
                        child: Column(
                          children: [
                            _buildInfoRow(
                              label: 'Name',
                              value: d.donorName,
                              icon: Icons.person_outline,
                            ),
                            _buildDivider(),
                            _buildInfoRow(
                              label: 'Email',
                              value: d.donorContact,
                              icon: Icons.email,
                            ),
                            if (d.donorPhone != null &&
                                d.donorPhone!.isNotEmpty) ...[
                              _buildDivider(),
                              _buildInfoRow(
                                label: 'Phone',
                                value: d.donorPhone!,
                                icon: Icons.phone,
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Submission Details Section
                      _buildSection(
                        title: 'Submission Details',
                        icon: Icons.event_note,
                        child: Column(
                          children: [
                            _buildInfoRow(
                              label: 'Submitted',
                              value: dateFormat.format(d.submissionDate),
                              icon: Icons.calendar_today,
                            ),
                            if (d.approvalDate != null) ...[
                              _buildDivider(),
                              _buildInfoRow(
                                label: 'Approved',
                                value: dateFormat.format(d.approvalDate!),
                                icon: Icons.check_circle,
                              ),
                            ],
                            if (d.rejectionDate != null) ...[
                              _buildDivider(),
                              _buildInfoRow(
                                label: 'Rejected',
                                value: dateFormat.format(d.rejectionDate!),
                                icon: Icons.cancel,
                              ),
                            ],
                            if (d.comments != null &&
                                d.comments!.trim().isNotEmpty) ...[
                              _buildDivider(),
                              _buildInfoRow(
                                label: 'Comments',
                                value: d.comments!,
                                icon: Icons.comment,
                                isMultiline: true,
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Images Section
                      if (d.imagePaths != null && d.imagePaths!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildSection(
                          title: 'Images',
                          icon: Icons.photo_library,
                          child: SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              itemCount: d.imagePaths!.length,
                              itemBuilder: (context, index) {
                                final url = d.imagePaths![index];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      url,
                                      height: 100,
                                      width: 100,
                                      fit: BoxFit.cover,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }
                                        return Container(
                                          height: 100,
                                          width: 100,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Color(0xFF2B6C67),
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                        height: 100,
                                        width: 100,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: const Color(0xFFE8ECEF),
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.broken_image,
                                          size: 32,
                                          color: Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Submit Another Button (Fixed at bottom)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Color(0xFFE8ECEF)),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DonationForm(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text(
                      'Submit Another Donation',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2B6C67),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF2B6C67).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF2B6C67),
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8ECEF)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A4A47).withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: child,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required IconData icon,
    bool isMultiline = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment:
            isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 16,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFF1F5F9),
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
