import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class UsersManagement extends StatefulWidget {
  const UsersManagement({super.key});

  @override
  State<UsersManagement> createState() => _UsersManagementState();
}

class _UsersManagementState extends State<UsersManagement> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedRole = 'All';
  String _selectedStatus = 'All';
  bool _isLoading = false;

  final List<String> _userRoles = ['All', 'Admin', 'User'];
  final List<String> _userStatuses = ['All', 'Active', 'Inactive', 'Suspended', 'Pending'];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedRole = 'All';
      _selectedStatus = 'All';
    });
  }

  Future<void> _updateUserStatus(String userId, String newStatus) async {
    try {
      setState(() => _isLoading = true);
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User status updated to $newStatus'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateUserRole(String userId, String newRole) async {
    try {
      setState(() => _isLoading = true);
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User role updated to $newRole'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _suspendUser(String userId, String userName) async {
    final result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Suspend User',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        content: Text(
          'Are you sure you want to suspend $userName? They will not be able to access the system until reactivated.',
          style: const TextStyle(
            color: Color(0xFF64748B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
            ),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Suspend'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );

    if (result == true) {
      await _updateUserStatus(userId, 'Suspended');
    }
  }

  Future<void> _deleteUser(String userId, String userName) async {
    final result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Delete User',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        content: Text(
          'Are you sure you want to permanently delete $userName? This action cannot be undone.',
          style: const TextStyle(
            color: Color(0xFF64748B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
            ),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Delete'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );

    if (result == true) {
      try {
        setState(() => _isLoading = true);
        await FirebaseFirestore.instance.collection('users').doc(userId).delete();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('User deleted successfully'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _showUserDetails(Map<String, dynamic> userData) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'User Details',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _userDetailRow('Name', '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'),
              _userDetailRow('Email', userData['email'] ?? ''),
              _userDetailRow('Phone', userData['phoneNumber'] ?? ''),
              _userDetailRow('CPR Number', userData['cpr'] ?? ''),
              _userDetailRow('Role', userData['role'] ?? ''),
              _userDetailRow('Status', userData['status'] ?? ''),
              _userDetailRow('Join Date', 
                userData['createdAt'] is Timestamp
                    ? DateFormat('MMM dd, yyyy').format((userData['createdAt'] as Timestamp).toDate())
                    : 'N/A'
              ),
              const SizedBox(height: 16),
              if (userData['address'] != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Address:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userData['address'],
                      style: const TextStyle(
                        color: Color(0xFF64748B),
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
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
            ),
            child: const Text('Close'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _userDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'N/A',
              style: const TextStyle(
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'User Management',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
            fontSize: 20,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: Column(
        children: [
          // Stats Overview
          _buildStatsOverview(),
          
          // Search and Filters
          _buildFilterSection(),
          
          // Users List
          Expanded(
            child: _buildUsersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: List.generate(4, (index) => Expanded(child: _buildLoadingStat())),
            ),
          );
        }

        final users = snapshot.data!.docs;
        final totalUsers = users.length;
        final activeUsers = users.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'Active';
        }).length;
        final admins = users.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['role'] == 'Admin';
        }).length;
        final pendingUsers = users.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'Pending';
        }).length;

        return Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              _buildStatCard('Total Users', totalUsers.toString(), Icons.people, const Color(0xFF2B6C67)),
              const SizedBox(width: 12),
              _buildStatCard('Active', activeUsers.toString(), Icons.check_circle, const Color(0xFF10B981)),
              const SizedBox(width: 12),
              _buildStatCard('Admins', admins.toString(), Icons.admin_panel_settings, const Color(0xFF8B5CF6)),
              const SizedBox(width: 12),
              _buildStatCard('Pending', pendingUsers.toString(), Icons.pending, const Color(0xFFF59E0B)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingStat() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8ECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9F8),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9F8),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 60,
            height: 14,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9F8),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE8ECEF)),
        ),
      ),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search users by name, email, or phone...',
              hintStyle: const TextStyle(color: Color(0xFF64748B)),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20, color: Color(0xFF64748B)),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE8ECEF)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE8ECEF)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2B6C67)),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          const SizedBox(height: 12),
          
          // Filter Row
          Row(
            children: [
              // Role Filter
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE8ECEF)),
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFFF8FAFC),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedRole,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 14,
                      ),
                      items: _userRoles.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedRole = newValue!;
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              
              // Status Filter
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE8ECEF)),
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFFF8FAFC),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedStatus,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 14,
                      ),
                      items: _userStatuses.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedStatus = newValue!;
                        });
                      },
                    ),
                  ),
                ),
              ),
              
              // Clear Filters Button
              if (_hasActiveFilters())
                IconButton(
                  icon: const Icon(Icons.filter_alt_off, color: Color(0xFFEF4444)),
                  onPressed: _clearFilters,
                  tooltip: 'Clear filters',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (_isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF2B6C67)),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF2B6C67)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Color(0xFFEF4444)),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final users = snapshot.data!.docs;
        final filteredUsers = _filterUsers(users);

        if (filteredUsers.isEmpty) {
          return _buildNoResultsState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            final userDoc = filteredUsers[index];
            final userData = userDoc.data() as Map<String, dynamic>;

            final firstName = userData['firstName'] ?? '';
            final lastName = userData['lastName'] ?? '';
            final email = userData['email'] ?? '';
            final role = userData['role'] ?? 'User';
            final status = userData['status'] ?? 'Active';
            final createdAt = userData['createdAt'] is Timestamp
                ? (userData['createdAt'] as Timestamp).toDate()
                : null;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // User Avatar
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: _getRoleColor(role).withOpacity(0.1),
                        child: Text(
                          firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: _getRoleColor(role),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // User Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$firstName $lastName',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getRoleColor(role).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    role,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _getRoleColor(role),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(status).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _getStatusColor(status),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Join Date and Menu
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (createdAt != null)
                            Text(
                              DateFormat('MMM dd, yyyy').format(createdAt),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          const SizedBox(height: 8),
                          _buildUserMenuButton(userDoc.id, userData, firstName),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUserMenuButton(String userId, Map<String, dynamic> userData, String userName) {
    final role = userData['role'] ?? 'User';
    final status = userData['status'] ?? 'Active';
    
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Color(0xFF64748B), size: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      onSelected: (value) {
        _handleMenuSelection(value, userId, userData, userName);
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'details',
          child: const Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: Color(0xFF2B6C67)),
              SizedBox(width: 8),
              Text('View Details', style: TextStyle(color: Color(0xFF1E293B))),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'role',
          child: Row(
            children: [
              const Icon(Icons.badge, size: 18, color: Color(0xFF8B5CF6)),
              const SizedBox(width: 8),
              const Text('Change Role', style: TextStyle(color: Color(0xFF8B5CF6))),
              const Spacer(),
              Text(
                role,
                style: TextStyle(
                  fontSize: 11,
                  color: _getRoleColor(role),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'status',
          child: Row(
            children: [
              const Icon(Icons.toggle_on, size: 18, color: Color(0xFF10B981)),
              const SizedBox(width: 8),
              const Text('Change Status', style: TextStyle(color: Color(0xFF10B981))),
              const Spacer(),
              Text(
                status,
                style: TextStyle(
                  fontSize: 11,
                  color: _getStatusColor(status),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (status != 'Suspended')
          const PopupMenuItem(
            value: 'suspend',
            child: Row(
              children: [
                Icon(Icons.pause_circle_outline, size: 18, color: Color(0xFFF59E0B)),
                SizedBox(width: 8),
                Text('Suspend User', style: TextStyle(color: Color(0xFFF59E0B))),
              ],
            ),
          ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
              SizedBox(width: 8),
              Text('Delete User', style: TextStyle(color: Color(0xFFEF4444))),
            ],
          ),
        ),
      ],
    );
  }

  void _handleMenuSelection(String value, String userId, Map<String, dynamic> userData, String userName) async {
    switch (value) {
      case 'details':
        await _showUserDetails(userData);
        break;
      case 'role':
        await _showRoleSelector(userId, userData['role'] ?? 'User', userName);
        break;
      case 'status':
        await _showStatusSelector(userId, userData['status'] ?? 'Active', userName);
        break;
      case 'suspend':
        await _suspendUser(userId, userName);
        break;
      case 'delete':
        await _deleteUser(userId, userName);
        break;
    }
  }

  Future<void> _showRoleSelector(String userId, String currentRole, String userName) async {
    String? newRole = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Change User Role',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select new role for $userName:',
              style: const TextStyle(
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            ...['User', 'Volunteer', 'Staff', 'Admin'].map((role) {
              return RadioListTile<String>(
                title: Text(role),
                value: role,
                groupValue: currentRole,
                onChanged: (value) {
                  Navigator.pop(context, value);
                },
                activeColor: const Color(0xFF2B6C67),
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
            ),
            child: const Text('Cancel'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );

    if (newRole != null && newRole != currentRole) {
      await _updateUserRole(userId, newRole);
    }
  }

  Future<void> _showStatusSelector(String userId, String currentStatus, String userName) async {
    String? newStatus = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Change User Status',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select new status for $userName:',
              style: const TextStyle(
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            ...['Active', 'Inactive', 'Pending', 'Suspended'].map((status) {
              return RadioListTile<String>(
                title: Text(status),
                value: status,
                groupValue: currentStatus,
                onChanged: (value) {
                  Navigator.pop(context, value);
                },
                activeColor: const Color(0xFF2B6C67),
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
            ),
            child: const Text('Cancel'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );

    if (newStatus != null && newStatus != currentStatus) {
      await _updateUserStatus(userId, newStatus);
    }
  }

  List<QueryDocumentSnapshot> _filterUsers(List<QueryDocumentSnapshot> users) {
    return users.where((userDoc) {
      final userData = userDoc.data() as Map<String, dynamic>;
      
      final firstName = userData['firstName']?.toString().toLowerCase() ?? '';
      final lastName = userData['lastName']?.toString().toLowerCase() ?? '';
      final email = userData['email']?.toString().toLowerCase() ?? '';
      final phone = userData['phoneNumber']?.toString().toLowerCase() ?? '';
      final role = userData['role']?.toString() ?? 'User';
      final status = userData['status']?.toString() ?? 'Active';
      
      // Apply search filter
      final matchesSearch = _searchQuery.isEmpty ||
          firstName.contains(_searchQuery.toLowerCase()) ||
          lastName.contains(_searchQuery.toLowerCase()) ||
          email.contains(_searchQuery.toLowerCase()) ||
          phone.contains(_searchQuery.toLowerCase());
      
      // Apply role filter
      final matchesRole = _selectedRole == 'All' || role == _selectedRole;
      
      // Apply status filter
      final matchesStatus = _selectedStatus == 'All' || status == _selectedStatus;
      
      return matchesSearch && matchesRole && matchesStatus;
    }).toList();
  }

  bool _hasActiveFilters() {
    return _searchQuery.isNotEmpty || _selectedRole != 'All' || _selectedStatus != 'All';
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return const Color(0xFF8B5CF6);
      case 'staff':
        return const Color(0xFF3B82F6);
      case 'volunteer':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return const Color(0xFF10B981);
      case 'inactive':
        return const Color(0xFF64748B);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'suspended':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: const Color(0xFFE8ECEF),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Users Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Users will appear here once they register',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: const Color(0xFFE8ECEF),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Users Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try adjusting your search or filters',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _clearFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF64748B),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFFE8ECEF)),
                ),
              ),
              icon: const Icon(Icons.filter_alt_off, size: 20),
              label: const Text('Clear Filters'),
            ),
          ],
        ),
      ),
    );
  }
}