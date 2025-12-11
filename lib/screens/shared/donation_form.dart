// Submit donation (used by donors)
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';
import 'package:flutter_iconpicker/Models/configuration.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  bool _isSubmitting = false;

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
    if (user == null) return;

    try {
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
        setState(() {
          _nameController.text = user!.displayName ?? '';
          _emailController.text = user!.email ?? '';
          _phoneController.text = user!.phoneNumber ?? '';
        });
      }
    } catch (e) {
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

  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null && pickedFile.path.isNotEmpty) {
      setState(() {
        images ??= [];
        images!.add(File(pickedFile.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      images?.removeAt(index);
    });
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Donation',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFE8ECEF),
            height: 1,
          ),
        ),
      ),
      body: Form(
        autovalidateMode: AutovalidateMode.onUserInteraction,
        key: formstate,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Donor Information Card
                    _buildCard(
                      title: 'Donor Information',
                      icon: Icons.person,
                      children: [
                        _buildTextField(
                          controller: _nameController,
                          label: 'Full Name',
                          hint: 'Mohammed Ali',
                          icon: Icons.person_outline,
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Required' : null,
                          onSaved: (val) => donorName = val ?? '',
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email',
                          hint: 'mohammed@gmail.com',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: _validateEmail,
                          onSaved: (val) => donorEmail = val ?? '',
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _phoneController,
                          label: 'Phone',
                          hint: '+973 3312 3456',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Required' : null,
                          onSaved: (val) => donorPhone = val ?? '',
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Item Information Card
                    _buildCard(
                      title: 'Item Information',
                      icon: Icons.inventory_2,
                      children: [
                        _buildTextField(
                          label: 'Item Name',
                          hint: 'S-Ergo 305',
                          icon: Icons.label_outline,
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Required' : null,
                          onSaved: (val) => itemName = val ?? '',
                        ),
                        const SizedBox(height: 12),
                        _buildDropdown(
                          label: 'Item Type',
                          icon: Icons.category_outlined,
                          value: itemVal,
                          items: itemTypes,
                          onChanged: (value) {
                            setState(() {
                              itemVal = value;
                              itemType = value ?? '';
                            });
                          },
                          validator: (value) =>
                              value == null ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        _buildDropdown(
                          label: 'Condition',
                          icon: Icons.star_outline,
                          value: condVal,
                          items: conditionTypes,
                          onChanged: (value) {
                            setState(() {
                              condVal = value;
                              condition = value ?? '';
                            });
                          },
                          validator: (value) =>
                              value == null ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        _buildQuantityRow(),
                        const SizedBox(height: 12),
                        _buildTextField(
                          label: 'Description',
                          hint: 'Color, size, dimensions, etc.',
                          icon: Icons.description_outlined,
                          maxLines: 3,
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Required' : null,
                          onSaved: (val) => description = val ?? '',
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          label: 'Comments (Optional)',
                          hint: 'Additional information',
                          icon: Icons.comment_outlined,
                          maxLines: 2,
                          onSaved: (val) => comments = val ?? '',
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Images Card
                    _buildCard(
                      title: 'Item Images',
                      icon: Icons.photo_library,
                      children: [
                        if (hasImages)
                          SizedBox(
                            height: 80,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: imageCount,
                              itemBuilder: (context, index) {
                                final imageFile = imageAt(index);
                                if (imageFile == null) return const SizedBox();
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          imageFile,
                                          height: 80,
                                          width: 80,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: () => _removeImage(index),
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFEF4444),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        if (hasImages) const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: pickImage,
                          icon: const Icon(Icons.add_photo_alternate, size: 18),
                          label: Text(hasImages ? 'Add More' : 'Add Images'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2B6C67),
                            side: const BorderSide(color: Color(0xFF2B6C67)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Icon Selection Card
                    _buildCard(
                      title: 'Item Icon (Optional)',
                      icon: Icons.category,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _selectedIcon != null
                                    ? const Color(0xFF2B6C67).withOpacity(0.1)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFE8ECEF),
                                ),
                              ),
                              child: Icon(
                                _selectedIcon ?? Icons.help_outline,
                                color: _selectedIcon != null
                                    ? const Color(0xFF2B6C67)
                                    : const Color(0xFF94A3B8),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedIcon != null
                                    ? 'Icon selected'
                                    : 'No icon selected',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _selectedIcon != null
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            OutlinedButton(
                              onPressed: _pickIcon,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF2B6C67),
                                side: const BorderSide(
                                  color: Color(0xFF2B6C67),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Choose'),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Submit Button (Fixed at bottom)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFE8ECEF)),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitDonation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2B6C67),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: const Color(0xFF94A3B8),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit Donation',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8ECEF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A4A47).withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF2B6C67).withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2B6C67),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          // Card Content
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,
    required String label,
    String? hint,
    IconData? icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 13,
        ),
        prefixIcon: icon != null
            ? Icon(icon, color: const Color(0xFF64748B), size: 18)
            : null,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE8ECEF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE8ECEF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2B6C67), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14),
      validator: validator,
      onSaved: onSaved,
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8ECEF)),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        hint: Text(
          'Select $label',
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        ),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(
              item,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1E293B),
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }

  Widget _buildQuantityRow() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8ECEF)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.numbers, color: Color(0xFF64748B), size: 18),
              SizedBox(width: 10),
              Text(
                'Quantity',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: quantity > 1 ? () => setState(() => quantity--) : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: const Color(0xFF2B6C67),
                iconSize: 22,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE8ECEF)),
                ),
                child: Text(
                  '$quantity',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              IconButton(
                onPressed: quantity < 100 ? () => setState(() => quantity++) : null,
                icon: const Icon(Icons.add_circle_outline),
                color: const Color(0xFF2B6C67),
                iconSize: 22,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submitDonation() async {
    if (!formstate.currentState!.validate()) {
      return;
    }

    if (itemType.isEmpty || condition.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select item type and condition'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    formstate.currentState!.save();

    setState(() => _isSubmitting = true);

    donorName = _nameController.text;
    donorEmail = _emailController.text;
    donorPhone = _phoneController.text;

    try {
      List<String> imageUrls = [];
      if (images != null && images!.isNotEmpty) {
        imageUrls = await DonationService().uploadDonationImages(images!);
      }

      final int? iconCode = _selectedIcon?.codePoint;

      final donationID = await DonationService().submitDonation(
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
          content: Text('Donation submitted successfully!'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => UserDonationDetails(
            donationID: donationID,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting donation: $e'),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
