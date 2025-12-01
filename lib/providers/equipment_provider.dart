//Equipment list + search/filter state
import 'package:flutter/foundation.dart';
import '../models/equipment_model.dart';

class EquipmentProvider extends ChangeNotifier {
  List<Equipment> _equipmentList = [];

  EquipmentProvider() {
    _initializeDummyData();
  }

  void _initializeDummyData() {
    _equipmentList = [
      Equipment(
        id: 'eq_001',
        name: 'Standard Wheelchair',
        type: EquipmentType.wheelchair,
        description: 'Lightweight, foldable wheelchair with comfortable seating. Perfect for daily use and travel.',
        images: ['assets/wheelchair.jpg'],
        condition: 'Excellent',
        quantity: 5,
        location: 'Main Storage Room A',
        tags: ['portable', 'foldable', 'lightweight'],
        status: EquipmentStatus.available,
        rentalPricePerDay: 10.0,
        isDonated: false,
        lastMaintenanceDate: DateTime.now().add(const Duration(days: -30)),
        nextMaintenanceDate: DateTime.now().add(const Duration(days: 60)),
        createdAt: DateTime.now().add(const Duration(days: -180)),
      ),
      Equipment(
        id: 'eq_002',
        name: 'Walker with Wheels',
        type: EquipmentType.walker,
        description: 'Four-wheel walker with seat, basket, and hand brakes. Provides stability and mobility.',
        images: ['assets/walker.jpg'],
        condition: 'Good',
        quantity: 3,
        location: 'Main Storage Room B',
        tags: ['stability', 'wheels', 'seat'],
        status: EquipmentStatus.available,
        rentalPricePerDay: 5.0,
        isDonated: true,
        lastMaintenanceDate: DateTime.now().add(const Duration(days: -15)),
        nextMaintenanceDate: DateTime.now().add(const Duration(days: 75)),
        createdAt: DateTime.now().add(const Duration(days: -120)),
      ),
      Equipment(
        id: 'eq_003',
        name: 'Hospital Bed',
        type: EquipmentType.hospitalBed,
        description: 'Adjustable electric hospital bed with side rails and height adjustment.',
        images: ['assets/bed.jpg'],
        condition: 'Very Good',
        quantity: 2,
        location: 'Medical Equipment Room',
        tags: ['adjustable', 'electric', 'bed'],
        status: EquipmentStatus.available,
        rentalPricePerDay: 20.0,
        isDonated: false,
        lastMaintenanceDate: DateTime.now().add(const Duration(days: -45)),
        nextMaintenanceDate: DateTime.now().add(const Duration(days: 45)),
        createdAt: DateTime.now().add(const Duration(days: -90)),
      ),
      Equipment(
        id: 'eq_004',
        name: 'Oxygen Concentrator',
        type: EquipmentType.oxygenMachine,
        description: 'Portable oxygen concentrator with adjustable flow rates. Includes nasal cannula.',
        images: ['assets/oxygen.jpg'],
        condition: 'Excellent',
        quantity: 4,
        location: 'Medical Equipment Room',
        tags: ['medical', 'oxygen', 'portable'],
        status: EquipmentStatus.available,
        rentalPricePerDay: 30.0,
        isDonated: true,
        lastMaintenanceDate: DateTime.now().add(const Duration(days: -60)),
        nextMaintenanceDate: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now().add(const Duration(days: -150)),
      ),
      Equipment(
        id: 'eq_005',
        name: 'Shower Chair',
        type: EquipmentType.showerChair,
        description: 'Waterproof shower chair with back support and non-slip feet.',
        images: ['assets/shower_chair.jpg'],
        condition: 'Good',
        quantity: 6,
        location: 'Bathroom Aids Section',
        tags: ['bathroom', 'waterproof', 'safe'],
        status: EquipmentStatus.available,
        rentalPricePerDay: 3.0,
        isDonated: true,
        lastMaintenanceDate: DateTime.now().add(const Duration(days: -20)),
        nextMaintenanceDate: DateTime.now().add(const Duration(days: 70)),
        createdAt: DateTime.now().add(const Duration(days: -100)),
      ),
      Equipment(
        id: 'eq_006',
        name: 'Under Maintenance Wheelchair',
        type: EquipmentType.wheelchair,
        description: 'Wheelchair currently undergoing maintenance.',
        images: ['assets/wheelchair2.jpg'],
        condition: 'Under Repair',
        quantity: 1,
        location: 'Maintenance Room',
        tags: ['repair', 'maintenance'],
        status: EquipmentStatus.underMaintenance,
        rentalPricePerDay: 10.0,
        isDonated: false,
        lastMaintenanceDate: DateTime.now().add(const Duration(days: -5)),
        nextMaintenanceDate: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now().add(const Duration(days: -200)),
      ),
      Equipment(
        id: 'eq_007',
        name: 'Crutches (Pair)',
        type: EquipmentType.crutches,
        description: 'Adjustable underarm crutches with comfortable grips.',
        images: ['assets/crutches.jpg'],
        condition: 'Very Good',
        quantity: 8,
        location: 'Mobility Aids Section',
        tags: ['adjustable', 'pair', 'lightweight'],
        status: EquipmentStatus.available,
        rentalPricePerDay: 2.0,
        isDonated: true,
        lastMaintenanceDate: DateTime.now().add(const Duration(days: -10)),
        nextMaintenanceDate: DateTime.now().add(const Duration(days: 80)),
        createdAt: DateTime.now().add(const Duration(days: -80)),
      ),
      Equipment(
        id: 'eq_008',
        name: 'Commode Chair',
        type: EquipmentType.commode,
        description: 'Bedside commode chair with removable bucket and lid.',
        images: ['assets/commode.jpg'],
        condition: 'Good',
        quantity: 3,
        location: 'Bathroom Aids Section',
        tags: ['bedside', 'portable', 'hygienic'],
        status: EquipmentStatus.available,
        rentalPricePerDay: 4.0,
        isDonated: false,
        lastMaintenanceDate: DateTime.now().add(const Duration(days: -25)),
        nextMaintenanceDate: DateTime.now().add(const Duration(days: 65)),
        createdAt: DateTime.now().add(const Duration(days: -140)),
      ),
    ];
  }

