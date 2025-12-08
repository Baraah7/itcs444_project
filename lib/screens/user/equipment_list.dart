import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:itcs444_project/screens/user/equipment_detail.dart';
import '../../utils/theme.dart';

class EquipmentListScreen extends StatefulWidget {
  final String? category;
  final String? searchQuery;

  const EquipmentListScreen({
    super.key,
    this.category,
    this.searchQuery,
  });

  @override
  State<EquipmentListScreen> createState() => _EquipmentListScreenState();
}

class _EquipmentListScreenState extends State<EquipmentListScreen> {
  String _selectedCategory = 'All';
  String _selectedCondition = 'All';
  String _sortBy = 'name';
  bool _showAvailableOnly = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _categories = [
    'All',
    'Mobility Aids',
    'Home Care',
    'Monitoring',
    'Medical Supplies',
    'Respiratory',
    'Other',
  ];

  final List<String> _conditions = [
    'All',
    'Excellent',
    'Good',
    'Fair',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _selectedCategory = widget.category!;
    }
    if (widget.searchQuery != null) {
      _searchQuery = widget.searchQuery!;
      _searchController.text = _searchQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Equipment'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterBottomSheet(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(
            child: _buildEquipmentGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search equipment...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.backgroundLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 60,
      color: Colors.white,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildFilterChip(
            label: _showAvailableOnly ? 'Available Only' : 'All Items',
            icon: _showAvailableOnly ? Icons.check_circle : Icons.filter_alt,
            isSelected: _showAvailableOnly,
            onTap: () {
              setState(() {
                _showAvailableOnly = !_showAvailableOnly;
              });
            },
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: _selectedCategory,
            icon: Icons.category,
            onTap: () => _showCategoryDialog(),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Sort: ${_getSortLabel()}',
            icon: Icons.sort,
            onTap: () => _showSortDialog(),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: _selectedCondition,
            icon: Icons.star,
            onTap: () => _showConditionDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primaryBlue 
              : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? AppColors.primaryBlue 
                : AppColors.neutralGray.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppColors.primaryDark,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEquipmentGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: _buildQuery().snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading equipment',
                  style: TextStyle(color: AppColors.error),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 80,
                  color: AppColors.neutralGray.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No equipment found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutralGray,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try adjusting your filters',
                  style: TextStyle(color: AppColors.neutralGray),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _resetFilters(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset Filters'),
                ),
              ],
            ),
          );
        }

        // Apply client-side filtering for search and sorting
        List<DocumentSnapshot> docs = snapshot.data!.docs;
        
        // Filter by search query
        if (_searchQuery.isNotEmpty) {
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['name'] ?? '').toString().toLowerCase();
            final description = (data['description'] ?? '').toString().toLowerCase();
            final category = (data['category'] ?? '').toString().toLowerCase();
            
            return name.contains(_searchQuery) || 
                   description.contains(_searchQuery) ||
                   category.contains(_searchQuery);
          }).toList();
        }

        // Sort
        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          
          switch (_sortBy) {
            case 'price_low':
              return (aData['rentalPrice'] ?? 0).compareTo(bData['rentalPrice'] ?? 0);
            case 'price_high':
              return (bData['rentalPrice'] ?? 0).compareTo(aData['rentalPrice'] ?? 0);
            case 'newest':
              final aDate = aData['createdAt'] as Timestamp?;
              final bDate = bData['createdAt'] as Timestamp?;
              if (aDate == null || bDate == null) return 0;
              return bDate.compareTo(aDate);
            default: // name
              return (aData['name'] ?? '').toString().compareTo((bData['name'] ?? '').toString());
          }
        });

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.68,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              
              return _buildEquipmentCard(
                id: doc.id,
                name: data['name'] ?? 'Unknown',
                category: data['category'] ?? 'General',
                price: (data['rentalPrice'] ?? 0).toDouble(),
                condition: data['condition'] ?? 'Good',
                imageUrl: data['imageUrl'],
                isAvailable: data['availability'] ?? false,
                availableQuantity: data['availableQuantity'] ?? 0,
              );
            },
          ),
        );
      },
    );
  }

  Query _buildQuery() {
    Query query = FirebaseFirestore.instance.collection('equipment');

    // Filter by availability
    if (_showAvailableOnly) {
      query = query.where('availability', isEqualTo: true);
    }

    // Filter by category
    if (_selectedCategory != 'All') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }

    // Filter by condition
    if (_selectedCondition != 'All') {
      query = query.where('condition', isEqualTo: _selectedCondition);
    }

    return query;
  }

  Widget _buildEquipmentCard({
    required String id,
    required String name,
    required String category,
    required double price,
    required String condition,
    String? imageUrl,
    required bool isAvailable,
    required int availableQuantity,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EquipmentDetailPage(equipmentId: id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 140,
                              color: AppColors.backgroundLight,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) => _placeholderImage(),
                        )
                      : _placeholderImage(),
                ),
                
                // Availability Badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAvailable ? AppColors.success : AppColors.error,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      isAvailable ? 'Available' : 'Unavailable',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                
                // Condition Badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getConditionColor(condition).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          size: 10,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          condition,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Details Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Category
                    Row(
                      children: [
                        Icon(
                          Icons.category_outlined,
                          size: 12,
                          color: AppColors.neutralGray,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.neutralGray,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Quantity
                    if (availableQuantity > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$availableQuantity available',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.info,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                    const SizedBox(height: 8),

                    // Price and Action
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BD ${price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                              Text(
                                'per day',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: AppColors.neutralGray,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryBlue.withOpacity(0.3),
            AppColors.accentMauve.withOpacity(0.3),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.medical_services,
          size: 48,
          color: Colors.white.withOpacity(0.7),
        ),
      ),
    );
  }

  Color _getConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'excellent':
        return AppColors.success;
      case 'good':
        return AppColors.info;
      case 'fair':
        return AppColors.warning;
      default:
        return AppColors.neutralGray;
    }
  }

  String _getSortLabel() {
    switch (_sortBy) {
      case 'price_low':
        return 'Price (Low)';
      case 'price_high':
        return 'Price (High)';
      case 'newest':
        return 'Newest';
      default:
        return 'Name';
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _resetFilters();
                    Navigator.pop(context);
                  },
                  child: const Text('Reset All'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Show Available Only'),
              value: _showAvailableOnly,
              activeColor: AppColors.primaryBlue,
              onChanged: (value) {
                setState(() {
                  _showAvailableOnly = value;
                });
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Apply Filters'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Category'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              return RadioListTile<String>(
                title: Text(category),
                value: category,
                groupValue: _selectedCategory,
                activeColor: AppColors.primaryBlue,
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort By'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Name (A-Z)'),
              value: 'name',
              groupValue: _sortBy,
              activeColor: AppColors.primaryBlue,
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Price (Low to High)'),
              value: 'price_low',
              groupValue: _sortBy,
              activeColor: AppColors.primaryBlue,
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Price (High to Low)'),
              value: 'price_high',
              groupValue: _sortBy,
              activeColor: AppColors.primaryBlue,
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Newest First'),
              value: 'newest',
              groupValue: _sortBy,
              activeColor: AppColors.primaryBlue,
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showConditionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Condition'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _conditions.length,
            itemBuilder: (context, index) {
              final condition = _conditions[index];
              return RadioListTile<String>(
                title: Text(condition),
                value: condition,
                groupValue: _selectedCondition,
                activeColor: AppColors.primaryBlue,
                onChanged: (value) {
                  setState(() {
                    _selectedCondition = value!;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = 'All';
      _selectedCondition = 'All';
      _sortBy = 'name';
      _showAvailableOnly = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }
}