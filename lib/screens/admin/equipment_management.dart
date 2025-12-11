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
  
  final List<String> _equipmentTypes = [
    'All',
    'Power Tools',
    'Hand Tools',
    'Electrical',
    'Plumbing',
    'Gardening',
    'Cleaning',
    'Safety',
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Equipment Management',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _currentView == ViewType.list ? Icons.grid_view : Icons.list,
              color: const Color(0xFF2B6C67),
            ),
            onPressed: () {
              setState(() {
                _currentView = _currentView == ViewType.list 
                  ? ViewType.grid 
                  : ViewType.list;
              });
            },
            tooltip: _currentView == ViewType.list ? 'Grid View' : 'List View',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2B6C67),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddEditEquipmentPage()),
                );
              },
              tooltip: 'Add Equipment',
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFE8ECEF),
            height: 1,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          if (_hasActiveFilters()) _buildActiveFilters(),
          Expanded(child: _buildEquipmentList()),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8ECEF)),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search equipment...',
                hintStyle: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF64748B),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () => _searchController.clear(),
                        color: const Color(0xFF64748B),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Filter Row
          Row(
            children: [
              // Type Filter Dropdown
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    border: Border.all(color: const Color(0xFFE8ECEF)),
                    borderRadius: BorderRadius.circular(12),
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
                        fontSize: 14,
                        color: Color(0xFF1E293B),
                      ),
                      items: _equipmentTypes.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() => _selectedType = newValue!);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Availability Filter
              FilterChip(
                label: const Text(
                  'Available',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                selected: _showOnlyAvailable,
                onSelected: (bool selected) {
                  setState(() => _showOnlyAvailable = selected);
                },
                checkmarkColor: Colors.white,
                selectedColor: const Color(0xFF2B6C67),
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: _showOnlyAvailable
                      ? const Color(0xFF2B6C67)
                      : const Color(0xFFE8ECEF),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              
              // Clear Filters Button
              if (_hasActiveFilters())
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: IconButton(
                    icon: const Icon(Icons.filter_alt_off),
                    onPressed: _clearFilters,
                    tooltip: 'Clear filters',
                    color: const Color(0xFF64748B),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF0F9F8),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE8ECEF)),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list, size: 16, color: Color(0xFF2B6C67)),
          const SizedBox(width: 8),
          const Text(
            'Active Filters:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2B6C67),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 8,
              children: [
                if (_searchQuery.isNotEmpty)
                  Chip(
                    label: Text('Search: $_searchQuery'),
                    onDeleted: () => _searchController.clear(),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFE8ECEF)),
                    labelStyle: const TextStyle(fontSize: 12),
                  ),
                if (_selectedType != 'All')
                  Chip(
                    label: Text('Type: $_selectedType'),
                    onDeleted: () => setState(() => _selectedType = 'All'),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFE8ECEF)),
                    labelStyle: const TextStyle(fontSize: 12),
                  ),
                if (_showOnlyAvailable)
                  Chip(
                    label: const Text('Available Only'),
                    onDeleted: () => setState(() => _showOnlyAvailable = false),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFE8ECEF)),
                    labelStyle: const TextStyle(fontSize: 12),
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
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF2B6C67),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 60, color: Color(0xFFEF4444)),
                const SizedBox(height: 16),
                const Text(
                  'Error loading equipment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

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
            filteredDocs.sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              return (aData['name'] ?? '').compareTo(bData['name'] ?? '');
            });

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
      padding: const EdgeInsets.all(20),
      itemCount: equipmentDocs.length,
      itemBuilder: (context, index) {
        final equipmentDoc = equipmentDocs[index];
        final data = equipmentDoc.data() as Map<String, dynamic>;

        final name = data['name'] ?? 'Unnamed';
        final description = data['description'] ?? '';
        final type = data['type'] ?? 'Other';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8ECEF)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A4A47).withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getTypeColor(type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _getEquipmentIcon(type, size: 28),
            ),
            title: Text(
              name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getTypeColor(type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _getTypeColor(type).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        type,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _getTypeColor(type),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
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

                        return _buildAvailabilityIndicator(
                          availableItems,
                          totalItems,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert,
                color: Color(0xFF64748B),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) => _handleMenuSelection(
                value,
                equipmentDoc,
                name,
                description,
                type,
              ),
              itemBuilder: (context) => _buildPopupMenuItems(),
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
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: equipmentDocs.length,
      itemBuilder: (context, index) {
        final equipmentDoc = equipmentDocs[index];
        final data = equipmentDoc.data() as Map<String, dynamic>;

        final name = data['name'] ?? 'Unnamed';
        final description = data['description'] ?? '';
        final type = data['type'] ?? 'Other';

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8ECEF)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A4A47).withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and menu
              Stack(
                children: [
                  Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _getTypeColor(type).withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Center(
                      child: _getEquipmentIcon(type, size: 48),
                    ),
                  ),
                  Positioned(
                    right: 4,
                    top: 4,
                    child: PopupMenuButton<String>(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.more_vert,
                          size: 18,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (value) => _handleMenuSelection(
                        value,
                        equipmentDoc,
                        name,
                        description,
                        type,
                      ),
                      itemBuilder: (context) => _buildPopupMenuItems(),
                    ),
                  ),
                ],
              ),

              // Content
              Expanded(
                child: InkWell(
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
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _getTypeColor(type).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            type,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _getTypeColor(type),
                            ),
                          ),
                        ),
                        const Spacer(),
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
                            final availabilityPercent = totalItems > 0
                                ? (availableItems / totalItems) * 100
                                : 0.0;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$availableItems/$totalItems available',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(2),
                                    color: const Color(0xFFE8ECEF),
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: availabilityPercent / 100,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(2),
                                        color: _getAvailabilityColor(
                                          availabilityPercent,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getAvailabilityColor(percentage).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: _getAvailabilityColor(percentage).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            available > 0 ? Icons.check_circle : Icons.error,
            size: 14,
            color: _getAvailabilityColor(percentage),
          ),
          const SizedBox(width: 4),
          Text(
            '$available/$total',
            style: TextStyle(
              fontSize: 12,
              color: _getAvailabilityColor(percentage),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Icon _getEquipmentIcon(String type, {double size = 24}) {
    switch (type.toLowerCase()) {
      case 'power tools':
        return Icon(Icons.build, color: const Color(0xFF3B82F6), size: size);
      case 'hand tools':
        return Icon(Icons.handyman, color: const Color(0xFF10B981), size: size);
      case 'electrical':
        return Icon(Icons.electrical_services, color: const Color(0xFFF59E0B), size: size);
      case 'plumbing':
        return Icon(Icons.plumbing, color: const Color(0xFF06B6D4), size: size);
      case 'gardening':
        return Icon(Icons.nature, color: const Color(0xFF22C55E), size: size);
      case 'cleaning':
        return Icon(Icons.cleaning_services, color: const Color(0xFF8B5CF6), size: size);
      case 'safety':
        return Icon(Icons.security, color: const Color(0xFFEF4444), size: size);
      default:
        return Icon(Icons.devices_other, color: const Color(0xFF64748B), size: size);
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'power tools':
        return const Color(0xFF3B82F6);
      case 'hand tools':
        return const Color(0xFF10B981);
      case 'electrical':
        return const Color(0xFFF59E0B);
      case 'plumbing':
        return const Color(0xFF06B6D4);
      case 'gardening':
        return const Color(0xFF22C55E);
      case 'cleaning':
        return const Color(0xFF8B5CF6);
      case 'safety':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _getAvailabilityColor(double percentage) {
    if (percentage == 0) return const Color(0xFFEF4444);
    if (percentage < 50) return const Color(0xFFF59E0B);
    if (percentage < 100) return const Color(0xFFFBBF24);
    return const Color(0xFF10B981);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFE8ECEF),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.devices_other,
                size: 64,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Equipment Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your first equipment by tapping the + button',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
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
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFE8ECEF),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.search_off,
                size: 64,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Results Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try adjusting your search or filters',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.filter_alt_off, size: 20),
              label: const Text('Clear Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2B6C67),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<QueryDocumentSnapshot>> _filterEquipmentAsync(
    List<QueryDocumentSnapshot> docs,
  ) async {
    final List<QueryDocumentSnapshot> result = [];

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      final name = data['name']?.toString().toLowerCase() ?? '';
      final description = data['description']?.toString().toLowerCase() ?? '';
      final type = data['type']?.toString() ?? 'Other';

      final matchesSearch = _searchQuery.isEmpty ||
          name.contains(_searchQuery.toLowerCase()) ||
          description.contains(_searchQuery.toLowerCase());

      final matchesType = _selectedType == 'All' || type == _selectedType;

      if (!_showOnlyAvailable) {
        if (matchesSearch && matchesType) {
          result.add(doc);
        }
        continue;
      }

      try {
        final itemsSnapshot = await FirebaseFirestore.instance
            .collection('equipment')
            .doc(doc.id)
            .collection('Items')
            .where('availability', isEqualTo: true)
            .limit(1)
            .get();

        final hasAvailableItems = itemsSnapshot.docs.isNotEmpty;

        if (matchesSearch && matchesType && hasAvailableItems) {
          result.add(doc);
        }
      } catch (e) {
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

  List<PopupMenuItem<String>> _buildPopupMenuItems() {
    return [
      const PopupMenuItem(
        value: 'edit',
        child: Row(
          children: [
            Icon(Icons.edit, size: 18, color: Color(0xFF2B6C67)),
            SizedBox(width: 12),
            Text('Edit'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'maintenance',
        child: Row(
          children: [
            Icon(Icons.build, color: Color(0xFF8B5CF6), size: 18),
            SizedBox(width: 12),
            Text('Mark for Maintenance'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'delete',
        child: Row(
          children: [
            Icon(Icons.delete, color: Color(0xFFEF4444), size: 18),
            SizedBox(width: 12),
            Text('Delete', style: TextStyle(color: Color(0xFFEF4444))),
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
    } else if (value == 'maintenance') {
      await _showMaintenanceDialog(context, equipmentDoc.id, name);
    } else if (value == 'delete') {
      await _showDeleteDialog(context, equipmentDoc.id, name);
    }
  }

  Future<void> _showMaintenanceDialog(
    BuildContext context,
    String equipmentId,
    String name,
  ) async {
    final notesController = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Mark for Maintenance',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mark "$name" as under maintenance?',
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: 'Maintenance Notes',
                hintText: 'Enter reason or notes...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE8ECEF)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2B6C67)),
                ),
              ),
              maxLines: 3,
            ),
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
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('equipment')
                    .doc(equipmentId)
                    .update({
                  'status': 'maintenance',
                  'availability': false,
                  'updatedAt': FieldValue.serverTimestamp(),
                });

                await FirebaseFirestore.instance
                    .collection('maintenance_logs')
                    .add({
                  'equipmentId': equipmentId,
                  'action': 'started',
                  'notes': notesController.text,
                  'timestamp': FieldValue.serverTimestamp(),
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Equipment marked for maintenance'),
                      backgroundColor: Color(0xFF8B5CF6),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: const Color(0xFFEF4444),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    String equipmentId,
    String name,
  ) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Delete Equipment',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        content: Text(
          'Are you sure you want to delete "$name"? This action cannot be undone.',
          style: const TextStyle(color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
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
                    const SnackBar(
                      content: Text('Equipment deleted successfully'),
                      backgroundColor: Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: const Color(0xFFEF4444),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

enum ViewType { list, grid }