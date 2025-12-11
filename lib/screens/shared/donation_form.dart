// Submit donation (used by donors)
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import 'package:flutter_iconpicker/Models/configuration.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';   // 👈 NEW
import 'package:itcs444_project/screens/user/user_donation_details.dart';
import 'package:itcs444_project/services/donation_service.dart';

class DonationForm extends StatefulWidget {
  const DonationForm({super.key});

  @override
  State<DonationForm> createState() => DonationFormState();
}

class DonationFormState extends State<DonationForm> {
  final GlobalKey<FormState> formstate = GlobalKey();

  // Form field values
  String donorName = '';
  String donorEmail = '';
  String donorPhone = '';
  String itemName = '';
  String itemType = '';
  String condition = '';
  String comments = '';
  String? description;
  List<File>? images;
  int quantity = 1;

  // Firebase user
  final User? user = FirebaseAuth.instance.currentUser;
  late final String? uid = user?.uid;

  // Controllers for prefill
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Dropdown options
  final List<String> conditionTypes = [
    'New',
    'Like New',
    'Good',
    'OK',
    'Needs Repairs',
  ];

  final List<String> itemTypes = [
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

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _prefillFromUser();
  }

  Future<void> _prefillFromUser() async {
    // If not logged in → nothing to prefill
    if (user == null) return;

    try {
      // 1) Try Firestore "users" collection (this is where AppUser is stored)
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        final firstName = (data['firstName'] ?? '').toString();
        final lastName = (data['lastName'] ?? '').toString();
        final fullName = [firstName, lastName]
            .where((p) => p.trim().isNotEmpty)
            .join(' ')
            .trim();

        setState(() {
          _nameController.text =
              fullName.isNotEmpty ? fullName : (user!.displayName ?? '');
          _emailController.text =
              (data['email'] ?? user!.email ?? '').toString();
          _phoneController.text =
              (data['phoneNumber'] ?? user!.phoneNumber ?? '').toString();
        });
      } else {
        // 2) Fallback to FirebaseAuth fields only if Firestore user doc missing
        setState(() {
          _nameController.text = user!.displayName ?? '';
          _emailController.text = user!.email ?? '';
          _phoneController.text = user!.phoneNumber ?? '';
        });
      }
    } catch (e) {
      // On error, at least use FirebaseAuth data if available
      debugPrint('Error pre-filling user info: $e');
      if (!mounted) return;
      setState(() {
        _nameController.text = user!.displayName ?? '';
        _emailController.text = user!.email ?? '';
        _phoneController.text = user!.phoneNumber ?? '';
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Simple email validator
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required.';
    }
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value)) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  // Pick icon
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

  // Pick image
  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null && pickedFile.path.isNotEmpty) {
      setState(() {
        images ??= [];
        images!.add(File(pickedFile.path));
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

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Donation Form'),
      ),
      body: SingleChildScrollView(
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
              autovalidateMode: AutovalidateMode.onUserInteraction,
              key: formstate,
              child: Column(
                spacing: 15,
                children: [
                  // Donor name
                  TextFormField(
                    controller: _nameController,
                    decoration: _inputDecoration(
                      'Donor/Organization Name',
                      hint: 'eg.: Mohammed Ali, Al Amal Co.',
                    ),
                    onSaved: (val) => donorName = val ?? '',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'This field is required.';
                      }
                      return null;
                    },
                  ),

                  // Donor email
                  TextFormField(
                    controller: _emailController,
                    decoration: _inputDecoration(
                      'Donor Email',
                      hint: 'eg.: mohammed@gmail.com',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onSaved: (val) => donorEmail = val ?? '',
                    validator: _validateEmail,
                  ),

                  // Donor phone
                  TextFormField(
                    controller: _phoneController,
                    decoration: _inputDecoration(
                      'Phone Number',
                      hint: 'eg.: +9733312345',
                    ),
                    keyboardType: TextInputType.phone,
                    onSaved: (val) => donorPhone = val ?? '',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'This field is required.';
                      }
                      return null;
                    },
                  ),

                  // Item name
                  TextFormField(
                    decoration: _inputDecoration(
                      'Item Name',
                      hint: 'Item name/model, eg.: S-Ergo 305',
                    ),
                    onSaved: (val) => itemName = val ?? '',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'This field is required.';
                      }
                      return null;
                    },
                  ),

                  // Item type dropdown
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

                  // Condition dropdown
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

                  // Quantity row
                  ListTile(
                    leading: const Text(
                      'Quantity:',
                      style: TextStyle(fontSize: 18),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
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

                  // Description
                  TextFormField(
                    decoration: _inputDecoration(
                      'Description',
                      hint: 'Item description, eg.: color, size, height, etc.',
                    ),
                    onSaved: (val) => description = val ?? '',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'This field is required.';
                      }
                      return null;
                    },
                  ),

                  // Comments
                  TextFormField(
                    decoration: _inputDecoration(
                      'Comments',
                      hint: 'Anything else we should know?',
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
                              if (imageFile == null) {
                                return const SizedBox();
                              }
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

                  // Submit button
                  ElevatedButton(
                    onPressed: () async {
                      if (!formstate.currentState!.validate()) {
                        return;
                      }

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

                      // Use controller values
                      donorName = _nameController.text;
                      donorEmail = _emailController.text;
                      donorPhone = _phoneController.text;

                      List<String> imageUrls = [];
                      if (images != null && images!.isNotEmpty) {
                        imageUrls = await DonationService()
                            .uploadDonationImages(images!);
                      }

                      final int? iconCode = _selectedIcon?.codePoint;

                      try {
                        final donationID =
                            await DonationService().submitDonation(
                          itemName: itemName,
                          donorName: donorName,
                          donorContact: donorEmail,
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
                          donorPhone: donorPhone,
                        );

                        if (!mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Donation submitted successfully!',
                            ),
                          ),
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserDonationDetails(
                              donationID: donationID,
                            ),
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('Error submitting donation: $e'),
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
    );
  }
}
