import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  String searchQuery = "";
  String filterStatus = "All";

  // Local demo items (replace with Firestore later)
  List<Map<String, dynamic>> equipmentList = [
    {
      "name": "Wheelchair",
      "type": "Mobility",
      "status": "Available",
      "quantity": 4,
      "image": null,
    },
    {
      "name": "Walker",
      "type": "Mobility",
      "status": "Rented",
      "quantity": 2,
      "image": null,
    },
    {
      "name": "Crutches",
      "type": "Support",
      "status": "Maintenance",
      "quantity": 1,
      "image": null,
    }
  ];

  @override
  Widget build(BuildContext context) {
    final filteredItems = equipmentList.where((item) {
      final matchesSearch = item["name"]
              .toString()
              .toLowerCase()
              .contains(searchQuery.toLowerCase()) ||
          item["type"].toString().toLowerCase().contains(searchQuery.toLowerCase());

      final matchesFilter = filterStatus == "All" || item["status"] == filterStatus;

      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Inventory Management"),
        actions: [
          // ----------------------------
          // SEARCH BAR
          // ----------------------------
          SizedBox(
            width: 250,
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Search...",
                border: InputBorder.none,
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),

          // ----------------------------
          // FILTER MENU
          // ----------------------------
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() => filterStatus = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: "All", child: Text("All")),
              const PopupMenuItem(value: "Available", child: Text("Available")),
              const PopupMenuItem(value: "Rented", child: Text("Rented")),
              const PopupMenuItem(value: "Maintenance", child: Text("Maintenance")),
            ],
            icon: const Icon(Icons.filter_alt),
          ),
        ],
      ),

      // ------------------------------------
      // Responsive Grid/List of inventory items
      // ------------------------------------
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWide = constraints.maxWidth > 700;

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isWide ? 3 : 1,
              childAspectRatio: 2.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              final item = filteredItems[index];

              return Card(
                child: Row(
                  children: [
                    // Item image
                    Container(
                      width: 90,
                      height: 90,
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[200],
                        image: item["image"] != null
                            ? DecorationImage(
                                image: FileImage(File(item["image"])),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: item["image"] == null
                          ? const Icon(Icons.image, size: 40, color: Colors.grey)
                          : null,
                    ),

                    // Item info
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item["name"],
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            Text("Type: ${item["type"]}"),
                            Text("Status: ${item["status"]}"),
                            Text("Quantity: ${item["quantity"]}"),
                          ],
                        ),
                      ),
                    ),

                    // Edit + Delete buttons
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _openEquipmentForm(item: item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              equipmentList.remove(item);
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),

      // -----------------------------------
      // FLOATING BUTTON - ADD EQUIPMENT
      // -----------------------------------
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEquipmentForm(),
        child: const Icon(Icons.add),
      ),
    );
  }

  // ======================================================
  // ADD / EDIT ITEM FORM DIALOG
  // ======================================================
  void _openEquipmentForm({Map<String, dynamic>? item}) async {
    final nameController = TextEditingController(text: item?["name"] ?? "");
    final typeController = TextEditingController(text: item?["type"] ?? "");
    final descController = TextEditingController(text: item?["description"] ?? "");
    final conditionController =
        TextEditingController(text: item?["condition"] ?? "");
    final quantityController =
        TextEditingController(text: item?["quantity"]?.toString() ?? "1");
    final locationController = TextEditingController(text: item?["location"] ?? "");
    final tagsController = TextEditingController(text: item?["tags"] ?? "");
    final priceController =
        TextEditingController(text: item?["rentalPrice"]?.toString() ?? "");

    String status = item?["status"] ?? "Available";
    File? pickedImage;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setModal) {
        return AlertDialog(
          title: Text(item == null ? "Add Equipment" : "Edit Equipment"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // IMAGE PICKER
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(source: ImageSource.gallery);
                    if (picked != null) {
                      setModal(() => pickedImage = File(picked.path));
                    }
                  },
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: pickedImage == null
                        ? const Center(child: Icon(Icons.add_a_photo, size: 40))
                        : Image.file(pickedImage!, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 10),

                _field(nameController, "Name"),
                _field(typeController, "Type"),
                _field(descController, "Description"),
                _field(conditionController, "Condition"),
                _field(quantityController, "Quantity", isNumber: true),
                _field(locationController, "Location"),
                _field(tagsController, "Tags (comma separated)"),
                _field(priceController, "Rental Price", isNumber: true),

                const SizedBox(height: 8),
                DropdownButtonFormField(
                  initialValue: status,
                  items: const [
                    DropdownMenuItem(value: "Available", child: Text("Available")),
                    DropdownMenuItem(value: "Rented", child: Text("Rented")),
                    DropdownMenuItem(value: "Maintenance", child: Text("Maintenance")),
                  ],
                  onChanged: (value) => setModal(() => status = value.toString()),
                  decoration: const InputDecoration(labelText: "Availability Status"),
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
                  if (item == null) {
                    equipmentList.add({
                      "name": nameController.text,
                      "type": typeController.text,
                      "description": descController.text,
                      "condition": conditionController.text,
                      "quantity": int.tryParse(quantityController.text) ?? 1,
                      "status": status,
                      "location": locationController.text,
                      "tags": tagsController.text,
                      "rentalPrice": double.tryParse(priceController.text) ?? 0,
                      "image": pickedImage?.path,
                    });
                  } else {
                    item["name"] = nameController.text;
                    item["type"] = typeController.text;
                    item["description"] = descController.text;
                    item["condition"] = conditionController.text;
                    item["quantity"] = int.tryParse(quantityController.text) ?? 1;
                    item["status"] = status;
                    item["location"] = locationController.text;
                    item["tags"] = tagsController.text;
                    item["rentalPrice"] = double.tryParse(priceController.text) ?? 0;
                    item["image"] = pickedImage?.path ?? item["image"];
                  }
                });

                // TODO: Save to Firestore
                // FirebaseFirestore.instance.collection("inventory").add({...});

                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      }),
    );

    setState(() {});
  }

  // ======================================================
  // INPUT FIELD WIDGET
  // ======================================================
  Widget _field(TextEditingController c, String label,
      {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: c,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(labelText: label, border: OutlineInputBorder()),
      ),
    );
  }
}