  // Getters
  List<Equipment> get equipmentList => _equipmentList;
  
  List<Equipment> get availableEquipment =>
      _equipmentList.where((e) => e.isAvailable).toList();
  
  List<Equipment> get rentableEquipment =>
      _equipmentList.where((e) => e.isAvailable && e.isRentable).toList();
  
  List<Equipment> get donatedEquipment =>
      _equipmentList.where((e) => e.isDonated).toList();

  // Filter equipment
  List<Equipment> filterEquipment({
    String? searchQuery,
    EquipmentType? type,
    EquipmentStatus? status,
    bool? availableOnly,
    bool? rentableOnly,
    bool? donatedOnly,
    double? maxPrice,
  }) {
    var filtered = _equipmentList;

    if (searchQuery != null && searchQuery.isNotEmpty) {
      filtered = filtered.where((e) =>
          e.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          e.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
          e.tags.any((tag) => tag.toLowerCase().contains(searchQuery.toLowerCase())))
          .toList();
    }

    if (type != null) {
      filtered = filtered.where((e) => e.type == type).toList();
    }

    if (status != null) {
      filtered = filtered.where((e) => e.status == status).toList();
    }

    if (availableOnly == true) {
      filtered = filtered.where((e) => e.isAvailable).toList();
    }

    if (rentableOnly == true) {
      filtered = filtered.where((e) => e.isRentable).toList();
    }

    if (donatedOnly == true) {
      filtered = filtered.where((e) => e.isDonated).toList();
    }

    if (maxPrice != null) {
      filtered = filtered.where((e) =>
          e.rentalPricePerDay != null && e.rentalPricePerDay! <= maxPrice).toList();
    }

    return filtered;
  }

  // Get equipment by ID
  Equipment? getEquipmentById(String id) {
    try {
      return _equipmentList.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get equipment by type
  List<Equipment> getEquipmentByType(EquipmentType type) {
    return _equipmentList.where((e) => e.type == type).toList();
  }

  // Check availability
  bool checkAvailability(String equipmentId, int requiredQuantity) {
    final equipment = getEquipmentById(equipmentId);
    return equipment != null && 
           equipment.isAvailable && 
           equipment.quantity >= requiredQuantity;
  }

  // Update equipment quantity (when reserved/returned)
  void updateEquipmentQuantity(String equipmentId, int newQuantity) {
    final index = _equipmentList.indexWhere((e) => e.id == equipmentId);
    
    if (index != -1) {
      final equipment = _equipmentList[index];
      final updatedEquipment = equipment.copyWith(
        quantity: newQuantity,
        status: newQuantity > 0 ? EquipmentStatus.available : EquipmentStatus.rented,
      );
      
      _equipmentList[index] = updatedEquipment;
      notifyListeners();
    }
  }

  // Mark equipment as under maintenance
  void markAsUnderMaintenance(String equipmentId) {
    final index = _equipmentList.indexWhere((e) => e.id == equipmentId);
    
    if (index != -1) {
      final equipment = _equipmentList[index];
      final updatedEquipment = equipment.copyWith(
        status: EquipmentStatus.underMaintenance,
        lastMaintenanceDate: DateTime.now(),
        nextMaintenanceDate: DateTime.now().add(const Duration(days: 90)),
      );
      
      _equipmentList[index] = updatedEquipment;
      notifyListeners();
    }
  }

  // Mark equipment as available
  void markAsAvailable(String equipmentId) {
    final index = _equipmentList.indexWhere((e) => e.id == equipmentId);
    
    if (index != -1) {
      final equipment = _equipmentList[index];
      final updatedEquipment = equipment.copyWith(
        status: EquipmentStatus.available,
      );
      
      _equipmentList[index] = updatedEquipment;
      notifyListeners();
    }
  }

  // Get equipment needing maintenance soon (within 30 days)
  List<Equipment> getEquipmentNeedingMaintenance() {
    final now = DateTime.now();
    final thirtyDaysFromNow = now.add(const Duration(days: 30));
    
    return _equipmentList.where((e) =>
        e.nextMaintenanceDate != null &&
        e.nextMaintenanceDate!.isBefore(thirtyDaysFromNow) &&
        e.nextMaintenanceDate!.isAfter(now))
        .toList();
  }

  // Get most rented equipment types (for reports)
  Map<String, int> getMostRentedTypes() {
    final counts = <String, int>{};
    
    for (final equipment in _equipmentList) {
      final typeName = equipment.type.name;
      counts[typeName] = (counts[typeName] ?? 0) + equipment.quantity;
    }
    
    return counts;
  }

  // Get equipment statistics
  Map<String, dynamic> getEquipmentStats() {
    final total = _equipmentList.length;
    final available = availableEquipment.length;
    final rentable = rentableEquipment.length;
    final donated = donatedEquipment.length;
    final underMaintenance = _equipmentList
        .where((e) => e.status == EquipmentStatus.underMaintenance)
        .length;
    final rented = _equipmentList
        .where((e) => e.status == EquipmentStatus.rented)
        .length;

    return {
      'total': total,
      'available': available,
      'rentable': rentable,
      'donated': donated,
      'underMaintenance': underMaintenance,
      'rented': rented,
    };
  }
}