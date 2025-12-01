//Equipment list + search/filter state
import 'package:flutter/foundation.dart';
import '../models/equipment_model.dart';

class EquipmentProvider with ChangeNotifier {
  List<Equipment> _equipmentList = [];
  List<Equipment> _filteredEquipmentList = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  List<Equipment> get equipmentList => _filteredEquipmentList;
  List<Equipment> get allEquipment => _equipmentList;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  // Initialize with sample data
  EquipmentProvider() {
    _initializeSampleData();
  }

  void _initializeSampleData() {
    _equipmentList = [
      Equipment(
        id: '1',
        name: 'Excavator CAT 320',
        description: 'Heavy-duty excavator for construction sites',
        imageUrl: 'https://example.com/excavator.jpg',
        isAvailable: true,
        category: 'Heavy Equipment',
        price: 2500.0,
        location: 'Construction Site A',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      Equipment(
        id: '2',
        name: 'Bulldozer Komatsu',
        description: 'Powerful bulldozer for earth moving',
        imageUrl: 'https://example.com/bulldozer.jpg',
        isAvailable: true,
        category: 'Heavy Equipment',
        price: 3000.0,
        location: 'Construction Site B',
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
      ),
      Equipment(
        id: '3',
        name: 'Concrete Mixer',
        description: 'Portable concrete mixing equipment',
        imageUrl: 'https://example.com/concrete-mixer.jpg',
        isAvailable: false,
        category: 'Concrete Equipment',
        price: 500.0,
        location: 'Warehouse C',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
      Equipment(
        id: '4',
        name: 'Scissor Lift',
        description: 'Electric scissor lift for maintenance work',
        imageUrl: 'https://example.com/scissor-lift.jpg',
        isAvailable: true,
        category: 'Access Equipment',
        price: 800.0,
        location: 'Warehouse A',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
    ];
    
    _filteredEquipmentList = _equipmentList;
    notifyListeners();
  }

  // Get equipment by ID
  Equipment? getEquipmentById(String id) {
    try {
      return _equipmentList.firstWhere((equipment) => equipment.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get available equipment
  List<Equipment> get availableEquipment {
    return _equipmentList.where((equipment) => equipment.isAvailable).toList();
  }

  // Add new equipment
  Future<void> addEquipment(Equipment equipment) async {
    _setLoading(true);
    _error = null;

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      _equipmentList.insert(0, equipment);
      _applyFilters();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Update equipment
  Future<void> updateEquipment(Equipment updatedEquipment) async {
    _setLoading(true);
    _error = null;

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      final index = _equipmentList.indexWhere((e) => e.id == updatedEquipment.id);
      if (index != -1) {
        _equipmentList[index] = updatedEquipment;
        _applyFilters();
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Delete equipment
  Future<void> deleteEquipment(String equipmentId) async {
    _setLoading(true);
    _error = null;

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      _equipmentList.removeWhere((equipment) => equipment.id == equipmentId);
      _applyFilters();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Search equipment
  void searchEquipment(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  // Filter by category
  void filterByCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
  }

  // Apply all filters
  void _applyFilters() {
    List<Equipment> filtered = _equipmentList;

    // Apply category filter
    if (_selectedCategory != 'All') {
      filtered = filtered.where((equipment) => equipment.category == _selectedCategory).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((equipment) =>
        equipment.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        equipment.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        equipment.location.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    _filteredEquipmentList = filtered;
    notifyListeners();
  }

  // Get all categories
  List<String> get categories {
    final categories = _equipmentList.map((e) => e.category).toSet().toList();
    categories.insert(0, 'All');
    return categories;
  }

  // Clear filters
  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = 'All';
    _filteredEquipmentList = _equipmentList;
    notifyListeners();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}