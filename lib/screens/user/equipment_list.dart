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

  // Equipment types from Firestore
  final List<String> _equipmentTypes = [
    'All',
    'Mobility Aid',
    'Hospital Furniture',
    'Shower Chair',
    'Walker',
    'Other', // Check thiiiiiiiiiiiiiiiiiiiiiiiiiiiiiis
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
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          offset: const Offset(0, 3),
          blurRadius: 6,
        )
      ],
    ),
    child: Column(
      children: [
        // Search Bar
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search equipment...',
            filled: true,
            fillColor: Colors.grey[100],
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => _searchController.clear(),
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        const SizedBox(height: 14),

        Row(
          children: [
            // Type Dropdown
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(14),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedType,
                    isExpanded: true,
                    items: _equipmentTypes.map((value) {
                      return DropdownMenuItem(
                        value: value,
                        child: Text(value, style: const TextStyle(fontSize: 14)),
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
              label: const Text("Available"),
              selected: _showOnlyAvailable,
              selectedColor: Colors.green.shade400,
              backgroundColor: Colors.grey.shade200,
              labelStyle: TextStyle(
                color: _showOnlyAvailable ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
              checkmarkColor: Colors.white,
              onSelected: (value) {
                setState(() => _showOnlyAvailable = value);
              },
            ),

            if (_hasActiveFilters())
              IconButton(
                icon: const Icon(Icons.filter_alt_off_rounded),
                onPressed: _clearFilters,
              ),
              IconButton(
            icon: Icon(_currentView == ViewType.list ? Icons.grid_view : Icons.list),
            onPressed: () {
              setState(() {
                _currentView = _currentView == ViewType.list
                    ? ViewType.grid
                    : ViewType.list;
              });
            },
            tooltip: 'Change view',
          ),
          ],
        )
      ],
    ),
  );
}


  Widget _buildActiveFilters() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.blue.shade50,
      border: Border(
        bottom: BorderSide(color: Colors.blue.shade100),
      ),
    ),
    child: Wrap(
      spacing: 10,
      children: [
        if (_searchQuery.isNotEmpty)
          Chip(
            backgroundColor: Colors.white,
            label: Text('Search: $_searchQuery'),
            deleteIcon: const Icon(Icons.close),
            onDeleted: () => _searchController.clear(),
          ),
        if (_selectedType != 'All')
          Chip(
            backgroundColor: Colors.white,
            label: Text('Type: $_selectedType'),
            deleteIcon: const Icon(Icons.close),
            onDeleted: () => setState(() => _selectedType = 'All'),
          ),
        if (_showOnlyAvailable)
          Chip(
            backgroundColor: Colors.white,
            label: const Text('Available Only'),
            deleteIcon: const Icon(Icons.close),
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
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        // Filter equipment using the async function
        return FutureBuilder<List<QueryDocumentSnapshot>>(
          future: _filterEquipmentAsync(snapshot.data!.docs),
          builder: (context, filterSnapshot) {
            if (filterSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
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
      itemCount: equipmentDocs.length,
      itemBuilder: (context, index) {
        final equipmentDoc = equipmentDocs[index];
        final data = equipmentDoc.data() as Map<String, dynamic>;

        final name = data['name'] ?? 'Unnamed';
        final description = data['description'] ?? '';
        final type = data['type'] ?? 'Other';

        return Card(
          color: Colors.white,
  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  elevation: 3,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  ),
  child: InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EquipmentDetailPage(equipmentId: equipmentDoc.id),
        ),
      );
    },
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Icon Section
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: _getTypeColor(type).withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: _getEquipmentIcon(type, size: 32),
            ),
          ),

          const SizedBox(width: 14),

          // Text Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  type,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 6),
                Text(
                  description.length > 60
                      ? '${description.substring(0, 60)}...'
                      : description,
                  style: TextStyle(color: Colors.grey.shade700),
                  maxLines: 2,
                )
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Availability badge
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('equipment')
                .doc(equipmentDoc.id)
                .collection('Items')
                .where('availability', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox();
              }

              final available = snapshot.data!.docs.isNotEmpty;

              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color:
                      available ? Colors.green.shade50 : Colors.red.shade50,
                  // border: Border.all(
                  //   color: available ? Colors.green : Colors.red,
                  // ),
                ),
                child: Row(
                  children: [
                    Icon(
                      available ? Icons.check_circle : Icons.cancel,
                      size: 14,
                      color: available ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      available ? 'Available' : 'Unavailable',
                      style: TextStyle(
                        fontSize: 12,
                        color: available ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    ),
  ),
);

      },
    );
  }

  Widget _buildGridView(List<QueryDocumentSnapshot> equipmentDocs) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: equipmentDocs.length,
      itemBuilder: (context, index) {
        final equipmentDoc = equipmentDocs[index];
        final data = equipmentDoc.data() as Map<String, dynamic>;

        final name = data['name'] ?? 'Unnamed';
        final description = data['description'] ?? '';
        final type = data['type'] ?? 'Other';

        return Card(
  elevation: 3,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(18),
  ),
  child: InkWell(
    borderRadius: BorderRadius.circular(18),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EquipmentDetailPage(equipmentId: equipmentDoc.id),
        ),
      );
    },
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon area
        Container(
          height: 110,
          decoration: BoxDecoration(
            color: _getTypeColor(type).withOpacity(0.12),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Center(
            child: _getEquipmentIcon(type, size: 45),
          ),
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  type,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description.length > 60
                      ? '${description.substring(0, 60)}...'
                      : description,
                  style: TextStyle(color: Colors.grey.shade700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Availability badge
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('equipment')
                      .doc(equipmentDoc.id)
                      .collection('Items')
                      .where('availability', isEqualTo: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();

                    final available = snapshot.data!.docs.isNotEmpty;

                    return Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: available
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        // border: Border.all(
                        //   color: available ? Colors.green : Colors.red,
                        // ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        available ? 'Available' : 'Unavailable',
                        style: TextStyle(
                          fontSize: 10,
                          color: available ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
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
  }

  Icon _getEquipmentIcon(String type, {double size = 24}) {
    switch (type.toLowerCase()) {
      case 'power tools':
        return Icon(Icons.build, color: Colors.blue, size: size);
      case 'hand tools':
        return Icon(Icons.handyman, color: Colors.green, size: size);
      case 'electrical':
        return Icon(Icons.electrical_services,
            color: Colors.yellow[700], size: size);
      case 'plumbing':
        return Icon(Icons.plumbing, color: Colors.blue[300], size: size);
      case 'gardening':
        return Icon(Icons.nature, color: Colors.green[700], size: size);
      case 'cleaning':
        return Icon(Icons.cleaning_services, color: Colors.cyan, size: size);
      case 'safety':
        return Icon(Icons.security, color: Colors.red, size: size);
      default:
        return Icon(Icons.devices_other, color: Colors.grey, size: size);
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'power tools':
        return Colors.blue;
      case 'hand tools':
        return Colors.green;
      case 'electrical':
        return Colors.yellow[700]!;
      case 'plumbing':
        return Colors.blue[300]!;
      case 'gardening':
        return Colors.green[700]!;
      case 'cleaning':
        return Colors.cyan;
      case 'safety':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.devices_other, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          const Text(
            'No Equipment Found',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Check back later for available equipment',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          const Text(
            'No Results Found',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your search or filters',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _clearFilters,
            icon: const Icon(Icons.filter_alt_off),
            label: const Text('Clear Filters'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
