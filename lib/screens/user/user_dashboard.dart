//Browse equipment + quick actions
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/reservation_model.dart';
import '../../models/equipment_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reservation_provider.dart';
import '../../providers/equipment_provider.dart';
import 'equipment_list.dart';
import 'my_reservations.dart';
import 'equipment_detail.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const EquipmentListScreen(),
    const MyReservationsScreen(),
    const UserProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final reservationProvider = Provider.of<ReservationProvider>(context);
    final equipmentProvider = Provider.of<EquipmentProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipment Rental'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Equipment',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'My Reservations',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await Provider.of<AuthProvider>(context, listen: false).logout();
                // Navigate to login screen - you might want to use Navigator.pushReplacement
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}

// User Profile Screen
class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.blue,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.name ?? 'No Name',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user?.email ?? 'No Email',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(
                      user?.role.toUpperCase() ?? 'USER',
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.blue,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contact Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.phone, user?.phoneNumber ?? 'Not provided'),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.location_on, user?.address ?? 'Not provided'),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.verified,
                    user?.isEmailVerified == true ? 'Email Verified' : 'Email Not Verified',
                    color: user?.isEmailVerified == true ? Colors.green : Colors.orange,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Account Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildActionButton(
                    'Edit Profile',
                    Icons.edit,
                    () {
                      // Navigate to edit profile screen
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildActionButton(
                    'Change Password',
                    Icons.lock,
                    () {
                      // Navigate to change password screen
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildActionButton(
                    'Contact Support',
                    Icons.support,
                    () {
                      // Navigate to support screen
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(icon, color: color ?? Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: color ?? Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String text, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}