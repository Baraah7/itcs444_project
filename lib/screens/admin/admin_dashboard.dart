import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import '../shared/profile_screen.dart';
import 'equipment_management.dart';
import 'add_edit_equipment.dart';
import '../admin/reservation_management.dart'; //NEW added by Wadeeah (task3)


class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  Future<int> getTotalItemsCount() async {
  int total = 0;

  final equipmentSnapshot =
      await FirebaseFirestore.instance.collection('equipment').get();

  for (var equipmentDoc in equipmentSnapshot.docs) {
    final itemsSnapshot = await equipmentDoc.reference
        .collection('Items') // ✅ اسم السبكوليكشن الصحيح
        .get();

    total += itemsSnapshot.docs.length;
  }

    return total;
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
        title: Text(
          _getTitleForIndex(_selectedIndex),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => _navigateToNotifications(),
          ),
          _buildProfileButton(context, admin),
        ],
      ),
      drawer: _buildSidebarDrawer(context, admin, auth),
      body: _getBodyForIndex(_selectedIndex, context, auth, admin),
      // floatingActionButton: _selectedIndex == 0 
      //     ? FloatingActionButton(
      //         onPressed: () => _navigateToAddEquipment(),
      //         backgroundColor: AppColors.primaryDark,
      //         foregroundColor: Colors.white,
      //         shape: RoundedRectangleBorder(
      //           borderRadius: BorderRadius.circular(16),
      //         ),
      //         child: const Icon(Icons.add),
      //       )
      //     : null,
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
      case 1: return _buildEquipmentBody(context);
      case 2: return _buildReservationsBody(context);
      case 3: return _buildDonationsBody(context);
      case 4: return _buildMaintenanceBody(context);
      case 5: return _buildReportsBody(context);
      case 6: return _buildUsersBody(context);
      case 7: return ProfileScreen();
      default: return _buildDashboardBody(context, auth, admin);
    }
  }

  Widget _buildProfileButton(BuildContext context, dynamic admin) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
        child: admin?.firstName != null
            ? Text(
                admin.firstName[0].toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              )
            : const Icon(
                Icons.admin_panel_settings,
                size: 18,
                color: AppColors.primaryBlue,
              ),
      ),
    );
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
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppColors.primaryBlue,
                  AppColors.primaryBlue.withOpacity(0.8),
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
                    backgroundColor: Colors.white.withOpacity(0.2),
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
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    admin?.email ?? 'Admin Account',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
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
                const Divider(height: 20),
                
                // Logout Button
                ListTile(
                  leading: Icon(
                    Icons.logout,
                    color: AppColors.error,
                  ),
                  title: Text(
                    'Logout',
                    style: TextStyle(
                      color: AppColors.error,
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
        color: _selectedIndex == item.index ? AppColors.primaryBlue : AppColors.neutralGray,
      ),
      title: Text(
        item.label,
        style: TextStyle(
          fontWeight: _selectedIndex == item.index ? FontWeight.w600 : FontWeight.normal,
          color: _selectedIndex == item.index ? AppColors.primaryDark : AppColors.primaryDark,
        ),
      ),
      trailing: _selectedIndex == item.index
          ? Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(2),
              ),
            )
          : null,
      selected: _selectedIndex == item.index,
      selectedTileColor: AppColors.primaryBlue.withOpacity(0.1),
      onTap: () {
        setState(() => _selectedIndex = item.index);
        Navigator.pop(context); // Close drawer
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

            // Quick Stats
            _buildAdminStats(context),
            
            const SizedBox(height: 28),

            // Quick Actions Grid
            _buildQuickActions(context),
            
            const SizedBox(height: 28),

            // Recent Activity
            _buildRecentActivity(context),
            
            const SizedBox(height: 20),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,

              children: [
                _dashboardTile(
                  icon: Icons.inventory,
                  color: Colors.blue,
                  label: "Equipment",
                  onTap: () => Navigator.pushNamed(context, '/equipment-management'),
                ),

                _dashboardTile(
                  icon: Icons.event_available,
                  color: Colors.green,
                  label: "Reservations",
                  // onTap: () => Navigator.pushNamed(context, '/reservation-management'),
                  onTap: () {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (_)=> const ReservationManagementScreen()));
                  },
                ),

                _dashboardTile(
                  icon: Icons.volunteer_activism,
                  color: Colors.orange,
                  label: "Donations",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DonationList(),
                    ),
                  ),
                ),

                _dashboardTile(
                  icon: Icons.build,
                  color: Colors.red,
                  label: "Maintenance",
                  onTap: () => Navigator.pushNamed(context, '/maintenance-management'),
                ),

                _dashboardTile(
                  icon: Icons.bar_chart,
                  color: Colors.purple,
                  label: "Reports",
                  onTap: () => Navigator.pushNamed(context, '/admin-reports'),
                ),

                _dashboardTile(
                  icon: Icons.notifications,
                  color: Colors.teal,
                  label: "Notifications",
                  onTap: () => Navigator.pushNamed(context, '/notifications'),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // -------------------------------------------
            // ADMIN INFO CARD
            // -------------------------------------------
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow("Email", admin?.email),
                    _infoRow("Username", admin?.username),
                    _infoRow("Phone Number", admin?.phoneNumber.toString()),
                    _infoRow("CPR", admin?.cpr.toString()),
                    _infoRow("Contact Preference", admin?.contactPref),
                  ],
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner(dynamic admin) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.primaryDark,
            AppColors.primaryBlue.withOpacity(0.9),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome, Admin ${admin?.firstName ?? ''}!",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Manage equipment, users, and reservations",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAdminStats(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FutureBuilder<int>(
            future: getTotalItemsCount(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return _statCard(
                  context,
                  icon: Icons.inventory,
                  value: "...",
                  label: "Total Items",
                  color: const Color.fromARGB(255, 0, 200, 183),
                );
             }

           return _statCard(
              context,
              icon: Icons.inventory,
              value: snapshot.data.toString(),
              label: "Total Items",
              color: const Color.fromARGB(255, 0, 200, 183),
            );
          },
        ),
      ),

      const SizedBox(width: 12),

        Expanded(
          child: _statCard(
            context,
            icon: Icons.event_available,
            value: "38",
            label: "Active Reservations",
            color: AppColors.success,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _statCard(
            context,
            icon: Icons.people,
            value: "127",
            label: "Total Users",
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }

  Widget _statCard(BuildContext context, {
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.neutralGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Quick Actions",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _actionCard(
              context,
              icon: Icons.add_circle,
              label: "Add Equipment",
              color: AppColors.success,
              onTap: () => _navigateToAddEquipment(),
            ),
            _actionCard(
              context,
              icon: Icons.person_add,
              label: "Add User",
              color: AppColors.info,
              onTap: () => _navigateToAddUser(),
            ),
            _actionCard(
              context,
              icon: Icons.bar_chart,
              label: "View Reports",
              color: AppColors.warning,
              onTap: () => setState(() => _selectedIndex = 5),
            ),
            _actionCard(
              context,
              icon: Icons.notifications_active,
              label: "Send Alert",
              color: const Color.fromARGB(255, 255, 67, 117),
              onTap: () => _sendAlert(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionCard(BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
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

  Widget _buildRecentActivity(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Recent Activity",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _selectedIndex = 2),
              child: const Row(
                children: [
                  Text(
                    "View All",
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: AppColors.primaryBlue,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _activityItem(
                  icon: Icons.event_available,
                  title: "New Reservation",
                  subtitle: "Wheelchair #A102 rented",
                  time: "2 hours ago",
                  color: AppColors.success,
                ),
                const Divider(),
                _activityItem(
                  icon: Icons.person_add,
                  title: "New User Registered",
                  subtitle: "John Doe joined the platform",
                  time: "4 hours ago",
                  color: AppColors.info,
                ),
                const Divider(),
                _activityItem(
                  icon: Icons.build,
                  title: "Maintenance Request",
                  subtitle: "Hospital bed #B205 needs service",
                  time: "1 day ago",
                  color: AppColors.warning,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _activityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.primaryDark,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppColors.neutralGray,
        ),
      ),
      trailing: Text(
        time,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.neutralGray,
        ),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  // ============ OTHER SECTION BODIES ============
  Widget _buildEquipmentBody(BuildContext context) {
    return EquipmentPage();
  }

  Widget _buildReservationsBody(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: 80,
            color: AppColors.neutralGray.withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          Text(
            "Reservation Management",
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

  Widget _buildDonationsBody(BuildContext context) {
    return DonationList();
  }

  Widget _buildMaintenanceBody(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.build,
            size: 80,
            color: AppColors.neutralGray.withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          Text(
            "Maintenance Management",
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

  Widget _buildUsersBody(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people,
            size: 80,
            color: AppColors.neutralGray.withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          Text(
            "User Management",
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

  // ============ NAVIGATION METHODS ============
  void _navigateToNotifications() {
    // Implement notifications navigation
  }

  void _navigateToAddEquipment() {
    // Implement add equipment navigation
   Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditEquipmentPage(),
      ),
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