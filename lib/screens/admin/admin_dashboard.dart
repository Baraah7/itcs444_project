import 'package:cloud_firestore/cloud_firestore.dart' hide Settings;
import 'package:flutter/material.dart';
import 'package:itcs444_project/screens/admin/donation_management.dart';
import 'package:itcs444_project/screens/admin/users_managment.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import '../shared/profile_screen.dart';
import 'equipment_management.dart';
import 'add_edit_equipment.dart';
import '../admin/reservation_management.dart';
import '../shared/notifications_screen.dart';
import '../debug_rentals_screen.dart';
import '../admin/settings.dart';


class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  // Function to get total items count from Firestore
  Future<int> getTotalItemsCount() async {
  int total = 0;

  try{
    final equipmentSnapshot =
      await FirebaseFirestore.instance.collection('equipment').get();
    for (var equipmentDoc in equipmentSnapshot.docs) {
      final itemsSnapshot = await equipmentDoc.reference
          .collection('Items')
          .get();

      total += itemsSnapshot.docs.length;
    }
  } catch (e) {
    print('Error fetching total items count: $e');
  }

    return total;
  }

  // Function to get pending reservations count from Firestore
  Future<int> getPendingReservationsCount() async {
    try {
      final reservationSnapshot = await FirebaseFirestore.instance
          .collection('reservations')
          .where('status', isEqualTo: 'pending')
          .get();
      return reservationSnapshot.docs.length;
    } catch (e) {
      print('Error fetching pending reservations count: $e');
      return 0;
    }
  }

  // Function to get pending donations count from Firestore
  Future<int> getPendingDonationsCount() async {
    try {
      final donationSnapshot = await FirebaseFirestore.instance
          .collection('donations')
          .where('status', isEqualTo: 'pending')
          .get();
      return donationSnapshot.docs.length;
    } catch (e) {
      print('Error fetching pending donations count: $e');
      return 0;
    }
  }

  // Sidebar menu items
  final List<SidebarItem> _sidebarItems = [
    SidebarItem(icon: Icons.dashboard, label: 'Dashboard', index: 0),
    SidebarItem(icon: Icons.inventory, label: 'Equipment', index: 1),
    SidebarItem(icon: Icons.event_available, label: 'Reservations', index: 2),
    SidebarItem(icon: Icons.volunteer_activism, label: 'Donations', index: 3),
    SidebarItem(icon: Icons.build, label: 'Maintenance', index: 4),
    SidebarItem(icon: Icons.bar_chart, label: 'Reports', index: 5),
    SidebarItem(icon: Icons.people, label: 'Users', index: 6),
    SidebarItem(icon: Icons.settings, label: 'Settings', index: 7),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final admin = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('userId', isEqualTo: admin?.docId)
                .where('isRead', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                                     ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
                      icon: const Icon(Icons.settings_outlined, color: Color(0xFF2B6C67)),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Settings()),
                      ),
                   ),
        ],
      ),
      drawer: _buildSidebarDrawer(context, admin, auth),
      body: _getBodyForIndex(_selectedIndex, context, auth, admin),
    );
  }

  String _getTitleForIndex(int index) {
    switch (index) {
      case 0: return 'Admin Dashboard';
      case 1: return 'Equipment Management';
      case 2: return 'Reservations';
      case 3: return 'Donations';
      case 4: return 'Maintenance';
      case 5: return 'Reports';
      case 6: return 'User Management';
      case 7: return 'Settings';
      default: return 'Admin Dashboard';
    }
  }

  Widget _getBodyForIndex(int index, BuildContext context, AuthProvider auth, dynamic admin) {
    switch (index) {
      case 0: return _buildDashboardBody(context, auth, admin);
      case 1: return EquipmentPage();
      case 2: return ReservationManagementScreen();
      case 3: return DonationList();
      case 4: return _buildMaintenanceBody(context);
      case 5: return _buildReportsBody(context);
      case 6: return UsersManagement();
      case 7: return ProfileScreen();
      default: return _buildDashboardBody(context, auth, admin);
    }
  }

  Widget _buildSidebarDrawer(BuildContext context, dynamic admin, AuthProvider auth) {
    final size = MediaQuery.of(context).size;
    
    return Drawer(
      width: size.width * 0.75,
      child: Column(
        children: [
          // Drawer Header
          Container(
            height: 230,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A4A47),
                  Color(0xFF2B6C67),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white.withOpacity(0.15),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "${admin?.firstName ?? ''} ${admin?.lastName ?? ''}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    admin?.email ?? 'Admin Account',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'ADMINISTRATOR',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ..._sidebarItems.map((item) => _buildSidebarMenuItem(item)),
                const Divider(height: 20, thickness: 0.5, color: Color(0xFFE8ECEF)),
                
                // Logout Button
                ListTile(
                  leading: const Icon(
                    Icons.logout,
                    color: Color(0xFFE53935),
                  ),
                  title: Text(
                    'Logout',
                    style: TextStyle(
                      color: const Color(0xFFE53935),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () async {
                    await auth.logout();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarMenuItem(SidebarItem item) {
    return ListTile(
      leading: Icon(
        item.icon,
        color: _selectedIndex == item.index ? const Color(0xFF2B6C67) : const Color(0xFF64748B),
      ),
      title: Text(
        item.label,
        style: TextStyle(
          fontWeight: _selectedIndex == item.index ? FontWeight.w600 : FontWeight.w500,
          color: _selectedIndex == item.index ? const Color(0xFF1E293B) : const Color(0xFF475569),
        ),
      ),
      trailing: _selectedIndex == item.index
          ? Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2B6C67), Color(0xFF1A4A47)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            )
          : null,
      selected: _selectedIndex == item.index,
      selectedTileColor: const Color(0xFFF0F9F8),
      onTap: () {
        setState(() => _selectedIndex = item.index);
        Navigator.pop(context);
      },
    );
  }

  // ============ DASHBOARD BODY ============
  Widget _buildDashboardBody(BuildContext context, AuthProvider auth, dynamic admin) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Banner
            _buildWelcomeBanner(admin),
            
            const SizedBox(height: 24),

            // Admin Stats
            _buildAdminStats(context),

            const SizedBox(height: 28),

            // Quick Actions Grid
            _buildQuickActions(context),
            
            const SizedBox(height: 28),

            // Recent Activity
            _buildRecentActivity(context, title: '', status: ''),
            
            const SizedBox(height: 20),

            // GridView.count(
            //   shrinkWrap: true,
            //   physics: const NeverScrollableScrollPhysics(),
            //   crossAxisCount: 2,
            //   crossAxisSpacing: 15,
            //   mainAxisSpacing: 15,

            //   children: [
            //     _dashboardTile(
            //       icon: Icons.inventory,
            //       color: Colors.blue,
            //       label: "Equipment",
            //       onTap: () => Navigator.pushNamed(context, '/equipment-management'),
            //     ),

            //     _dashboardTile(
            //       icon: Icons.event_available,
            //       color: Colors.green,
            //       label: "Reservations",
            //       // onTap: () => Navigator.pushNamed(context, '/reservation-management'),
            //       onTap: () {
            //         Navigator.push(
            //           context, 
            //           MaterialPageRoute(builder: (_)=> const ReservationManagementScreen()));
            //       },
            //     ),

            //     _dashboardTile(
            //       icon: Icons.volunteer_activism,
            //       color: Colors.orange,
            //       label: "Donations",
            //       onTap: () => Navigator.push(
            //         context,
            //         MaterialPageRoute(
            //           builder: (context) => DonationList(),
            //         ),
            //       ),
            //     ),

            //     _dashboardTile(
            //       icon: Icons.build,
            //       color: Colors.red,
            //       label: "Maintenance",
            //       onTap: () => Navigator.pushNamed(context, '/maintenance-management'),
            //     ),

            //     _dashboardTile(
            //       icon: Icons.bar_chart,
            //       color: Colors.purple,
            //       label: "Reports",
            //       onTap: () => Navigator.pushNamed(context, '/admin-reports'),
            //     ),

            //     _dashboardTile(
            //       icon: Icons.notifications,
            //       color: Colors.teal,
            //       label: "Notifications",
            //       onTap: () => Navigator.pushNamed(context, '/notifications'),
            //     ),

            //     _dashboardTile(
            //       icon: Icons.bug_report,
            //       color: Colors.pink,
            //       label: "Debug Rentals",
            //       onTap: () => Navigator.push(
            //         context,
            //         MaterialPageRoute(builder: (_) => const DebugRentalsScreen()),
            //       ),
            //     ),
            //   ],
            // ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ================ WELCOME BANNER ================
  Widget _buildWelcomeBanner(dynamic admin) {
    final firstName = admin?.firstName ?? admin?.name ?? 'Admin';
    final greeting = _greetingText();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color.fromARGB(255, 56, 146, 137),
            Color.fromARGB(255, 122, 201, 194),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2B6C67).withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2B6C67), Color(0xFF1A4A47)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.admin_panel_settings, size: 28, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$greeting, $firstName!",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color.fromARGB(255, 240, 249, 247),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Manage equipment, users, and reservations",
                  style: TextStyle(
                    fontSize: 16,
                    color: const Color.fromARGB(255, 233, 248, 246),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _greetingText() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good morning";
    if (hour < 17) return "Good afternoon";
    return "Good evening";
  }

  // ============ ADMIN STATS ============
  Widget _buildAdminStats(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FutureBuilder<int>(
            future: getTotalItemsCount(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return _statCard(
                  icon: Icons.inventory,
                  value: "...",
                  label: "Total                 Items",
                  color: const Color(0xFF2B6C67),
                );
              }
              return _statCard(
                icon: Icons.inventory,
                value: snapshot.data.toString(),
                label: "Total                 Items",
                color: const Color(0xFF2B6C67),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FutureBuilder<int>(
            future: getPendingReservationsCount(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return _statCard(
                  icon: Icons.event_available,
                  value: "...",
                  label: "Pending Reservations",
                  color: const Color(0xFFF59E0B),
                );
              }
              return _statCard(
                icon: Icons.event_available,
                value: snapshot.data.toString(),
                label: "Pending Reservations",
                color: const Color(0xFFF59E0B),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FutureBuilder<int>(
            future: getPendingDonationsCount(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return _statCard(
                  icon: Icons.volunteer_activism,
                  value: "...",
                  label: "Pending Donations",
                  color: const Color(0xFFF59E0B),
                );
              }
              return _statCard(
                icon: Icons.volunteer_activism,
                value: snapshot.data.toString(),
                label: "Pending Donations",
                color: const Color(0xFFF59E0B),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE8ECEF),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A4A47).withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
 
  // ============ QUICK ACTIONS ============
  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Quick Actions",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _quickActionCard(
                title: "Add Equipment",
                subtitle: "Add new equipment to inventory",
                icon: Icons.add_circle_outline,
                onTap: () => _navigateToAddEquipment(),
              ),
              const SizedBox(width: 12),
              _quickActionCard(
                title: "View Reports",
                subtitle: "Analytics and insights",
                icon: Icons.bar_chart_outlined,
                onTap: () => setState(() => _selectedIndex = 5),
              ),
              const SizedBox(width: 12),
              _quickActionCard(
                title: "Manage Users",
                subtitle: "View and manage users",
                icon: Icons.people_outline,
                onTap: () => setState(() => _selectedIndex = 6),
              ),
              const SizedBox(width: 12),
              _quickActionCard(
                title: "Send Alert",
                subtitle: "Send notification to users",
                icon: Icons.notifications_active_outlined,
                onTap: () => _sendAlert(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _quickActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Function() onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A4A47).withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: const Color(0xFFF1F5F9),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2B6C67), Color(0xFF1A4A47)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context, {required String title, required String status, DateTime? date}) {
    Color badgeColor;
    String badgeText;
    
    if (status.toLowerCase() == 'approved' || status.toLowerCase() == 'completed') {
      badgeColor = const Color(0xFF10B981);
      badgeText = 'Approved';
    } else if (status.toLowerCase() == 'pending') {
      badgeColor = const Color(0xFFF59E0B);
      badgeText = 'Pending';
    } else {
      badgeColor = const Color(0xFFEF4444);
      badgeText = 'Declined';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9F8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.event_note,
              color: const Color(0xFF2B6C67),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date != null ? "${date.day}/${date.month}/${date.year}" : "",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: badgeColor.withOpacity(0.2)),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                color: badgeColor,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 0.3,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildReportsBody(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart,
            size: 80,
            color: AppColors.neutralGray.withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          Text(
            "Reports & Analytics",
            style: TextStyle(
              fontSize: 24,
              color: AppColors.neutralGray,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

    Widget _buildMaintenanceBody(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.build,
            size: 80,
            color: const Color(0xFFE8ECEF),
          ),
          const SizedBox(height: 20),
          const Text(
            "Maintenance Management",
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF475569),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Manage equipment maintenance and repairs",
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersBody(BuildContext context) {
    return const UsersManagement();
  }

  // ============ NAVIGATION METHODS ============

  void _navigateToAddEquipment() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditEquipmentPage()),
    );
  }

  void _navigateToAddUser() {
    // Implement add user navigation
  }

  void _sendAlert() {
    // Implement send alert
  }

  Widget _dashboardTile({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.neutralGray,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SidebarItem {
  final IconData icon;
  final String label;
  final int index;

  SidebarItem({required this.icon, required this.label, required this.index});
}

Future<int> getTotalItemsCount() async {
  int total = 0;

  final equipmentSnapshot =
      await FirebaseFirestore.instance.collection('equipment').get();

  for (var equipmentDoc in equipmentSnapshot.docs) {
    final itemsSnapshot = await equipmentDoc.reference
        .collection('Items')
        .get();

    total += itemsSnapshot.docs.length;
  }

  return total;
}