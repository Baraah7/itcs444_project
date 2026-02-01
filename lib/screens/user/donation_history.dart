import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:itcs444_project/models/donation_model.dart';
import 'package:itcs444_project/screens/shared/donation_form.dart';
import 'package:itcs444_project/screens/user/user_donation_details.dart';
import 'package:itcs444_project/services/donation_service.dart';

class DonationHistory extends StatefulWidget {
  const DonationHistory({super.key});

  @override
  State<DonationHistory> createState() => _DonationHistoryState();
}

class _DonationHistoryState extends State<DonationHistory> {
  final user = FirebaseAuth.instance.currentUser;
  bool _showHistory = false;
  String _searchQuery = "";
  String _selectedStatus = "All";

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Color(0xFF2B6C67),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'My Donations',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 20,
          ),
        ),
      ),
      body: _buildDonationsList(isHistory: _showHistory),
    );
  }

  Widget _buildDonationsList({required bool isHistory}) {
    return FutureBuilder<List<Donation>>(
      future: DonationService().fetchDonationsByUserId(user!.uid),
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
                  'Error loading donations',
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

        List<Donation> donations = snapshot.data ?? [];

        // Filter by tab
        donations = donations.where((d) {
          if (isHistory) {
            return d.status?.toLowerCase() == 'approved' ||
                d.status?.toLowerCase() == 'rejected' ||
                d.status?.toLowerCase() == 'completed';
          } else {
            return d.status?.toLowerCase() == 'pending';
          }
        }).toList();

        // Apply filtering
        donations = _applyFilters(donations, isHistory: isHistory);

        // Sort by date (newest first)
        donations.sort((a, b) {
          return b.submissionDate.compareTo(a.submissionDate);
        });

        if (donations.isEmpty) {
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildTabButtons(),
                _buildSearchBar(),
                _buildFilters(isHistory: isHistory),
                _buildEmptyState(isHistory: isHistory),
              ],
            ),
          );
        }

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildTabButtons(),
                  _buildSearchBar(),
                  _buildFilters(isHistory: isHistory),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return _buildDonationCard(donations[index], isHistory);
                  },
                  childCount: donations.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTabButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          _viewSelectorButton('Pending', !_showHistory),
          const SizedBox(width: 12),
          _viewSelectorButton('History', _showHistory),
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
            _selectedStatus = "All";
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
                label == 'Pending' ? Icons.pending_actions : Icons.history,
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
            hintText: "Search by item name...",
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
    List<String> filterOptions = ["All"];
    if (!isHistory) {
      filterOptions.add("Pending");
    } else {
      filterOptions.addAll(["Approved", "Rejected", "Completed"]);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8ECEF)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedStatus,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: Color(0xFF64748B),
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1E293B),
                  ),
                  items: filterOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() => _selectedStatus = newValue!);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DonationForm()),
              );
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New Donation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2B6C67),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonationCard(Donation donation, bool isHistory) {
    final format = DateFormat('MMM dd, yyyy');
    final status = donation.status.toLowerCase();

    // Status colors and icons
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case 'pending':
        statusColor = const Color(0xFFF59E0B);
        statusIcon = Icons.access_time;
        statusText = 'PENDING';
        break;
      case 'approved':
        statusColor = const Color(0xFF10B981);
        statusIcon = Icons.check_circle;
        statusText = 'APPROVED';
        break;
      case 'rejected':
        statusColor = const Color(0xFFEF4444);
        statusIcon = Icons.cancel;
        statusText = 'REJECTED';
        break;
      case 'completed':
        statusColor = const Color(0xFF2B6C67);
        statusIcon = Icons.done_all;
        statusText = 'COMPLETED';
        break;
      default:
        statusColor = const Color(0xFF64748B);
        statusIcon = Icons.help_outline;
        statusText = donation.status.toUpperCase();
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserDonationDetails(donationID: donation.id!),
          ),
        );
      },
      child: Container(
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
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon,
                          size: 16,
                          color: statusColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // View details arrow
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9F8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF2B6C67),
                      size: 20,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Item Name and Type
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9F8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        IconData(
                          donation.iconCode ?? Icons.volunteer_activism.codePoint,
                          fontFamily: 'MaterialIcons',
                        ),
                        color: const Color(0xFF2B6C67),
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          donation.itemName ?? 'Donation Item',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          donation.itemType ?? 'Equipment',
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

              const SizedBox(height: 16),

              // Date Container
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8ECEF)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Submitted: ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      format.format(donation.submissionDate),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
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
                      icon: Icons.inventory_2,
                      label: 'Quantity',
                      value: '${donation.quantity ?? 1}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoChip(
                      icon: Icons.category,
                      label: 'Condition',
                      value: donation.condition ?? 'Good',
                    ),
                  ),
                ],
              ),

              if (donation.description != null && donation.description!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE8ECEF)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.notes,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          donation.description!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (!isHistory) ...[
                const SizedBox(height: 16),
                _buildProgressTracker(donation),
              ],
            ],
          ),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTracker(Donation donation) {
    final steps = ['Submitted', 'Under Review', 'Decision'];
    final status = donation.status.toLowerCase();
    final currentStep = status == 'pending' ? 1 : 2;

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

  List<Donation> _applyFilters(List<Donation> donations, {required bool isHistory}) {
    return donations.where((d) {
      final matchesSearch = (d.itemName?.toLowerCase().contains(_searchQuery) ?? false) ||
          (d.itemType?.toLowerCase().contains(_searchQuery) ?? false);

      final matchesStatus = _selectedStatus == "All" ||
          (d.status?.toLowerCase() == _selectedStatus.toLowerCase());

      return matchesSearch && matchesStatus;
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
                isHistory ? Icons.history : Icons.volunteer_activism_outlined,
                size: 64,
                color: const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isHistory ? "No donation history" : "No pending donations",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isHistory
                  ? "Your past donations will appear here"
                  : "Start by making a donation to help others",
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
}
