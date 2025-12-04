import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../utils/theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _contactPrefController;
  late TextEditingController _cprController;
  late TextEditingController _usernameController;

  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _contactPrefController = TextEditingController(text: user?.contactPref ?? '');
    _cprController = TextEditingController(text: user?.cpr?.toString() ?? '');
    _usernameController = TextEditingController(text: user?.username ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _contactPrefController.dispose();
    _cprController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;

    if (currentUser != null) {
      final updatedUser = AppUser(
        docId: currentUser.docId,
        cpr: _cprController.text.trim().isNotEmpty ? _cprController.text.trim() : '',
        email: _emailController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        role: currentUser.role,
        contactPref: _contactPrefController.text.trim(),
        id: currentUser.id,
        username: _usernameController.text.trim(),
        profileImageUrl: currentUser.profileImageUrl,
      );

      try {
        await authProvider.updateProfile(updatedUser);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        setState(() => _isEditing = false);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  void _startEditing() {
    setState(() => _isEditing = true);
  }

  void _cancelEditing() {
    final user = context.read<AuthProvider>().currentUser;
    _firstNameController.text = user?.firstName ?? '';
    _lastNameController.text = user?.lastName ?? '';
    _emailController.text = user?.email ?? '';
    _phoneController.text = user?.phoneNumber ?? '';
    _contactPrefController.text = user?.contactPref ?? '';
    _cprController.text = user?.cpr?.toString() ?? '';
    _usernameController.text = user?.username ?? '';
    
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(
        actions: _isEditing
            ? [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _cancelEditing,
                  tooltip: 'Cancel',
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _startEditing,
                  tooltip: 'Edit Profile',
                ),
              ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isEditing
              ? _buildEditForm(context, user)
              : _buildProfileView(context, user),
    );
  }

  // ============ PROFILE VIEW (READ-ONLY) ============
  Widget _buildProfileView(BuildContext context, AppUser? user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                  child: user?.profileImageUrl != null
                      ? ClipOval(
                          child: Image.network(
                            user!.profileImageUrl!,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          size: 70,
                          color: AppColors.primaryBlue,
                        ),
                ),
                const SizedBox(height: 20),
                Text(
                  "${user?.firstName ?? ''} ${user?.lastName ?? ''}",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user?.email ?? 'No email provided',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.neutralGray,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user?.role?.toUpperCase() ?? 'USER',
                    style: const TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
          const Divider(),
          const SizedBox(height: 20),
          
          // Personal Information Section
          _profileInfoSection(
            title: "Personal Information",
            icon: Icons.person_outline,
            children: [
              _profileInfoRow("First Name", user?.firstName ?? "Not provided"),
              _profileInfoRow("Last Name", user?.lastName ?? "Not provided"),
              _profileInfoRow("Username", user?.username ?? "Not provided"),
              _profileInfoRow("Email", user?.email ?? "Not provided"),
              _profileInfoRow("Phone", user?.phoneNumber ?? "Not provided"),
              _profileInfoRow("CPR Number", user?.cpr?.toString() ?? "Not provided"),
              _profileInfoRow("Contact Preference", user?.contactPref ?? "Email"),
              _profileInfoRow("Member Since", "January 15, 2024"),
              _profileInfoRow("User ID", user?.id?.toString() ?? "N/A"),
            ],
          ),
          
          const SizedBox(height: 40),
          
          // Edit Profile Button
          Center(
            child: ElevatedButton.icon(
              onPressed: _startEditing,
              icon: const Icon(Icons.edit_outlined),
              label: const Text("Edit Profile"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _profileInfoSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primaryBlue, size: 22),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: children,
            ),
          ),
        ),
      ],
    );
  }

  Widget _profileInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.neutralGray,
                fontSize: 15,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ EDIT FORM ============
  Widget _buildEditForm(BuildContext context, AppUser? user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                        child: user?.profileImageUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  user!.profileImageUrl!,
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                size: 70,
                                color: AppColors.primaryBlue,
                              ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Edit Profile",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Update your personal information",
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.neutralGray,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 20),
            
            // Personal Information Form
            _buildFormSection(
              title: "Personal Information",
              icon: Icons.person_outline,
              children: [
                _buildTextField(
                  controller: _firstNameController,
                  label: "First Name",
                  icon: Icons.person_outline,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter your first name'
                      : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _lastNameController,
                  label: "Last Name",
                  icon: Icons.person_outline,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter your last name'
                      : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _usernameController,
                  label: "Username",
                  icon: Icons.alternate_email,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter a username'
                      : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _emailController,
                  label: "Email Address",
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Contact Information Form
            _buildFormSection(
              title: "Contact Information",
              icon: Icons.contact_phone_outlined,
              children: [
                _buildTextField(
                  controller: _phoneController,
                  label: "Phone Number",
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter your phone number'
                      : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _contactPrefController,
                  label: "Contact Preference",
                  icon: Icons.message_outlined,
                  hintText: "Email, Phone, SMS, etc.",
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter your contact preference'
                      : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _cprController,
                  label: "CPR Number",
                  icon: Icons.badge_outlined,
                  keyboardType: TextInputType.number,
                  hintText: "Optional",
                ),
              ],
            ),
            
            const SizedBox(height: 40),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _cancelEditing,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: AppColors.neutralGray),
                    ),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: AppColors.primaryDark),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _updateProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Save Changes"),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primaryBlue, size: 22),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: children,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: AppColors.neutralGray),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.neutralGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.neutralGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }
}