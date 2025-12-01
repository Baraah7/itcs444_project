//Search/filter available equipment
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/equipment_model.dart';
import '../../providers/equipment_provider.dart';
import 'equipment_detail.dart';

class EquipmentListScreen extends StatefulWidget {
  const EquipmentListScreen({super.key});

  @override
  State<EquipmentListScreen> createState() => _EquipmentListScreenState();
}

class _EquipmentListScreenState extends State<EquipmentListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    Provider.of<EquipmentProvider>(context, listen: false)
        .searchEquipment(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(
            child: _buildEquipmentList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search equipment...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final equipmentProvider = Provider.of<EquipmentProvider>(context);
    
    return SizedBox(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        children: equipmentProvider.categories.map((category) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(category),
              selected: equipmentProvider.selectedCategory == category,
              onSelected: (selected) {
                equipmentProvider.filterByCategory(category);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEquipmentList() {
    return Consumer<EquipmentProvider>(
      builder: (context, equipmentProvider, child) {
        if (equipmentProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (equipmentProvider.equipmentList.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No equipment found',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: equipmentProvider.equipmentList.length,
          itemBuilder: (context, index) {
            final equipment = equipmentProvider.equipmentList[index];
            return _buildEquipmentCard(equipment);
          },
        );
      },
    );
  }

  Widget _buildEquipmentCard(Equipment equipment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EquipmentDetailScreen(equipment: equipment),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Equipment Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8.0),
                  image: equipment.imageUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(equipment.imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: equipment.imageUrl.isEmpty
                    ? const Icon(Icons.construction, size: 40, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 16),
              // Equipment Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      equipment.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      equipment.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          equipment.location,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${equipment.price?.toStringAsFixed(2)}/day',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: equipment.isAvailable
                                ? Colors.green[50]
                                : Colors.red[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: equipment.isAvailable
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          child: Text(
                            equipment.isAvailable ? 'Available' : 'Not Available',
                            style: TextStyle(
                              color: equipment.isAvailable
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}