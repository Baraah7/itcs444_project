import 'package:flutter/material.dart';

class UserTrackingPage extends StatefulWidget {
  const UserTrackingPage({super.key});

  @override
  State<UserTrackingPage> createState() => _UserTrackingPageState();
}

class _UserTrackingPageState extends State<UserTrackingPage> {
  TextEditingController searchController = TextEditingController();

  // Dummy Users List (Replace with Firestore Query)
  // TODO: Firestore -> Load users + their rental data
  List<Map<String, dynamic>> users = [
    {
      "name": "Ali Hassan",
      "contact": "+973 3999 5522",
      "memberSince": "2022",
      "trustScore": 92,
      "rentals": [
        {"item": "Wheelchair", "status": "active", "date": "2025-01-10"},
        {"item": "Walker", "status": "returned", "date": "2024-10-02"},
      ]
    },
    {
      "name": "Fatima Ahmed",
      "contact": "+973 3366 2211",
      "memberSince": "2023",
      "trustScore": 75,
      "rentals": [
        {"item": "Crutches", "status": "overdue", "date": "2025-01-01"},
      ]
    },
  ];

  String searchQuery = "";

  Color getStatusColor(String status) {
    switch (status) {
      case "active":
        return Colors.blue;
      case "overdue":
        return Colors.red;
      case "returned":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = users
        .where((u) =>
            u["name"].toLowerCase().contains(searchQuery.toLowerCase()) ||
            u["contact"].contains(searchQuery))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("User Tracking"),
      ),
      body: Column(
        children: [
          // 🔍 Search Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search users...",
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (val) {
                setState(() => searchQuery = val);
              },
            ),
          ),

          // 📌 User List
          Expanded(
            child: ListView.builder(
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final user = filteredUsers[index];

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ExpansionTile(
                    title: Text(user["name"],
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text("${user["contact"]} • Member since ${user["memberSince"]}"),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Trust Score: ${user["trustScore"]}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            const Icon(Icons.verified, color: Colors.green),
                          ],
                        ),
                      ),

                      // Rental History Section
                      const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Text("Rental History:",
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold)),
                      ),

                      Column(
                        children: List.generate(user["rentals"].length, (r) {
                          final rental = user["rentals"][r];

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  getStatusColor(rental["status"]).withOpacity(0.2),
                              child: Icon(Icons.medical_services,
                                  color: getStatusColor(rental["status"])),
                            ),
                            title: Text(rental["item"]),
                            subtitle: Text("Date: ${rental["date"]}"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Send Reminder
                                if (rental["status"] == "overdue")
                                  IconButton(
                                    icon: const Icon(Icons.notification_important,
                                        color: Colors.red),
                                    onPressed: () {
                                      // TODO: Firestore -> send reminder
                                    },
                                  ),

                                // Extend
                                if (rental["status"] == "active")
                                  IconButton(
                                    icon: const Icon(Icons.access_time),
                                    onPressed: () {
                                      // TODO: Firestore -> extend rental
                                    },
                                  ),

                                // Mark Returned
                                if (rental["status"] == "active" ||
                                    rental["status"] == "overdue")
                                  IconButton(
                                    icon:
                                        const Icon(Icons.check_circle, color: Colors.green),
                                    onPressed: () {
                                      // TODO: Firestore -> mark item returned
                                    },
                                  ),
                              ],
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
