import 'package:flutter/material.dart';

class RequestsManagementPage extends StatefulWidget {
  const RequestsManagementPage({super.key});

  @override
  State<RequestsManagementPage> createState() => _RequestsManagementPageState();
}

class _RequestsManagementPageState extends State<RequestsManagementPage>
    with SingleTickerProviderStateMixin {
  
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 4, vsync: this);
  }

  // TODO: Replace with Firestore Streams
  final dummyRequests = [
    {
      "user": "Ali Ahmed",
      "contact": "+973 3999 5522",
      "equipment": "Wheelchair",
      "dateStart": "2025-01-15",
      "dateEnd": "2025-01-20",
      "status": "pending",
    },
    {
      "user": "Fatima Yusuf",
      "contact": "+973 3311 1100",
      "equipment": "Crutches",
      "dateStart": "2025-01-10",
      "dateEnd": "2025-01-12",
      "status": "approved",
    },
    {
      "user": "Hassan Ali",
      "contact": "+973 3666 5533",
      "equipment": "Walker",
      "dateStart": "2025-01-01",
      "dateEnd": "2025-01-15",
      "status": "active",
    },
    {
      "user": "Maryam Salman",
      "contact": "+973 3777 9484",
      "equipment": "Portable Bed",
      "dateStart": "2024-12-20",
      "dateEnd": "2024-12-30",
      "status": "completed",
    }
  ];

  // Filter helper
  List<Map<String, dynamic>> filterRequests(String status) {
    return dummyRequests.where((r) => r["status"] == status).toList();
  }

  Color getStatusColor(String status) {
    switch (status) {
      case "pending":
        return Colors.orange;
      case "approved":
        return Colors.blue;
      case "active":
        return Colors.green;
      case "completed":
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  // Approve → Check availability → Firestore Transaction later
  void approveRequest(Map<String, dynamic> req) {
    // TODO: Firestore Transaction to:
    // 1. Check availability
    // 2. Mark request as approved
    // 3. Lock equipment for rental dates
  }

  void declineRequest(Map<String, dynamic> req) {
    // TODO: Update status to "declined" and send notification
  }

  void checkOutEquipment(Map<String, dynamic> req) {
    // TODO: Change status from "approved" → "active"
  }

  void markCompleted(Map<String, dynamic> req) {
    // TODO: Change status "active" → "completed"
    // TODO: Increase trust score or update history
  }

  Widget buildRequestCard(Map<String, dynamic> req) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info
            Text(req["user"],
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(req["contact"], style: const TextStyle(color: Colors.grey)),

            const SizedBox(height: 10),

            // Equipment + Dates
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Equipment: ${req["equipment"]}"),
                Chip(
                  label: Text(req["status"].toUpperCase()),
                  backgroundColor: getStatusColor(req["status"]).withOpacity(.2),
                  labelStyle: TextStyle(
                      color: getStatusColor(req["status"]),
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Text(
                "From: ${req["dateStart"]}   →   To: ${req["dateEnd"]}",
                style: const TextStyle(fontSize: 13)
            ),

            const SizedBox(height: 12),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (req["status"] == "pending") ...[
                  ElevatedButton(
                    onPressed: () => approveRequest(req),
                    child: const Text("Approve"),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () => declineRequest(req),
                    child: const Text("Decline"),
                  ),
                ],

                if (req["status"] == "approved") ...[
                  ElevatedButton(
                      onPressed: () => checkOutEquipment(req),
                      child: const Text("Check Out")),
                ],

                if (req["status"] == "active") ...[
                  ElevatedButton(
                    onPressed: () => markCompleted(req),
                    child: const Text("Mark Returned"),
                  ),
                ],
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Requests Management"),
        bottom: TabBar(
          controller: tabController,
          labelColor: Colors.white,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "Pending"),
            Tab(text: "Approved"),
            Tab(text: "Active"),
            Tab(text: "Completed"),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          // PENDING
          ListView(
            children:
                filterRequests("pending").map(buildRequestCard).toList(),
          ),

          // APPROVED
          ListView(
            children:
                filterRequests("approved").map(buildRequestCard).toList(),
          ),

          // ACTIVE RENTALS
          ListView(
            children:
                filterRequests("active").map(buildRequestCard).toList(),
          ),

          // COMPLETED
          ListView(
            children:
                filterRequests("completed").map(buildRequestCard).toList(),
          ),
        ],
      ),
    );
  }
}