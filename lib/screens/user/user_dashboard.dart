import 'package:cloud_firestore/cloud_firestore.dart' hide Settings;
import 'package:flutter/material.dart';
import 'package:itcs444_project/screens/shared/donation_form.dart';
import 'package:itcs444_project/screens/user/donation_history.dart';
import 'package:itcs444_project/screens/user/equipment_list.dart';
import 'package:itcs444_project/screens/user/my_reservations.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../shared/notifications_screen.dart';
import 'settings.dart';
import 'equipment_detail.dart';

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
    SidebarItem(icon: Icons.event_available, label: 'Equipment', index: 1),
    SidebarItem(icon: Icons.shopping_cart, label: 'Reservations', index: 2),
    SidebarItem(icon: Icons.favorite_border, label: 'Donations', index: 3),
    SidebarItem(icon: Icons.settings, label: 'Settings', index: 4),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.white,

        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('userId', isEqualTo: user?.docId)
                .where('isRead', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Color(0xFF2B6C67)),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
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
      drawer: _buildSidebarDrawer(context, user, auth),
      body: _getBodyForIndex(_selectedIndex, context, auth, user),
    );
  }

  Widget _getBodyForIndex(int index, BuildContext context, AuthProvider auth, dynamic user) {
    switch (index) {
      case 0: return _buildDashboardBody(context, auth, user);
      case 1: return UserEquipmentPage();
      case 2: return MyReservationsScreen();
      case 3: return DonationHistory();
      case 4: return Settings();
      default: return _buildDashboardBody(context, auth, user);
    }
  }

  Widget _buildSidebarDrawer(BuildContext context, dynamic user, AuthProvider auth) {
    final size = MediaQuery.of(context).size;

    return Drawer(
      width: size.width * 0.75,
      child: Column(
        children: [
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
                    child: const Icon(Icons.person, size: 48, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "${user?.firstName ?? ''} ${user?.lastName ?? ''}",
                    style: const TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.w600, 
                        color: Colors.white,
                        letterSpacing: 0.2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'No email provided',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
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

          // Menu items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ..._sidebarItems.map((item) => _buildSidebarMenuItem(item)),
                const Divider(height: 20, thickness: 0.5, color: Color(0xFFE8ECEF)),

                ListTile(
                  leading: const Icon(Icons.logout, color: Color(0xFFE53935)),
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
        color:
            _selectedIndex == item.index ? const Color(0xFF2B6C67) : const Color(0xFF64748B),
      ),
      title: Text(
        item.label,
        style: TextStyle(
          fontWeight:
              _selectedIndex == item.index ? FontWeight.w600 : FontWeight.w500,
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

  // ------------------- DASHBOARD BODY -------------------
  Widget _buildDashboardBody(BuildContext context, AuthProvider auth, dynamic user) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeBanner(user),

            const SizedBox(height: 24),

            _buildRecentActivity(user),

            const SizedBox(height: 24),

            _buildQuickActionsRow(context),

            const SizedBox(height: 24),

            _buildFeaturedEquipment(context),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ------------------- WELCOME BANNER -------------------
  Widget _buildWelcomeBanner(dynamic user) {
    final firstName = user?.firstName ?? user?.name ?? 'User';
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
            child: const Icon(Icons.person, size: 28, color: Colors.white),
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
                  "Welcome back to Care Center App",
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

  // ----------------- Recent Activities -----------------
// ----------------- FIXED Recent Activities -----------------
  Widget _buildRecentActivity(dynamic user) {
    final userId = user?.docId;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Recent Activity",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE8ECEF),
            ),
          ),
          child: Column(
            children: [
              // Reservations Section
              _buildActivitySection(
                title: "Reservations",
                userId: userId,
                collection: 'reservations',
                icon: Icons.event_available,
                emptyMessage: "No reservations",
              ),
              
              const SizedBox(height: 20),
              
              // Divider
              const Divider(height: 1, color: Color(0xFFE8ECEF)),
              
              const SizedBox(height: 20),
              
              // Donations Section
              _buildActivitySection(
                title: "Donations",
                userId: userId,
                collection: 'donations',
                icon: Icons.volunteer_activism,
                emptyMessage: "No donations",
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivitySection({
    required String title,
    required String? userId,
    required String collection,
    required IconData icon,
    required String emptyMessage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF2B6C67)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection(collection)
              .where('userId', isEqualTo: userId)
              .orderBy('createdAt', descending: true)
              .limit(3)
              .snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 80,
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF2B6C67)),
                ),
              );
            }
            
            final docs = snap.data?.docs ?? [];
            
            if (docs.isEmpty) {
              return _smallEmptyCard(emptyMessage);
            }
            
            return Column(
              children: docs.map((d) {
                final data = d.data() as Map<String, dynamic>;
                final title = data['equipmentName'] ?? 
                             (collection == 'donations' ? 'Donation' : 'Equipment');
                final status = (data['status'] ?? 'pending').toString();
                final date = (data['createdAt'] is Timestamp)
                    ? (data['createdAt'] as Timestamp).toDate()
                    : null;
                
                return _compactActivityRow(
                  title: title, 
                  status: status, 
                  date: date,
                  type: collection,
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _smallEmptyCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8ECEF)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, color: const Color(0xFF94A3B8), size: 20),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactActivityRow({
    required String title, 
    required String status, 
    DateTime? date,
    required String type,
  }) {
    Color badgeColor;
    String badgeText;
    IconData statusIcon;
    
    if (status.toLowerCase() == 'approved' || status.toLowerCase() == 'completed') {
      badgeColor = const Color(0xFF10B981);
      badgeText = 'Approved';
      statusIcon = Icons.check_circle;
    } else if (status.toLowerCase() == 'pending') {
      badgeColor = const Color(0xFFF59E0B);
      badgeText = 'Pending';
      statusIcon = Icons.schedule;
    } else if (status.toLowerCase() == 'rejected') {
      badgeColor = const Color(0xFFEF4444);
      badgeText = 'Rejected';
      statusIcon = Icons.cancel;
    } else if (status.toLowerCase() == 'cancelled') {
      badgeColor = const Color(0xFF64748B);
      badgeText = 'Cancelled';
      statusIcon = Icons.cancel_outlined;
    } else {
      badgeColor = const Color(0xFF64748B);
      badgeText = status.substring(0, 1).toUpperCase() + status.substring(1);
      statusIcon = Icons.info_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
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
      child: Row(
        children: [
          // Icon Container
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
            child: Icon(
              type == 'donations' ? Icons.volunteer_activism : Icons.event_note,
              color: const Color(0xFF2B6C67),
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Text Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      date != null ? _formatDate(date) : "N/A",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: badgeColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  statusIcon,
                  size: 12,
                  color: badgeColor,
                ),
                const SizedBox(width: 4),
                Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to format dates
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return "Just now";
        }
        return "${difference.inMinutes}m ago";
      }
      return "${difference.inHours}h ago";
    } else if (difference.inDays == 1) {
      return "Yesterday";
    } else if (difference.inDays < 7) {
      return "${difference.inDays}d ago";
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return "${weeks}w ago";
    } else {
      return "${date.day}/${date.month}/${date.year}";
    }
  }

  // ------------------- QUICK ACTIONS -------------------
  Widget _buildQuickActionsRow(dynamic user) {
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
                title: "Make Donation",
                subtitle: "Give equipment quickly",
                icon: Icons.volunteer_activism_outlined,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => DonationForm()));
                },
              ),
              const SizedBox(width: 12),
              _quickActionCard(
                title: "New Reservation",
                subtitle: "Reserve equipment",
                icon: Icons.event_available_outlined,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => UserEquipmentPage()));
                },
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ],
    );
  }

  Widget _quickActionCard({required String title, required String subtitle, required IconData icon, required Function() onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 255, 255, 255),
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

  // ------------------- FEATURED EQUIPMENT -------------------
  Widget _buildFeaturedEquipment(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('equipment').limit(4).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF2B6C67)));

        final equipmentDocs = snapshot.data!.docs;

        if (equipmentDocs.isEmpty) {
          return const Center(child: Text("No equipment found"));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Featured Equipment",
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                        letterSpacing: -0.3,
                      ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UserEquipmentPage()),
                  ),
                  child: const Row(
                    children: [
                      Text(
                        "View All",
                        style: TextStyle(
                            color: Color(0xFF2B6C67),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            letterSpacing: -0.1),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios,
                          size: 14, color: Color(0xFF2B6C67)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: equipmentDocs.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.65,
              ),
              itemBuilder: (context, index) {
                final doc = equipmentDocs[index];
                final equipment = doc.data();

                return _medicalEquipmentCard(
                  context,
                  id: doc.id,
                  name: equipment['name'] ?? "Unknown",
                  category: equipment['type'] ?? "n/a",
                  imageColor: const Color(0xFF2B6C67).withOpacity(0.1),
                );
              },
            )
          ],
        );
      },
    );
  }

  Widget _medicalEquipmentCard(
    BuildContext context, {
    required String id,
    required String name,
    required String category,
    required Color imageColor,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('equipment')
          .doc(id)
          .collection('Items')
          .where('availability', isEqualTo: true)
          .limit(1)
          .snapshots(),
      builder: (context, itemsSnapshot) {
        bool isAvailable = false;
        int availableCount = 0;

        if (itemsSnapshot.hasData && itemsSnapshot.data!.docs.isNotEmpty) {
          isAvailable = true;
          availableCount = itemsSnapshot.data!.docs.length;
        }

        return GestureDetector(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF1A4A47).withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8))
              ],
              border: Border.all(
                color: const Color(0xFFE8ECEF), 
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        height: 110,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF2B6C67).withOpacity(0.15),
                              const Color(0xFF1A4A47).withOpacity(0.08),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.medical_services,
                            size: 42, 
                            color: const Color(0xFF2B6C67).withOpacity(0.7),
                          ),
                        ),
                      ),

                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isAvailable
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isAvailable
                                ? (availableCount > 1
                                    ? "$availableCount Available"
                                    : "Available")
                                : "Out of Stock",
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                      letterSpacing: -0.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 14, 
                        color: const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          category,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EquipmentDetailPage(equipmentId: id),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.visibility, size: 16, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            "View Details",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ------------------- HISTORY -------------------
  Widget _buildHistoryBody(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final userId = auth.currentUser?.docId;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rentals')
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: ['returned', 'cancelled'])
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF2B6C67)));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_outlined, size: 80, color: const Color(0xFFE8ECEF)),
                const SizedBox(height: 20),
                Text(
                  "No rental history",
                  style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Text(
                  "Your past rentals will appear here",
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final equipmentName = data['equipmentName'] ?? 'Equipment';
            final status = data['status'] ?? '';
            final startDate = data['startDate'] != null ? DateTime.parse(data['startDate']) : null;
            final endDate = data['endDate'] != null ? DateTime.parse(data['endDate']) : null;
            final totalCost = data['totalCost'] ?? 0.0;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: status == 'returned' 
                      ? const Color(0xFF10B981).withOpacity(0.1)
                      : const Color(0xFFEF4444).withOpacity(0.1),
                  child: Icon(
                    status == 'returned' ? Icons.check_circle : Icons.cancel,
                    color: status == 'returned' ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                ),
                title: Text(
                  equipmentName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (startDate != null && endDate != null)
                      Text('${startDate.day}/${startDate.month}/${startDate.year} - ${endDate.day}/${endDate.month}/${endDate.year}'),
                    Text('Total: \$${totalCost.toStringAsFixed(2)}'),
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: status == 'returned' 
                        ? const Color(0xFF10B981).withOpacity(0.1)
                        : const Color(0xFFEF4444).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status == 'returned' ? 'Returned' : 'Cancelled',
                    style: TextStyle(
                      color: status == 'returned' ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class SidebarItem {
  final IconData icon;
  final String label;
  final int index;

  SidebarItem({required this.icon, required this.label, required this.index});
}