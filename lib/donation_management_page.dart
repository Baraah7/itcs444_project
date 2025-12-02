import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class DonationManagementPage extends StatefulWidget {
  const DonationManagementPage({super.key});

  @override
  State<DonationManagementPage> createState() =>
      _DonationManagementPageState();
}

class _DonationManagementPageState extends State<DonationManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  // Local demo data (replace with Firestore later)
  List<Map<String, dynamic>> donations = [
    {
      "donor": "Ali Ahmed",
      "contact": "+973 3200 1234",
      "itemType": "Wheelchair",
      "description": "Almost new, gently used",
      "condition": "Good",
      "photos": [],
      "status": "Pending"
    },
    {
      "donor": "Sara Yousif",
      "contact": "+973 6610 5555",
      "itemType": "Walker",
      "description": "Used, minor scratches",
      "condition": "Fair",
      "photos": [],
      "status": "Approved"
    },
  ];

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final pending = donations.where((d) => d["status"] == "Pending").toList();
    final approved = donations.where((d) => d["status"] == "Approved").toList();
    final rejected = donations.where((d) => d["status"] == "Rejected").toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Donation Management"),
        bottom: TabBar(
          controller: tabController,
          tabs: const [
            Tab(text: "Pending"),
            Tab(text: "Approved"),
            Tab(text: "Rejected"),
          ],
        ),
      ),

      body: TabBarView(
        controller: tabController,
        children: [
          _buildDonationList(pending, "Pending"),
          _buildDonationList(approved, "Approved"),
          _buildDonationList(rejected, "Rejected"),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _openDonationForm,
        child: const Icon(Icons.add),
      ),
    );
  }

  // ====================================================
  // Donation List Builder
  // ====================================================
  Widget _buildDonationList(List<Map<String, dynamic>> items, String status) {
    if (items.isEmpty) {
      return const Center(child: Text("No donations found."));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Donor Information
                Text(item["donor"],
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                Text("Contact: ${item["contact"]}"),

                const SizedBox(height: 8),
                Text("Item Type: ${item["itemType"]}"),
                Text("Condition: ${item["condition"]}"),
                Text("Description: ${item["description"]}"),

                const SizedBox(height: 10),
                // Photos preview
                SizedBox(
                  height: 90,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: (item["photos"] as List)
                        .map<Widget>((p) => Container(
                              width: 90,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: FileImage(File(p)),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),

                const SizedBox(height: 12),

                // ACTION BUTTONS
                if (status == "Pending")
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _approveDonation(item),
                        icon: const Icon(Icons.check),
                        label: const Text("Approve"),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () => _rejectDonation(item),
                        icon: const Icon(Icons.close),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        label: const Text("Reject"),
                      ),
                    ],
                  ),

                if (status == "Approved")
                  ElevatedButton.icon(
                    onPressed: () => _addToInventory(item),
                    icon: const Icon(Icons.add_box),
                    label: const Text("Add to Inventory"),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ====================================================
  // Approve Donation
  // ====================================================
  void _approveDonation(Map<String, dynamic> item) {
    setState(() {
      item["status"] = "Approved";
    });

    // TODO: Firestore update
    // FirebaseFirestore.instance.collection("donations").doc(itemId).update({
    //   "status": "Approved"
    // });
  }

  // ====================================================
  // Reject Donation
  // ====================================================
  void _rejectDonation(Map<String, dynamic> item) {
    setState(() {
      item["status"] = "Rejected";
    });

    // TODO: Firestore update
    // FirebaseFirestore.instance.collection("donations").doc(itemId).update({
    //   "status": "Rejected"
    // });
  }

  // ====================================================
  // Add Approved Donation to Inventory
  // ====================================================
  void _addToInventory(Map<String, dynamic> item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${item["itemType"]} added to inventory!"),
      ),
    );

    // TODO: Firestore
    // FirebaseFirestore.instance.collection("inventory").add({
    //   "name": item["itemType"],
    //   "description": item["description"],
    //   "condition": item["condition"],
    //   "photos": item["photos"],
    //   "quantity": 1,
    //   "status": "Available",
    // });
  }

  // ====================================================
  // Donation Form Dialog
  // ====================================================
  void _openDonationForm() async {
    final donorController = TextEditingController();
    final contactController = TextEditingController();
    final itemTypeController = TextEditingController();
    final descController = TextEditingController();
    //final donorNameController = TextEditingController();
    final conditionController = TextEditingController();
    List<String> photos = [];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModal) {
          return AlertDialog(
            title: const Text("New Donation"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  _field(donorController, "Donor Name"),
                  _field(contactController, "Contact Number"),
                  _field(itemTypeController, "Item Type"),
                  _field(conditionController, "Condition"),
                  _field(descController, "Description", maxLines: 2),

                  const SizedBox(height: 10),
                  // Photo picker
                  Wrap(
                    spacing: 8,
                    children: [
                      ...photos.map((p) => Image.file(
                            File(p),
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                          )),
                      GestureDetector(
                        onTap: () async {
                          final picker = ImagePicker();
                          final img =
                              await picker.pickImage(source: ImageSource.gallery);
                          if (img != null) {
                            setModal(() => photos.add(img.path));
                          }
                        },
                        child: Container(
                          width: 70,
                          height: 70,
                          color: Colors.grey[300],
                          child: const Icon(Icons.add_a_photo),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    donations.add({
                      "donor": donorController.text,
                      "contact": contactController.text,
                      "itemType": itemTypeController.text,
                      "description": descController.text,
                      "condition": conditionController.text,
                      "photos": photos,
                      "status": "Pending",
                    });
                  });

                  // TODO: Save to Firestore
                  // FirebaseFirestore.instance.collection("donations").add({...});

                  Navigator.pop(context);
                },
                child: const Text("Submit"),
              ),
            ],
          );
        },
      ),
    );
  }

  // ====================================================
  // Input Field Widget
  // ====================================================
  Widget _field(TextEditingController c, String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
