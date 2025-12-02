//Browse equipment + quick actions

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class UserDashboard extends StatelessWidget {
  const UserDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text("User Dashboard"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(20.0),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // USER HEADER
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.blue.shade200,
                  child: Icon(Icons.person, size: 40),
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${user?.firstName ?? ''} ${user?.lastName ?? ''}",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      user?.role.toUpperCase() ?? '',
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                  ],
                )
              ],
            ),

            SizedBox(height: 30),

            // USER INFO CARD
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow("Email", user?.email),
                    _infoRow("Phone Number", user?.phoneNumber?.toString()),
                    _infoRow("Username", user?.username),
                    _infoRow("Contact Preference", user?.contactPref),
                    _infoRow("CPR", user?.cpr?.toString()),
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
          ],
        ),
      ),
    );
  }

  // ------------------------------------------
  // REUSABLE WIDGETS
  // ------------------------------------------

  Widget _infoRow(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            "$title: ",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Expanded(
            child: Text(
              value ?? "N/A",
              style: TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({required IconData icon, required String label, required VoidCallback onPressed}) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: Icon(icon, size: 22),
        label: Text(label, style: TextStyle(fontSize: 18)),
        onPressed: onPressed,
      ),
    );
  }
}
