import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'item_page.dart';
import 'add_edit_equipment.dart';

class EquipmentPage extends StatefulWidget {
  const EquipmentPage({super.key});

  @override
  State<EquipmentPage> createState() => _EquipmentPageState();
}

class _EquipmentPageState extends State<EquipmentPage> {
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
        title: const Text("Available Equipment"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddEditEquipmentPage()),
              );
            },
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
          child: ListTile(
            leading: _getEquipmentIcon(type),
            title: Text(name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(description),
                const SizedBox(height: 4),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('equipment')
                      .doc(equipmentDoc.id)
                      .collection('Items')
                      .snapshots(),
                  builder: (context, itemsSnapshot) {
                    if (!itemsSnapshot.hasData) {
                      return const SizedBox();
                    }

                    final totalItems = itemsSnapshot.data!.docs.length;
                    final availableItems = itemsSnapshot.data!.docs
                        .where((doc) => doc['availability'] == true)
                        .length;

                    return Row(
                      children: [
                        Chip(
                          label: Text(type),
                          backgroundColor: _getTypeColor(type),
                          labelStyle: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            const Icon(Icons.inventory, size: 14, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text('$availableItems/$totalItems'),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('equipment')
                      .doc(equipmentDoc.id)
                      .collection('Items')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox();
                    }

                    final total = snapshot.data!.docs.length;
                    final available = snapshot.data!.docs
                        .where((doc) => doc['availability'] == true)
                        .length;

                    return _buildAvailabilityIndicator(available, total);
                  },
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleMenuSelection(
                    value, equipmentDoc, name, description, type
                  ),
                  itemBuilder: (context) => _buildPopupMenuItems(),
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ItemsPage(
                    toolId: equipmentDoc.id,
                    toolName: name,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

Widget _buildGridView(List<QueryDocumentSnapshot> equipmentDocs) {
  return GridView.builder(
    padding: const EdgeInsets.all(8),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 0.9,
    ),
    itemCount: equipmentDocs.length,
    itemBuilder: (context, index) {
      final equipmentDoc = equipmentDocs[index];
      final data = equipmentDoc.data() as Map<String, dynamic>;

      final name = data['name'] ?? 'Unnamed';
      final description = data['description'] ?? '';
      final type = data['type'] ?? 'Other';

      return Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top container with icon and popup menu
            Stack(
              children: [
                Container(
                  height: 80,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _getTypeColor(type).withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                  child: Center(child: _getEquipmentIcon(type, size: 40)),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: PopupMenuButton<String>(
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 2,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.more_vert, size: 18),
                    ),
                    onSelected: (value) =>
                        _handleMenuSelection(value, equipmentDoc, name, description, type),
                    itemBuilder: (context) => _buildPopupMenuItems(),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),

            // Card content below the top container
            Expanded(
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ItemsPage(toolId: equipmentDoc.id, toolName: name),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        type,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('equipment')
                            .doc(equipmentDoc.id)
                            .collection('Items')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox();
                          final totalItems = snapshot.data!.docs.length;
                          final availableItems = snapshot.data!.docs
                              .where((doc) => doc['availability'] == true)
                              .length;
                          final availabilityPercent =
                              totalItems > 0 ? (availableItems / totalItems) * 100 : 0.0;

                          return LayoutBuilder(
                            builder: (context, constraints) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$availableItems/$totalItems',
                                    style: const TextStyle(fontSize: 9),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    width: constraints.maxWidth,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(2),
                                      color: Colors.grey[300],
                                    ),
                                    child: FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: availabilityPercent / 100,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(2),
                                          color: _getAvailabilityColor(availabilityPercent),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}



  Widget _buildAvailabilityIndicator(int available, int total) {
    final double percentage = total > 0 ? (available / total) * 100.0 : 0.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getAvailabilityColor(percentage).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getAvailabilityColor(percentage)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            available > 0 ? Icons.check_circle : Icons.error,
            size: 12,
            color: _getAvailabilityColor(percentage),
          ),
          const SizedBox(width: 4),
          Text(
            '$available/$total',
            style: TextStyle(
              fontSize: 12,
              color: _getAvailabilityColor(percentage),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityIcon(int available, int total) {
    if (available == 0) {
      return const Icon(Icons.error, color: Colors.red, size: 20);
    } else if (available < total) {
      return const Icon(Icons.warning, color: Colors.orange, size: 20);
    } else {
      return const Icon(Icons.check_circle, color: Colors.green, size: 20);
    }
  }

  Icon _getEquipmentIcon(String type, {double size = 24}) {
    switch (type.toLowerCase()) {
      case 'power tools':
        return Icon(Icons.build, color: Colors.blue, size: size);
      case 'hand tools':
        return Icon(Icons.handyman, color: Colors.green, size: size);
      case 'electrical':
        return Icon(Icons.electrical_services, color: Colors.yellow[700], size: size);
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

  Color _getAvailabilityColor(double percentage) {
    if (percentage == 0) return Colors.red;
    if (percentage < 50) return Colors.orange;
    if (percentage < 100) return Colors.yellow[700]!;
    return Colors.green;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.devices_other, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'No Equipment Found',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your first equipment by tapping the + button',
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
          Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _clearFilters,
            icon: const Icon(Icons.filter_alt_off),
            label: const Text('Clear Filters'),
          ),
        ],
      ),
    );
  }

  // ⭐⭐ FIXED: Async filter function that checks availability
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

      // ⭐ Apply availability filter by checking subcollection
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
    return _searchQuery.isNotEmpty || _selectedType != 'All' || _showOnlyAvailable;
  }

  List<PopupMenuItem<String>> _buildPopupMenuItems() {
    return [
      const PopupMenuItem(
        value: 'edit',
        child: Row(
          children: [
            Icon(Icons.edit, size: 20),
            SizedBox(width: 8),
            Text('Edit'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'delete',
        child: Row(
          children: [
            Icon(Icons.delete, color: Colors.red, size: 20),
            SizedBox(width: 8),
            Text('Delete', style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    ];
  }

  void _handleMenuSelection(
    String value,
    QueryDocumentSnapshot equipmentDoc,
    String name,
    String description,
    String type,
  ) async {
    if (value == 'edit') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddEditEquipmentPage(
            equipmentId: equipmentDoc.id,
            initialName: name,
            initialDescription: description,
            initialType: type,
          ),
        ),
      );
    } else if (value == 'delete') {
      await _showDeleteDialog(context, equipmentDoc.id, name);
    }
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    String equipmentId,
    String name,
  ) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Equipment'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final itemsSnapshot = await FirebaseFirestore.instance
                    .collection('equipment')
                    .doc(equipmentId)
                    .collection('Items')
                    .get();

                for (final doc in itemsSnapshot.docs) {
                  await doc.reference.delete();
                }

                await FirebaseFirestore.instance
                    .collection('equipment')
                    .doc(equipmentId)
                    .delete();

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Equipment deleted successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

enum ViewType { list, grid }