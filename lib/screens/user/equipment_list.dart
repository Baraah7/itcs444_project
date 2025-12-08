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
    'Power Tools',
    'Hand Tools',
    'Electrical',
    'Plumbing',
    'Gardening',
    'Cleaning',
    'Safety',
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
        title: const Text("Browse Equipment"),
        centerTitle: true,
        actions: [
          // Removed add button for users
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
      color: Theme.of(context).primaryColor.withOpacity(0.05),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search equipment...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
          const SizedBox(height: 12),

          // Filter Row
          Row(
            children: [
              // Type Filter Dropdown
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedType,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down),
                      items: _equipmentTypes.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedType = newValue!;
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Availability Filter
              FilterChip(
                label: const Text('Available'),
                selected: _showOnlyAvailable,
                onSelected: (bool selected) {
                  setState(() {
                    _showOnlyAvailable = selected;
                  });
                },
                checkmarkColor: Colors.white,
                selectedColor: Colors.green,
                avatar: _showOnlyAvailable
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : const Icon(Icons.check, size: 16, color: Colors.grey),
              ),

              // Clear Filters Button
              if (_hasActiveFilters())
                IconButton(
                  icon: const Icon(Icons.filter_alt_off),
                  onPressed: _clearFilters,
                  tooltip: 'Clear filters',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.blue[50],
      child: Row(
        children: [
          const Icon(Icons.filter_list, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 8,
              children: [
                if (_searchQuery.isNotEmpty)
                  Chip(
                    label: Text('Search: $_searchQuery'),
                    onDeleted: () => _searchController.clear(),
                    deleteIcon: const Icon(Icons.close, size: 16),
                  ),
                if (_selectedType != 'All')
                  Chip(
                    label: Text('Type: $_selectedType'),
                    onDeleted: () => setState(() => _selectedType = 'All'),
                    deleteIcon: const Icon(Icons.close, size: 16),
                  ),
                if (_showOnlyAvailable)
                  Chip(
                    label: const Text('Available Only'),
                    onDeleted: () => setState(() => _showOnlyAvailable = false),
                    deleteIcon: const Icon(Icons.close, size: 16),
                  ),
              ],
            ),
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
          margin: const EdgeInsets.all(8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EquipmentDetailPage(
                    equipmentId: equipmentDoc.id,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Equipment Icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _getTypeColor(type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: _getEquipmentIcon(type, size: 30),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Equipment Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          type,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description.length > 60
                              ? '${description.substring(0, 60)}...'
                              : description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Availability Status
                  const SizedBox(width: 8),
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

                      final hasAvailableItems = snapshot.data!.docs.isNotEmpty;

                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: hasAvailableItems
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: hasAvailableItems
                                ? Colors.green
                                : Colors.red,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              hasAvailableItems
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              size: 14,
                              color: hasAvailableItems
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              hasAvailableItems ? 'Available' : 'Unavailable',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: hasAvailableItems
                                    ? Colors.green
                                    : Colors.red,
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
        childAspectRatio: 0.85,
      ),
      itemCount: equipmentDocs.length,
      itemBuilder: (context, index) {
        final equipmentDoc = equipmentDocs[index];
        final data = equipmentDoc.data() as Map<String, dynamic>;

        final name = data['name'] ?? 'Unnamed';
        final type = data['type'] ?? 'Other';

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EquipmentDetailPage(
                    equipmentId: equipmentDoc.id,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top icon section
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _getTypeColor(type).withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _getEquipmentIcon(type, size: 40),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            type,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _getTypeColor(type),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Content section
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),

                        // Availability status
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

                            final hasAvailableItems =
                                snapshot.data!.docs.isNotEmpty;

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: hasAvailableItems
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: hasAvailableItems
                                      ? Colors.green
                                      : Colors.red,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    hasAvailableItems
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    size: 12,
                                    color: hasAvailableItems
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    hasAvailableItems
                                        ? 'Available'
                                        : 'Unavailable',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: hasAvailableItems
                                          ? Colors.green
                                          : Colors.red,
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