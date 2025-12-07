import 'package:flutter/material.dart';
import 'package:itcs444_project/utils/theme.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../user/user_dashboard.dart';
import '../admin/admin_dashboard.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _cprController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _idController = TextEditingController();

  String selectedRole = "Renter";
  String selectedContactPref = "Email";
  bool _obscurePassword = true;

  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white10,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Account", style: TextStyle(color: AppColors.primaryDark),),
        centerTitle: true,
        backgroundColor: AppColors.primaryBlue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------- TITLE ----------
                Text(
                  "Personal Information",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 20),
        
                // CPR
                TextFormField(
                  controller: _cprController,
                  keyboardType: TextInputType.number,
                  decoration: _inputStyle("CPR", Icons.badge),
                  validator: (value) =>
                      value!.isEmpty ? "CPR is required" : null,
                ),
                const SizedBox(height: 15),
        
                // Email
                TextFormField(
                  controller: _emailController,
                  decoration: _inputStyle("Email", Icons.email),
                  validator: (value) =>
                      value!.isEmpty ? "Email is required" : null,
                ),
                const SizedBox(height: 15),
        
                // First + Last Name Side by Side
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameController,
                        decoration: _inputStyle("First Name", Icons.person),
                        validator: (value) =>
                            value!.isEmpty ? "First name required" : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameController,
                        decoration: _inputStyle("Last Name", Icons.person),
                        validator: (value) =>
                            value!.isEmpty ? "Last name required" : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
        
                // Phone Number
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration:
                      _inputStyle("Phone Number", Icons.phone_android),
                  validator: (value) =>
                      value!.isEmpty ? "Phone number required" : null,
                ),
                const SizedBox(height: 15),
        
                // Username
                TextFormField(
                  controller: _usernameController,
                  decoration: _inputStyle("Username", Icons.account_circle),
                  validator: (value) =>
                      value!.isEmpty ? "Username required" : null,
                ),
                const SizedBox(height: 15),
        
                // ID
                TextFormField(
                  controller: _idController,
                  keyboardType: TextInputType.number,
                  decoration:
                      _inputStyle("User ID / Internal ID", Icons.credit_card),
                  validator: (value) =>
                      value!.isEmpty ? "ID is required" : null,
                ),
        
                const SizedBox(height: 25),
                Divider(thickness: 1),
                const SizedBox(height: 15),
        
                // ---------- ACCOUNT SETTINGS ----------
                Text(
                  "Account Settings",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 20),
        
                // Role Dropdown
                DropdownButtonFormField(
                  initialValue: selectedRole,
                  decoration: _inputStyle("Select Role", Icons.work),
                  items: const [
                    DropdownMenuItem(value: "Renter", child: Text("Renter")),
                    DropdownMenuItem(value: "Donor", child: Text("Donor")),
                    DropdownMenuItem(value: "Admin", child: Text("Admin")),
                  ],
                  onChanged: (value) =>
                      setState(() => selectedRole = value!),
                ),
                const SizedBox(height: 15),
        
                // Contact Preference
                DropdownButtonFormField(
                  initialValue: selectedContactPref,
                  decoration:
                      _inputStyle("Preferred Contact", Icons.settings_phone),
                  items: const [
                    DropdownMenuItem(value: "Email", child: Text("Email")),
                    DropdownMenuItem(value: "Phone", child: Text("Phone")),
                  ],
                  onChanged: (value) =>
                      setState(() => selectedContactPref = value!),
                ),
                const SizedBox(height: 15),
        
                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: _inputStyle("Password", Icons.lock).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (value) =>
                      value!.length < 6 ? "Minimum 6 characters" : null,
                ),
                const SizedBox(height: 25),
        
                // Register Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      backgroundColor: AppColors.accentMauve,
                    ),
                    onPressed: authProvider.isLoading
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              AppUser newUser = AppUser(
                                docId: null,
                                cpr: _cprController.text.trim(),
                                email: _emailController.text.trim(),
                                firstName: _firstNameController.text.trim(),
                                lastName: _lastNameController.text.trim(),
                                phoneNumber: _phoneController.text.trim(),
                                role: selectedRole,
                                contactPref: selectedContactPref,
                                id: int.tryParse(
                                        _idController.text.trim()) ??
                                    0,
                                username:
                                    _usernameController.text.trim(),
                              );
        
                              bool success = await authProvider.register(
                                newUser,
                                _passwordController.text.trim(),
                              );
        
                              if (!success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text("Registration failed. Try again."),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
        
                              if (selectedRole == "Admin") {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const AdminDashboard()),
                                );
                              } else {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const UserDashboard()),
                                );
                              }
                            }
                          },
                    child: authProvider.isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text(
                            "Register",
                            style: TextStyle(fontSize: 16, color: AppColors.primaryDark),
                          ),
                  ),
                ),
        
                const SizedBox(height: 15),
        
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Already have an account? Login", style: TextStyle(color: AppColors.primaryDark)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}