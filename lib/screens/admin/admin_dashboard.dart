// Overview + quick stats

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final admin = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          )
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // -------------------------------------------
            // ADMIN HEADER
            // -------------------------------------------
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.blue.shade200,
                  child: const Icon(Icons.admin_panel_settings, size: 40),
                ),
                const SizedBox(width: 16),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${admin?.firstName ?? ''} ${admin?.lastName ?? ''}",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "ADMIN",
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 25),

            // -------------------------------------------
            // QUICK ACTIONS GRID
            // -------------------------------------------
            const Text(
              "Management Sections",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
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
                  onTap: () => Navigator.pushNamed(context, '/reservation-management'),
                ),

                _dashboardTile(
                  icon: Icons.volunteer_activism,
                  color: Colors.orange,
                  label: "Donations",
                  onTap: () => Navigator.pushNamed(context, '/donation-management'),
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

  // ----------------------------------------------------
  // REUSABLE WIDGETS
  // ----------------------------------------------------

  Widget _dashboardTile({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(.15),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 42, color: color),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            "$title: ",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Expanded(
            child: Text(
              value ?? "N/A",
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
