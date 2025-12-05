import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import '../shared/profile_screen.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  int _selectedIndex = 0;
  
  // Sidebar menu items
  final List<SidebarItem> _sidebarItems = [
    SidebarItem(icon: Icons.dashboard, label: 'Dashboard', index: 0),
    SidebarItem(icon: Icons.shopping_cart, label: 'View Cart', index: 1),
    SidebarItem(icon: Icons.history, label: 'Rental History', index: 2),
    SidebarItem(icon: Icons.help, label: 'Help & Support', index: 3),
    SidebarItem(icon: Icons.person, label: 'My Profile', index: 4),
    SidebarItem(icon: Icons.settings, label: 'Settings', index: 5),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

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
          _buildProfileButton(context, user),
        ],
      ),
      drawer: _buildSidebarDrawer(context, user, auth),
      body: _getBodyForIndex(_selectedIndex, context, auth, user),
      floatingActionButton: _selectedIndex == 0 
          ? FloatingActionButton(
              onPressed: () => _navigateToAddEquipment(),
              backgroundColor: AppColors.primaryDark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.search),
            )
          : null,
    );
  }

  String _getTitleForIndex(int index) {
    switch (index) {
      case 0: return 'Care Center';
      case 1: return 'My Cart';
      case 2: return 'Rental History';
      case 3: return 'Help & Support';
      case 4: return 'My Profile';
      case 5: return 'Settings';
      default: return 'Dashboard';
    }
  }

  Widget _getBodyForIndex(int index, BuildContext context, AuthProvider auth, dynamic user) {
    switch (index) {
      case 0: return _buildDashboardBody(context, auth, user);
      case 1: return _buildCartBody(context);
      case 2: return _buildHistoryBody(context);
      case 3: return _buildHelpBody(context);
      case 4: return ProfileScreen();
      case 5: return _buildSettingsBody(context);
      default: return _buildDashboardBody(context, auth, user);
    }
  }

  Widget _buildProfileButton(BuildContext context, dynamic user) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
        child: user?.firstName != null
            ? Text(
                user.firstName[0].toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              )
            : const Icon(
                Icons.person,
                size: 18,
                color: AppColors.primaryBlue,
              ),
      ),
    );
  }

  Widget _buildSidebarDrawer(BuildContext context, dynamic user, AuthProvider auth) {
    final size = MediaQuery.of(context).size; // Get size from context
    
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
                      Icons.person,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "${user?.firstName ?? ''} ${user?.lastName ?? ''}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'No email provided',
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
                    child: Text(
                      user?.role?.toUpperCase() ?? 'USER',
                      style: const TextStyle(
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
  Widget _buildDashboardBody(BuildContext context, AuthProvider auth, dynamic user) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Banner
            _buildWelcomeBanner(user),
            
            const SizedBox(height: 24),

            // Quick Stats
            _buildMedicalStats(context),
            
            const SizedBox(height: 28),

            // Medical Equipment Categories
            _buildMedicalCategories(context),
            
            const SizedBox(height: 28),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow("Email", user?.email),
                    _infoRow("Phone Number", user?.phoneNumber.toString()),
                    _infoRow("Username", user?.username),
                    _infoRow("Contact Preference", user?.contactPref),
                    _infoRow("CPR", user?.cpr.toString()),
                  ],
                ),
              ),
            ),

            SizedBox(height: 25),

            // ROLE BASED ACTIONS
            Text("Available Actions", 
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
            ),

            SizedBox(height: 10),

            if (auth.isAdmin || auth.isDonor)
              _actionButton(
                icon: Icons.add_business,
                label: "Add Housing / Donation",
                onPressed: () => print("Navigate to Add Housing Screen"),
              ),

            if (auth.isRenter)
              _actionButton(
                icon: Icons.home,
                label: "Browse Available Housing",
                onPressed: () => print("Navigate to Housing Listing Screen"),
              ),

            if (auth.isGuest)
              _actionButton(
                icon: Icons.info,
                label: "View Public Listings",
                onPressed: () => print("Guest Browse"),
              ),
