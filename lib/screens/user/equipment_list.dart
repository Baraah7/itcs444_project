//Search/filter available equipment
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/equipment_model.dart';
import '../../providers/equipment_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/equipment_card.dart';
import 'reservation_screen.dart';

class EquipmentListScreen extends StatefulWidget {
  const EquipmentListScreen({Key? key}) : super(key: key);

  @override
  State<EquipmentListScreen> createState() => _EquipmentListScreenState();
}

class _EquipmentListScreenState extends State<EquipmentListScreen> {
  String _searchQuery = '';
  EquipmentType? _selectedType;
  bool _showAvailableOnly = true;
  bool _showRentableOnly = false;
  bool _showDonatedOnly = false;

  @override
  Widget build(BuildContext context) {
    final equipmentProvider = Provider.of<EquipmentProvider>(context);
    final filteredEquipment = equipmentProvider.filterEquipment(
      searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      type: _selectedType,
      availableOnly: _showAvailableOnly,
      rentableOnly: _showRentableOnly,
      donatedOnly: _showDonatedOnly,
    );

    final stats = equipmentProvider.getEquipmentStats();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Equipment'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: () {
              Navigator.pushNamed(context, '/my-reservations');
            },
            tooltip: 'My Reservations',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search equipment...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Quick Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                _buildQuickStat('Total', stats['total']),
                _buildQuickStat('Available', stats['available']),
                _buildQuickStat('Rentable', stats['rentable']),
                _buildQuickStat('Donated', stats['donated']),
              ],
            ),
          ),

          // Filter Chips
          SizedBox(
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                FilterChip(
                  label: const Text('All Types'),
                  selected: _selectedType == null,
                  onSelected: (selected) {
                    setState(() {
                      _selectedType = null;
                    });
                  },
                ),
                ...EquipmentType.values.map((type) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: FilterChip(
                      label: Text(type.name),
                      selected: _selectedType == type,
                      onSelected: (selected) {
                        setState(() {
                          _selectedType = selected ? type : null;
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          // Toggle Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('Available Only'),
                  selected: _showAvailableOnly,
                  onSelected: (selected) {
                    setState(() {
                      _showAvailableOnly = selected;
                    });
                  },
                ),
                FilterChip(
                  label: const Text('Rentable Only'),
                  selected: _showRentableOnly,
                  onSelected: (selected) {
                    setState(() {
                      _showRentableOnly = selected;
                    });
                  },
                ),
                FilterChip(
                  label: const Text('Donated Only'),
                  selected: _showDonatedOnly,
                  onSelected: (selected) {
                    setState(() {
                      _showDonatedOnly = selected;
                    });
                  },
                ),
              ],
            ),
          ),

          // Equipment List
          Expanded(
            child: filteredEquipment.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: AppColors.neutralGray.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No equipment found',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try changing your filters or search query',
                          style: TextStyle(
                            color: AppColors.neutralGray,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredEquipment.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final equipment = filteredEquipment[index];
                      return EquipmentCard(
                        equipment: equipment,
                        onTap: () {
                          // Navigate to equipment detail
                          _showEquipmentDetail(context, equipment);
                        },
                        onReserve: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ReservationScreen(equipment: equipment),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, dynamic value) {
    return Expanded(
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.neutralGray,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEquipmentDetail(BuildContext context, Equipment equipment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      equipment.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            equipment.type.name,
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accentMauve.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            equipment.condition,
                            style: TextStyle(
                              color: AppColors.accentMauve,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      equipment.description,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailItem('Location', equipment.location),
                    _buildDetailItem('Quantity', equipment.quantity.toString()),
                    _buildDetailItem('Tags', equipment.tags.join(', ')),
                    if (equipment.isDonated)
                      _buildDetailItem('Donation', 'This item was donated'),
                    if (equipment.rentalPricePerDay != null)
                      _buildDetailItem('Daily Rate',
                          '\$${equipment.rentalPricePerDay!.toStringAsFixed(2)}'),
                    const SizedBox(height: 32),
                    if (equipment.isAvailable && equipment.isRentable)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ReservationScreen(equipment: equipment),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Reserve This Equipment'),
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

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}