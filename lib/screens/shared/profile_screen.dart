import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

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
    _cprController = TextEditingController(text: user?.cpr.toString() ?? '');
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Expanded(child: Text('Profile updated successfully')),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
          setState(() => _isEditing = false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Failed to update profile: $e')),
                ],
              ),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
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
    _cprController.text = user?.cpr.toString() ?? '';
    _usernameController.text = user?.username ?? '';
    
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _isEditing ? 'Edit Profile' : 'My Profile',
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2B6C67),
        foregroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
        actions: _isEditing
            ? [
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Color(0xFFEF4444),
                  ),
                  onPressed: _cancelEditing,
                  tooltip: 'Cancel',
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFF2B6C67),
                  ),
                  onPressed: _startEditing,
                  tooltip: 'Edit Profile',
                ),
              ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2B6C67),
              ),
            )
          : _isEditing
              ? _buildEditForm(context, user)
              : _buildProfileView(context, user),
    );
  }

  // ============ PROFILE VIEW (READ-ONLY) ============
  Widget _buildProfileView(BuildContext context, AppUser? user) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile Header with Gradient
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A4A47),
                  Color(0xFF2B6C67),
                ],
              ),
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(60),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 3,
                        ),
                      ),
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
                              size: 60,
                              color: Colors.white,
                            ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2B6C67),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(
                          Icons.verified,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  "${user?.firstName ?? ''} ${user?.lastName ?? ''}",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user?.email ?? 'No email provided',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
          
          // Profile Information Cards
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Personal Information
                _profileInfoCard(
                  title: 'Personal Information',
                  icon: Icons.person_outline,
                  children: [
                    _profileInfoRow(
                      icon: Icons.person,
                      label: 'First Name',
                      value: user?.firstName ?? 'Not provided',
                    ),
                    _profileInfoRow(
                      icon: Icons.person,
                      label: 'Last Name',
                      value: user?.lastName ?? 'Not provided',
                    ),
                    _profileInfoRow(
                      icon: Icons.alternate_email,
                      label: 'Username',
                      value: user?.username ?? 'Not provided',
                    ),
                    _profileInfoRow(
                      icon: Icons.fingerprint,
                      label: 'User ID',
                      value: user?.id.toString() ?? 'N/A',
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Contact Information
                _profileInfoCard(
                  title: 'Contact Information',
                  icon: Icons.contact_phone_outlined,
                  children: [
                    _profileInfoRow(
                      icon: Icons.email,
                      label: 'Email',
                      value: user?.email ?? 'Not provided',
                    ),
                    _profileInfoRow(
                      icon: Icons.phone,
                      label: 'Phone',
                      value: user?.phoneNumber ?? 'Not provided',
                    ),
                    _profileInfoRow(
                      icon: Icons.message,
                      label: 'Contact Preference',
                      value: user?.contactPref ?? 'Email',
                    ),
                    _profileInfoRow(
                      icon: Icons.badge,
                      label: 'CPR Number',
                      value: user?.cpr.toString() ?? 'Not provided',
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Account Information
                _profileInfoCard(
                  title: 'Account Information',
                  icon: Icons.account_circle_outlined,
                  children: [
                    _profileInfoRow(
                      icon: Icons.calendar_today,
                      label: 'Member Since',
                      value: 'January 15, 2024',
                    ),
                    _profileInfoRow(
                      icon: Icons.security,
                      label: 'Account Status',
                      value: 'Active',
                      valueColor: const Color(0xFF10B981),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Edit Profile Button
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _startEditing,
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 20,
                    ),
                    label: const Text(
                      "Edit Profile",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2B6C67),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      shadowColor: const Color(0xFF2B6C67).withOpacity(0.3),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
          color: Color(0xFFF1F5F9),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: const Color(0xFF2B6C67),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _profileInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9F8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF2B6C67),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: valueColor ?? const Color(0xFF1E293B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
            // Edit Profile Header
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F9F8),
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color: const Color(0xFFE8ECEF),
                            width: 3,
                          ),
                        ),
                        child: user?.profileImageUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  user!.profileImageUrl!,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                size: 50,
                                color: Color(0xFF2B6C67),
                              ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2B6C67),
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
                  const Text(
                    "Update Your Profile",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Make changes to your personal information",
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
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
            
            const SizedBox(height: 24),
            
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
            
            const SizedBox(height: 32),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _cancelEditing,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF64748B),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(
                        color: Color(0xFFE8ECEF),
                        width: 2,
                      ),
                    ),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2B6C67),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      shadowColor: const Color(0xFF2B6C67).withOpacity(0.3),
                    ),
                    child: const Text(
                      "Save Changes",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
            Icon(
              icon,
              color: const Color(0xFF2B6C67),
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(
              color: Color(0xFFF1F5F9),
              width: 1,
            ),
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
      style: const TextStyle(
        color: Color(0xFF1E293B),
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0xFF475569),
          fontSize: 14,
        ),
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Color(0xFF94A3B8),
        ),
        prefixIcon: Icon(
          icon,
          color: const Color(0xFF64748B),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE8ECEF),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE8ECEF),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF2B6C67),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFEF4444),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }
}