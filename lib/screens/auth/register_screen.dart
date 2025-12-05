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
  final bool _obscurePassword = true;

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
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // CPR
              TextFormField(
                controller: _cprController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "CPR",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? "CPR is required" : null,
              ),
              const SizedBox(height: 15),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Email is required" : null,
              ),
              const SizedBox(height: 15),

              // First Name
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: "First Name",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? "First name required" : null,
              ),
              const SizedBox(height: 15),

              // Last Name
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: "Last Name",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Last name required" : null,
              ),
              const SizedBox(height: 15),

              // Phone Number
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Phone number required" : null,
              ),
              const SizedBox(height: 15),

              // Username
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: "Username",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Username required" : null,
              ),
              const SizedBox(height: 15),

              // National ID / internal ID
              TextFormField(
                controller: _idController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "User ID / Internal ID",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? "ID required" : null,
              ),
              const SizedBox(height: 15),

              // Role Dropdown
              DropdownButtonFormField(
                initialValue: selectedRole,
                decoration: const InputDecoration(
                  labelText: "Role",
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: "Renter", child: Text("Renter")),
                  DropdownMenuItem(value: "Donor", child: Text("Donor")),
                  DropdownMenuItem(value: "Admin", child: Text("Admin")),
                ],
                onChanged: (value) {
                  setState(() => selectedRole = value!);
                },
              ),
              const SizedBox(height: 15),

              // Contact Preference
              DropdownButtonFormField(
                initialValue: selectedContactPref,
                decoration: const InputDecoration(
                  labelText: "Preferred Contact",
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: "Email", child: Text("Email")),
                  DropdownMenuItem(value: "Phone", child: Text("Phone")),
                ],
                onChanged: (value) {
                  setState(() => selectedContactPref = value!);
                },
              ),
              const SizedBox(height: 15),

              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
