import 'package:flutter/material.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
      ),

      // ---------------------------
      // Navigation Drawer
      // ---------------------------
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: const [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                "Admin Menu",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            ListTile(leading: Icon(Icons.inventory), title: Text("Inventory")),
            ListTile(leading: Icon(Icons.volunteer_activism), title: Text("Donations")),
            ListTile(leading: Icon(Icons.people), title: Text("Users")),
            ListTile(leading: Icon(Icons.list_alt), title: Text("Requests")),
            ListTile(leading: Icon(Icons.analytics), title: Text("Analytics")),
          ],
        ),
      ),

      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWide = constraints.maxWidth > 700;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ---------------------------
                // Stats Cards
                // ---------------------------
                Text("Overview", style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),

                GridView.count(
                  crossAxisCount: isWide ? 4 : 2,
                  shrinkWrap: true,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStatCard(
                      "Total Equipment",
                      "120",
                      Icons.medical_services,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      "Active Rentals",
                      "35",
                      Icons.shopping_cart_checkout,
                      Colors.green,
                    ),
                    _buildStatCard(
                      "Pending Donations",
                      "12",
                      Icons.volunteer_activism,
                      Colors.orange,
                    ),
                    _buildStatCard(
                      "Overdue Items",
                      "7",
                      Icons.warning,
                      Colors.red,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ---------------------------
                // Quick Action Buttons
                // ---------------------------
                Text("Quick Actions", style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add),
                      label: const Text("Add Equipment"),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.check),
                      label: const Text("Approve Donations"),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.person_add),
                      label: const Text("Add User"),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // ---------------------------
                // Recent Activity List
                // ---------------------------
                Text("Recent Activity", style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),

                Card(
                  child: ListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: const [
                      ListTile(
                        leading: Icon(Icons.receipt),
                        title: Text("Wheelchair rented by Ali Ahmed"),
                        subtitle: Text("2 hours ago"),
                      ),
                      ListTile(
                        leading: Icon(Icons.volunteer_activism),
                        title: Text("Donation pending: Walker from Sara"),
                        subtitle: Text("5 hours ago"),
                      ),
                      ListTile(
                        leading: Icon(Icons.warning),
                        title: Text("Overdue: Crutches rental expired"),
                        subtitle: Text("1 day ago"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ------------------------------------
  // STAT CARD WIDGET
  // ------------------------------------
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(title, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
