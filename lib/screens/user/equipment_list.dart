import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'equipment_detail.dart';

class UserEquipmentPage extends StatefulWidget {
  const UserEquipmentPage({super.key});

  @override
  State<UserEquipmentPage> createState() => _UserEquipmentPageState();
}

class _UserEquipmentPageState extends State<UserEquipmentPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedType = 'All';
  bool _showOnlyAvailable = false;
  ViewType _currentView = ViewType.list;

  // Medical equipment types
  final List<String> _equipmentTypes = [
    'All',
    'Mobility Aid',
    'Hospital Furniture',
    'Shower Chair',
    'Walker',
    'Wheelchair',
    'Crutches',
    'Commode',
    'Patient Lift',
    'Other',
  ];

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
      _selectedType = 'All';
      _showOnlyAvailable = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2B6C67),
        title: const Text(
          'Medical Equipment',
          style: TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // Search and Filter Section
          _buildFilterSection(),

          // Active Filters Display
          if (_hasActiveFilters()) _buildActiveFilters(),

          // Equipment List
          Expanded(
            child: _buildEquipmentList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          bottom: BorderSide(
            color: Color(0xFFE8ECEF),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A4A47).withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
          )
        ],
      ),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: 'Search medical equipment...',
              hintStyle: const TextStyle(
                color: Color(0xFF94A3B8),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              prefixIcon: const Icon(
                Icons.search,
                color: Color(0xFF64748B),
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Color(0xFF64748B),
                        size: 20,
                      ),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
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
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              // Type Dropdown
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE8ECEF),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedType,
                      isExpanded: true,
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Color(0xFF64748B),
                      ),
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      items: _equipmentTypes.map((value) {
                        return DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedType = value!);
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Availability Chip
              FilterChip(
                label: const Text(
                  "Available",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                selected: _showOnlyAvailable,
                selectedColor: const Color(0xFF10B981),
                backgroundColor: const Color(0xFFF8FAFC),
                labelStyle: TextStyle(
                  color: _showOnlyAvailable
                      ? Colors.white
                      : const Color(0xFF475569),
                  fontSize: 13,
                ),
                checkmarkColor: Colors.white,
                side: BorderSide(
                  color: _showOnlyAvailable
                      ? const Color(0xFF10B981)
                      : const Color(0xFFE8ECEF),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onSelected: (value) {
                  setState(() => _showOnlyAvailable = value);
                },
              ),

              const SizedBox(width: 8),

              // Clear Filters Button
              if (_hasActiveFilters())
                IconButton(
                  icon: const Icon(
                    Icons.filter_alt_off_rounded,
                    color: Color(0xFFEF4444),
                    size: 22,
                  ),
                  onPressed: _clearFilters,
                  tooltip: 'Clear all filters',
                ),

              // View Toggle Button
              IconButton(
                icon: Icon(
                  _currentView == ViewType.list
                      ? Icons.grid_view_rounded
                      : Icons.view_list_rounded,
                  color: const Color(0xFF2B6C67),
                  size: 22,
                ),
                onPressed: () {
                  setState(() {
                    _currentView = _currentView == ViewType.list
                        ? ViewType.grid
                        : ViewType.list;
                  });
                },
                tooltip: _currentView == ViewType.list
                    ? 'Switch to grid view'
                    : 'Switch to list view',
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF0F9F8),
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE8ECEF),
            width: 1,
          ),
        ),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        children: [
          if (_searchQuery.isNotEmpty)
            Chip(
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFE8ECEF)),
              label: Text('Search: $_searchQuery'),
              deleteIcon: const Icon(
                Icons.close,
                size: 16,
                color: Color(0xFF64748B),
              ),
              onDeleted: () => _searchController.clear(),
            ),
          if (_selectedType != 'All')
            Chip(
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFE8ECEF)),
              label: Text('Type: $_selectedType'),
              deleteIcon: const Icon(
                Icons.close,
                size: 16,
                color: Color(0xFF64748B),
              ),
              onDeleted: () => setState(() => _selectedType = 'All'),
            ),
          if (_showOnlyAvailable)
            Chip(
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFE8ECEF)),
              label: const Text('Available Only'),
              deleteIcon: const Icon(
                Icons.close,
                size: 16,
                color: Color(0xFF64748B),
              ),
              onDeleted: () => setState(() => _showOnlyAvailable = false),
            ),
        ],
      ),
    );
  }

  Widget _buildEquipmentList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('equipment').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF2B6C67),
            ),
          );
        }

        if (snapshot.hasError) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Color(0xFFEF4444),
                ),
                SizedBox(height: 16),
                Text(
                  'Error loading equipment',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w500,
                ),
                ),
                SizedBox(height: 8),
                Text(
                  'Please try again later',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        // Filter equipment using the async function
        return FutureBuilder<List<QueryDocumentSnapshot>>(
          future: _filterEquipmentAsync(snapshot.data!.docs),
          builder: (context, filterSnapshot) {
            if (filterSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF2B6C67),
                ),
              );
            }

            if (!filterSnapshot.hasData || filterSnapshot.data!.isEmpty) {
              return _buildNoResultsState();
            }

            final filteredDocs = filterSnapshot.data!;

            // Sort by name
            filteredDocs.sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              return (aData['name'] ?? '').compareTo(bData['name'] ?? '');
            });

            // Build based on view type
            return _currentView == ViewType.list
                ? _buildListView(filteredDocs)
                : _buildGridView(filteredDocs);
          },
        );
      },
    );
  }

  Widget _buildListView(List<QueryDocumentSnapshot> equipmentDocs) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: equipmentDocs.length,
      itemBuilder: (context, index) {
        final equipmentDoc = equipmentDocs[index];
        final data = equipmentDoc.data() as Map<String, dynamic>;

        final name = data['name'] ?? 'Unnamed';
        final description = data['description'] ?? '';
        final type = data['type'] ?? 'Other';

        // Get availability status
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('equipment')
              .doc(equipmentDoc.id)
              .collection('Items')
              .where('availability', isEqualTo: true)
              .snapshots(),
          builder: (context, snapshot) {
            final available = snapshot.hasData && snapshot.data!.docs.isNotEmpty;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: available
                      ? const Color(0xFFE8F4F3)
                      : const Color(0xFFF1F5F9),
                  width: 2,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          EquipmentDetailPage(equipmentId: equipmentDoc.id),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Icon Section with gradient background
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: available
                                ? [
                                    const Color(0xFFE8F4F3),
                                    const Color(0xFFD1EAE8),
                                  ]
                                : [
                                    const Color(0xFFF1F5F9),
                                    const Color(0xFFE2E8F0),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: available
                                ? const Color(0xFFB8E6E0)
                                : const Color(0xFFCBD5E1),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: _getEquipmentIcon(
                            type,
                            size: 34,
                            available: available,
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Text Section
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: available
                                          ? const Color(0xFF1E293B)
                                          : const Color(0xFF94A3B8),
                                      letterSpacing: -0.1,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // Availability badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: available
                                        ? const Color(0xFF10B981)
                                            .withOpacity(0.1)
                                        : const Color(0xFFEF4444)
                                            .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: available
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFEF4444),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    available ? 'Available' : 'Out of Stock',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: available
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFEF4444),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: available
                                    ? const Color(0xFFF0F9F8)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                type,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: available
                                      ? const Color(0xFF2B6C67)
                                      : const Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              description.length > 60
                                  ? '${description.substring(0, 60)}...'
                                  : description,
                              style: TextStyle(
                                fontSize: 13,
                                color: available
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFF94A3B8),
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
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

  Widget _buildGridView(List<QueryDocumentSnapshot> equipmentDocs) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.78,
      ),
      itemCount: equipmentDocs.length,
      itemBuilder: (context, index) {
        final equipmentDoc = equipmentDocs[index];
        final data = equipmentDoc.data() as Map<String, dynamic>;

        final name = data['name'] ?? 'Unnamed';
        final description = data['description'] ?? '';
        final type = data['type'] ?? 'Other';

        // Get availability status
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('equipment')
              .doc(equipmentDoc.id)
              .collection('Items')
              .where('availability', isEqualTo: true)
              .snapshots(),
          builder: (context, snapshot) {
            final available = snapshot.hasData && snapshot.data!.docs.isNotEmpty;

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: available
                      ? const Color(0xFFE8F4F3)
                      : const Color(0xFFF1F5F9),
                  width: 2,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          EquipmentDetailPage(equipmentId: equipmentDoc.id),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon area with gradient
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: available
                              ? [
                                  const Color(0xFFE8F4F3),
                                  const Color(0xFFD1EAE8),
                                ]
                              : [
                                  const Color(0xFFF1F5F9),
                                  const Color(0xFFE2E8F0),
                                ],
                        ),
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: Center(
                        child: _getEquipmentIcon(
                          type,
                          size: 48,
                          available: available,
                        ),
                      ),
                    ),

                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name with availability badge
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: available
                                          ? const Color(0xFF1E293B)
                                          : const Color(0xFF94A3B8),
                                      letterSpacing: -0.1,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: available
                                        ? const Color(0xFF10B981)
                                            .withOpacity(0.1)
                                        : const Color(0xFFEF4444)
                                            .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    available ? '✓' : '✗',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: available
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFEF4444),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Type tag
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: available
                                    ? const Color(0xFFF0F9F8)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                type,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: available
                                      ? const Color(0xFF2B6C67)
                                      : const Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Description
                            Expanded(
                              child: Text(
                                description.length > 60
                                    ? '${description.substring(0, 60)}...'
                                    : description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: available
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFF94A3B8),
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Availability status bar
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: available
                                    ? const Color(0xFF10B981)
                                        .withOpacity(0.1)
                                    : const Color(0xFFEF4444)
                                        .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: available
                                      ? const Color(0xFF10B981)
                                          .withOpacity(0.3)
                                      : const Color(0xFFEF4444)
                                          .withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    available
                                        ? Icons.check_circle
                                        : Icons.cancel_outlined,
                                    size: 14,
                                    color: available
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFEF4444),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    available ? 'Available' : 'Out of Stock',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: available
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFEF4444),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Icon _getEquipmentIcon(String type,
      {double size = 24, bool available = true}) {
    final color = available ? const Color(0xFF2B6C67) : const Color(0xFF94A3B8);

    switch (type.toLowerCase()) {
      case 'mobility aid':
        return Icon(Icons.accessibility_new, color: color, size: size);
      case 'hospital furniture':
        return Icon(Icons.king_bed, color: color, size: size);
      case 'shower chair':
        return Icon(Icons.chair, color: color, size: size);
      case 'walker':
        return Icon(Icons.directions_walk, color: color, size: size);
      case 'wheelchair':
        return Icon(Icons.accessible, color: color, size: size);
      case 'crutches':
        return Icon(Icons.sports, color: color, size: size);
      case 'commode':
        return Icon(Icons.bathroom, color: color, size: size);
      case 'patient lift':
        return Icon(Icons.arrow_upward, color: color, size: size);
      default:
        return Icon(Icons.medical_services, color: color, size: size);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9F8),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.medical_services_outlined,
              size: 60,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Equipment Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Check back later for available medical equipment',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9F8),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.search_off,
              size: 60,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Results Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Try adjusting your search or filters to find what you\'re looking for',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _clearFilters,
            icon: const Icon(Icons.filter_alt_off, size: 20),
            label: const Text(
              'Clear All Filters',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2B6C67),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              shadowColor: const Color(0xFF2B6C67).withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  // Async filter function that checks availability
  Future<List<QueryDocumentSnapshot>> _filterEquipmentAsync(
    List<QueryDocumentSnapshot> docs,
  ) async {
    final List<QueryDocumentSnapshot> result = [];

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      final name = data['name']?.toString().toLowerCase() ?? '';
      final description = data['description']?.toString().toLowerCase() ?? '';
      final type = data['type']?.toString() ?? 'Other';

      // Apply search filter
      final matchesSearch = _searchQuery.isEmpty ||
          name.contains(_searchQuery.toLowerCase()) ||
          description.contains(_searchQuery.toLowerCase());

      // Apply type filter
      final matchesType = _selectedType == 'All' || type == _selectedType;

      // If availability filter is OFF, skip the expensive check
      if (!_showOnlyAvailable) {
        if (matchesSearch && matchesType) {
          result.add(doc);
        }
        continue;
      }

      // Apply availability filter by checking subcollection
      try {
        final itemsSnapshot = await FirebaseFirestore.instance
            .collection('equipment')
            .doc(doc.id)
            .collection('Items')
            .where('availability', isEqualTo: true)
            .limit(1) // We only need to know if ANY item is available
            .get();

        final hasAvailableItems = itemsSnapshot.docs.isNotEmpty;

        if (matchesSearch && matchesType && hasAvailableItems) {
          result.add(doc);
        }
      } catch (e) {
        // If there's an error, include the item anyway
        if (matchesSearch && matchesType) {
          result.add(doc);
        }
      }
    }

    return result;
  }

  bool _hasActiveFilters() {
    return _searchQuery.isNotEmpty ||
        _selectedType != 'All' ||
        _showOnlyAvailable;
  }
}

enum ViewType { list, grid }