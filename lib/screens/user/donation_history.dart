import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
  List<String> filterOptions = ['All', 'Pending', 'Approved', 'Rejected'];
  String selectedFilter = 'All';
  final user = FirebaseAuth.instance.currentUser;
  late final uid = user?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Donation History',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xFFE8ECEF),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2B6C67),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DonationForm()),
                );
              },
              icon: const Icon(
                Icons.add,
                color: Colors.white,
                size: 22,
              ),
              tooltip: 'Make New Donation',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE8F4F3),
                  Color(0xFFF0F9F8),
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFE8ECEF),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Donations',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Thank you for your generous contributions to Care Center',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),

                // Filter Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedFilter == 'All'
                          ? 'All Donations'
                          : '$selectedFilter Donations',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),

                    // Filter Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE8ECEF),
                          width: 1,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedFilter,
                          icon: const Icon(
                            Icons.filter_list_rounded,
                            color: Color(0xFF64748B),
                          ),
                          style: const TextStyle(
                            color: Color(0xFF1E293B),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          dropdownColor: Colors.white,
                          items: filterOptions.map((String value) {
                            IconData icon;
                            Color color;

                            switch (value) {
                              case 'All':
                                icon = Icons.all_inclusive;
                                color = const Color(0xFF64748B);
                                break;
                              case 'Pending':
                                icon = Icons.access_time;
                                color = const Color(0xFFF59E0B);
                                break;
                              case 'Approved':
                                icon = Icons.check_circle;
                                color = const Color(0xFF10B981);
                                break;
                              case 'Rejected':
                                icon = Icons.cancel;
                                color = const Color(0xFFEF4444);
                                break;

                              default:
                                icon = Icons.category;
                                color = const Color(0xFF64748B);
                            }

                            return DropdownMenuItem<String>(
                              value: value,
                              child: Row(
                                children: [
                                  Icon(
                                    icon,
                                    color: color,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(value),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (String? value) {
                            setState(() {
                              selectedFilter = value!;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Donations List
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FutureBuilder<List<Donation>>(
                future: DonationService().fetchDonationsByUserId(user!.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Color(0xFF2B6C67),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Loading donations...',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F9F8),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: const Icon(
                              Icons.error_outline,
                              size: 40,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Error loading donations',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF475569),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Please try again later',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F9F8),
                              borderRadius: BorderRadius.circular(60),
                            ),
                            child: const Icon(
                              Icons.volunteer_activism_outlined,
                              size: 60,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'No Donations Yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              'Start making a difference by donating equipment to those in need',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748B),
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const DonationForm(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add, size: 20),
                            label: const Text(
                              'Make Your First Donation',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2B6C67),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              shadowColor:
                                  const Color(0xFF2B6C67).withOpacity(0.3),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final allDonations = snapshot.data!;

                  // Apply filter
                  final donations = selectedFilter == 'All'
                      ? allDonations
                      : allDonations
                          .where((d) =>
                              d.status.toLowerCase() ==
                              selectedFilter.toLowerCase())
                          .toList();

                  if (donations.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F9F8),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: const Icon(
                              Icons.filter_alt_off,
                              size: 50,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'No Matching Donations',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Try changing your filter to see other donations',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Sort by date (newest first)
                  donations.sort((a, b) {
                    return b.submissionDate.compareTo(a.submissionDate);
                  });

                  return ListView.builder(
                    itemCount: donations.length,
                    itemBuilder: (context, index) {
                      final donation = donations[index];
                      final status = donation.status.toLowerCase();

                      // Status colors
                      Color statusColor;
                      Color statusBgColor;
                      IconData statusIcon;

                      switch (status) {
                        case 'pending':
                          statusColor = const Color(0xFFF59E0B);
                          statusBgColor = const Color(0xFFFEF3C7);
                          statusIcon = Icons.access_time;
                          break;
                        case 'approved':
                          statusColor = const Color(0xFF10B981);
                          statusBgColor = const Color(0xFFD1FAE5);
                          statusIcon = Icons.check_circle;
                          break;
                        case 'rejected':
                          statusColor = const Color(0xFFEF4444);
                          statusBgColor = const Color(0xFFFEE2E2);
                          statusIcon = Icons.cancel;
                          break;
                        case 'completed':
                          statusColor = const Color(0xFF2B6C67);
                          statusBgColor = const Color(0xFFE8F4F3);
                          statusIcon = Icons.done_all;
                          break;
                        default:
                          statusColor = const Color(0xFF64748B);
                          statusBgColor = const Color(0xFFF1F5F9);
                          statusIcon = Icons.help_outline;
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(
                            color: Color(0xFFF1F5F9),
                            width: 1,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserDonationDetails(
                                    donationID: donation.id!),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Donation Icon
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0F9F8),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      IconData(
                                        donation.iconCode ??
                                            Icons.volunteer_activism.codePoint,
                                        fontFamily: 'MaterialIcons',
                                      ),
                                      color: const Color(0xFF2B6C67),
                                      size: 26,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 16),

                                // Donation Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              donation.itemType ??
                                                  'Equipment Donation',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF1E293B),
                                                letterSpacing: -0.1,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: statusBgColor,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: statusColor
                                                    .withOpacity(0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  statusIcon,
                                                  size: 12,
                                                  color: statusColor,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  donation.status,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: statusColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        donation.donorName ?? 'Anonymous Donor',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF475569),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.calendar_today,
                                            size: 14,
                                            color: Color(0xFF64748B),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            _formatDate(
                                                donation.submissionDate),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (donation.description != null &&
                                          donation.description!.isNotEmpty)
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 8),
                                            Text(
                                              donation.description!.length > 40
                                                  ? '${donation.description!.substring(0, 40)}...'
                                                  : donation.description!,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFF64748B),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // View Details Arrow
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
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Date not available';

    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
