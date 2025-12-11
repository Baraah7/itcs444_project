//Submit donation (used by donors)
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_iconpicker/Models/configuration.dart';
import 'package:image_picker/image_picker.dart';
import 'package:itcs444_project/screens/user/user_donation_details.dart';
import 'package:itcs444_project/services/donation_service.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DonationForm extends StatefulWidget {
  const DonationForm({super.key});

  @override
  State<DonationForm> createState() => DonationFormState();
}

class DonationFormState extends State<DonationForm> {
  GlobalKey<FormState> formstate = GlobalKey();
  String donorName = '';
  String donorContact = '';
  String itemName = '';
  String itemType = ''; // will be set from dropdown
  String condition = ''; // will be set from dropdown
  String comments = '';
  DateTime? submissionDate;
  String? description;
  List<File>? images;
  int quantity = 1;
  DateTime? approvalDate;
  final user = FirebaseAuth.instance.currentUser;
  late final uid = user?.uid;

  List<String> conditionTypes = [
    'New',
    'Like New',
    'Good',
    'OK',
    'Needs Repairs',
  ];
  List<String> itemTypes = [
    'Wheelchair',
    'Electrical Bed',
    'Mechanical Bed',
    'Shower Chair',
    'Walker',
    'Walker with Wheels',
    'Crutches',
  ];

  String? condVal;
  String? itemVal;
  IconData? _selectedIcon;

  Future<void> _pickIcon() async {
    final IconPickerIcon? icon = await showIconPicker(
      context,
      configuration: const SinglePickerConfiguration(
        title: Text('Pick an icon'),
        searchHintText: 'Search...',
        noResultsText: 'No results found',
        iconPackModes: [IconPack.material, IconPack.cupertino],
      ),
    );

    if (icon != null) {
      setState(() {
        _selectedIcon = icon.data;
      });
    }
  }

  final _picker = ImagePicker();

  pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null && pickedFile.path.isNotEmpty) {
      setState(() {
        if (images == null) {
          images = [File(pickedFile.path)];
        } else {
          images!.add(File(pickedFile.path));
        }
      });
    }
  }

  bool get hasImages => images != null && images!.isNotEmpty;
  int get imageCount => images?.length ?? 0;

  File? imageAt(int index) {
    if (images == null || index < 0 || index >= images!.length) {
      return null;
    }
    return images![index];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Donation Form'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            spacing: 10,
            children: [
              const Text(
                'Please fill out the following details.',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.left,
              ),
              Form(
                autovalidateMode: AutovalidateMode.always,
                key: formstate,
                child: Column(
                  spacing: 15,
                  children: [
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Donor/Organization Name',
                        hintText: 'eg.:  Mohammed Ali, Al Amal Co.',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onSaved: (val) => donorName = val ?? '',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'This field is required.';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Donor Contact',
                        hintText: 'eg.: mohammed@gmail.com, or +9733312345',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onSaved: (val) => donorContact = val ?? '',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'This field is required.';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Item Name',
                        hintText: 'Item name/model, eg.: S-Ergo 305',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onSaved: (val) => itemName = val ?? '',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'This field is required.';
                        }
                        return null;
                      },
                    ),

                    // ITEM TYPE DROPDOWN (FIXED)
                    ListTile(
                      title: const Text("Type: "),
                      trailing: DropdownMenu(
                        initialSelection: itemVal,
                        dropdownMenuEntries: itemTypes.map((item) {
                          return DropdownMenuEntry(value: item, label: item);
                        }).toList(),
                        onSelected: (value) {
                          setState(() {
                            itemVal = value;
                            itemType = value ?? '';
                          });
                        },
                      ),
                    ),

                    // CONDITION DROPDOWN (FIXED)
                    ListTile(
                      title: const Text("Condition: "),
                      trailing: DropdownMenu(
                        initialSelection: condVal,
                        dropdownMenuEntries: conditionTypes.map((item) {
                          return DropdownMenuEntry(value: item, label: item);
                        }).toList(),
                        onSelected: (value) {
                          setState(() {
                            condVal = value;
                            condition = value ?? '';
                          });
                        },
                      ),
                    ),

                    ListTile(
                      leading: const Text(
                        'Quantity:',
                        style: TextStyle(fontSize: 18),
                      ),
                      trailing: Row(
                        mainAxisSize:
                            MainAxisSize.min, // 👈 THIS avoids layout errors
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () {
                              if (quantity > 1) {
                                setState(() {
                                  quantity--;
                                });
                              }
                            },
                          ),
                          Text(
                            '$quantity',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              if (quantity < 101) {
                                setState(() {
                                  quantity++;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Description',
                        hintText:
                            'Item description, eg.: color, size, height, etc.',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onSaved: (val) => description = val ?? '',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'This field is required.';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Comments',
                        hintText: 'Anything else we should know?',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onSaved: (val) => comments = val ?? '',
                    ),

                    // Image picker
                    ListTile(
                      leading: const Icon(Icons.camera_alt),
                      title: const Text('You can add images of the item here.'),
                      trailing: ElevatedButton(
                        onPressed: pickImage,
                        child: const Text('Choose Image'),
                      ),
                    ),
                    !hasImages
                        ? const Text('No images selected')
                        : SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: imageCount,
                              itemBuilder: (context, index) {
                                final imageFile = imageAt(index);
                                if (imageFile == null) return const SizedBox();
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Image.file(
                                    imageFile,
                                    height: 80,
                                    width: 90,
                                    fit: BoxFit.cover,
                                  ),
                                );
                              },
                            ),
                          ),

                    // Icon picker
                    ListTile(
                      leading: _selectedIcon != null
                          ? Icon(_selectedIcon)
                          : const Icon(Icons.add),

                      title: const Text(
                        'You can choose icons describing the item here.',
                      ),
                      trailing: ElevatedButton(
                        onPressed: _pickIcon,
                        child: const Text('Choose Icon'),
                      ),
                    ),

                    ElevatedButton(
                      onPressed: () async {
                        if (!formstate.currentState!.validate()) {
                          return;
                        }
                        // ensure dropdowns are selected
                        if (itemType.isEmpty || condition.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please select item type and condition.',
                              ),
                            ),
                          );
                          return;
                        }

                        formstate.currentState!.save();
                        List<String> imageUrls = [];
                        if (images != null && images!.isNotEmpty) {
                          imageUrls = await DonationService()
                              .uploadDonationImages(images!);
                        }
                        int? iconCode = _selectedIcon?.codePoint;

                        try {
                          final donationID = await DonationService()
                              .submitDonation(
                                itemName: itemName,
                                donorName: donorName,
                                donorContact: donorContact,
                                itemType: itemType,
                                condition: condition,
                                status: 'Pending',
                                submissionDate: DateTime.now(),
                                description: description,
                                quantity: quantity,
                                imagePaths: imageUrls,
                                iconCode: iconCode,
                                comments: comments,
                                donorID: uid,
                              );

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Donation submitted successfully!'),
                            ),
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  UserDonationDetails(donationID: donationID),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error submitting donation: $e'),
                            ),
                          );
                        }
                      },
                      child: const Text('Submit Donation'),
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
}