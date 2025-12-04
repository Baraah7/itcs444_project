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
                ..._sidebarItems.map((item) => _buildSidebarMenuItem(item)).toList(),
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

            // Featured Equipment
            _buildFeaturedEquipment(context),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner(dynamic user) {
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
          const Icon(
            Icons.person,
            size: 40,
            color: Colors.white,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome, ${user?.firstName ?? 'User'}!",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalStats(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            context,
            icon: Icons.wheelchair_pickup,
            value: "42",
            label: "Mobility Aids",
            color: const Color.fromARGB(255, 255, 67, 117),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            context,
            icon: Icons.monitor_heart,
            value: "18",
            label: "Monitoring",
            color: const Color.fromARGB(255, 0, 200, 183),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            context,
            icon: Icons.medical_services,
            value: "7",
            label: "In Your Cart",
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

  Widget _buildMedicalCategories(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Browse by Category",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () => _navigateToAllCategories(),
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
        
        // Medical Equipment Categories
        SizedBox(
          height: 160,
          width: double.infinity,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _medicalCategoryCard(
                context,
                icon: Icons.wheelchair_pickup,
                label: "Mobility Aids",
                sublabel: "Wheelchairs, Walkers",
                color: const Color.fromARGB(255, 255, 67, 117),
              ),
              const SizedBox(width: 12),
              _medicalCategoryCard(
                context,
                icon: Icons.bed,
                label: "Home Care",
                sublabel: "Hospital Beds, Lifts",
                color: const Color.fromARGB(255, 0, 200, 183),
              ),
              const SizedBox(width: 12),
              _medicalCategoryCard(
                context,
                icon: Icons.monitor_heart,
                label: "Monitoring",
                sublabel: "BP Monitors, Oximeters",
                color: AppColors.warning,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _medicalCategoryCard(BuildContext context, {
    required IconData icon,
    required String label,
    required String sublabel,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () => _navigateToCategory(label),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              sublabel,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.neutralGray,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedEquipment(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Featured Equipment",
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        // Featured Medical Equipment
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8,
          children: [
            _medicalEquipmentCard(
              context,
              name: "Electric Wheelchair",
              category: "Mobility Aid",
              price: " BD 85/week",
              imageColor: Color.fromARGB(255, 255, 67, 117).withOpacity(0.1),
            ),
            _medicalEquipmentCard(
              context,
              name: "Hospital Bed",
              category: "Home Care",
              price: " BD 120/week",
              imageColor: Color.fromARGB(255, 0, 200, 183).withOpacity(0.1),
            ),
            _medicalEquipmentCard(
              context,
              name: "Hearing Aid Set",
              category: "Sensory Aid",
              price: " BD 45/week",
              imageColor: AppColors.warning.withOpacity(0.1),
            ),
            _medicalEquipmentCard(
              context,
              name: "BP Monitor",
              category: "Monitoring",
              price: " BD 25/week",
              imageColor: Color.fromARGB(255, 0, 200, 183).withOpacity(0.1),
            ),
          ],
        ),
      ],
    );
  }

Widget _medicalEquipmentCard(BuildContext context, {
  required String name,
  required String category,
  required String price,
  required Color imageColor,
}) {
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    child: ConstrainedBox(
      constraints: const BoxConstraints(
        maxHeight: 200, // Fixed maximum height
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image placeholder - Fixed height
            Container(
              height: 100, // Reduced from 100
              width: double.infinity,
              decoration: BoxDecoration(
                color: imageColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.medical_services,
                size: 30,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10), // Reduced
            
            // Name - with flexible text
            Flexible(
              child: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12, // Smaller
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            const SizedBox(height: 2), // Reduced
            
            // Category
            Text(
              category,
              style: TextStyle(
                fontSize: 10, // Smaller
                color: AppColors.neutralGray,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            
            const Spacer(),
            
            // Bottom row
            SizedBox(
              height: 20, // Fixed height
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    price,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _addToCart(name),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.add_shopping_cart,
                        size: 14,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  // ============ CART BODY ============
  Widget _buildCartBody(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: AppColors.neutralGray.withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          Text(
            "Your cart is empty",
            style: TextStyle(
              fontSize: 18,
              color: AppColors.neutralGray,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Browse medical equipment and add items to cart",
            style: TextStyle(
              color: AppColors.neutralGray,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => setState(() => _selectedIndex = 0),
            child: const Text("Browse Equipment"),
          ),
        ],
      ),
    );
  }

  // ============ HISTORY BODY ============
  Widget _buildHistoryBody(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_outlined,
            size: 80,
            color: AppColors.neutralGray.withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          Text(
            "No rental history",
            style: TextStyle(
              fontSize: 18,
              color: AppColors.neutralGray,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Your past rentals will appear here",
            style: TextStyle(
              color: AppColors.neutralGray,
            ),
          ),
        ],
      ),
    );
  }


  // ============ HELP BODY ============
  Widget _buildHelpBody(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Help & Support",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          
          _helpSection(
            icon: Icons.phone,
            title: "24/7 Support Line",
            subtitle: "Call us anytime at 1-800-MED-HELP",
            onTap: () => _callSupport(),
          ),
          _helpSection(
            icon: Icons.email,
            title: "Email Support",
            subtitle: "support@medequipment.com",
            onTap: () => _emailSupport(),
          ),
          _helpSection(
            icon: Icons.question_answer,
            title: "FAQ",
            subtitle: "Frequently asked questions",
            onTap: () => _openFAQ(),
          ),
          _helpSection(
            icon: Icons.book,
            title: "User Guides",
            subtitle: "Equipment usage instructions",
            onTap: () => _openGuides(),
          ),
        ],
      ),
    );
  }

  Widget _helpSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryBlue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }


  // ============ SETTINGS BODY ============
  Widget _buildSettingsBody(BuildContext context) {
    return Center(
      child: Text(
        "Settings",
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    );
  }

  // ============ NAVIGATION METHODS ============
  void _navigateToNotifications() {
    // Implement notifications navigation
  }

  void _navigateToAddEquipment() {
    // Implement add equipment navigation
  }

  void _navigateToAllCategories() {
    // Implement categories navigation
  }

  void _navigateToCategory(String category) {
    // Implement category navigation
  }

  void _addToCart(String itemName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $itemName to cart'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _callSupport() {
    // Implement call support
  }

  void _emailSupport() {
    // Implement email support
  }

  void _openFAQ() {
    // Implement FAQ
  }

  void _openGuides() {
    // Implement guides
  }

}

class SidebarItem {
  final IconData icon;
  final String label;
  final int index;

  SidebarItem({required this.icon, required this.label, required this.index});
}