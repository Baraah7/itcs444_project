import 'package:cloud_firestore/cloud_firestore.dart';

class Equipment {
  final String id;
  final String name;
  final String category;
  final String type;
  final String description;
  final double rentalPrice;
  final bool availability;
  final String condition;
  final int quantity;
  final String? location;
  final List<String>? tags;
  final String? imageUrl;
  final String status; // available, rented, maintenance
  final DateTime createdAt;
  final DateTime updatedAt;
  final int maxRentalDays;
  final double? lateFeePerDay;
  final int availableQuantity; // NEW: Track available items

  Equipment({
    required this.id,
    required this.name,
    required this.category,
    required this.type,
    required this.description,
    required this.rentalPrice,
    required this.availability,
    required this.condition,
    required this.quantity,
    this.location,
    this.tags,
    this.imageUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.maxRentalDays = 30,
    this.lateFeePerDay,
    required this.availableQuantity, // NEW
  });

  factory Equipment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Equipment(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? 'General',
      type: data['type'] ?? 'General',
      description: data['description'] ?? '',
      rentalPrice: (data['rentalPrice'] ?? 0).toDouble(),
      availability: data['availability'] ?? false,
      condition: data['condition'] ?? 'Good',
      quantity: data['quantity'] ?? 1,
      location: data['location'],
      tags: data['tags'] != null ? List<String>.from(data['tags']) : null,
      imageUrl: data['imageUrl'],
      status: data['status'] ?? 'available',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      maxRentalDays: data['maxRentalDays'] ?? 30,
      lateFeePerDay: (data['lateFeePerDay'] ?? 0).toDouble(),
      availableQuantity: data['availableQuantity'] ?? (data['quantity'] ?? 1), // NEW
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'type': type,
      'description': description,
      'rentalPrice': rentalPrice,
      'availability': availability,
      'condition': condition,
      'quantity': quantity,
      'location': location,
      'tags': tags,
      'imageUrl': imageUrl,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'maxRentalDays': maxRentalDays,
      'lateFeePerDay': lateFeePerDay,
      'availableQuantity': availableQuantity, // NEW
    };
  }

  // Get equipment icon based on type
  String get icon {
    switch (type.toLowerCase()) {
      case 'wheelchair':
        return '🦽';
      case 'walker':
        return '🚶';
      case 'crutches':
        return '🩼';
      case 'hospital bed':
        return '🛏️';
      case 'oxygen machine':
        return '💨';
      case 'shower chair':
        return '🚿';
      default:
        return '🏥';
    }
  }

  // Get recommended rental duration based on equipment type
  int get recommendedRentalDays {
    switch (type.toLowerCase()) {
      case 'wheelchair':
        return 30; // Long-term mobility aid
      case 'walker':
        return 21;
      case 'crutches':
        return 14; // Temporary use
      case 'hospital bed':
        return 60; // Long-term care
      case 'oxygen machine':
        return 30;
      case 'shower chair':
        return 21;
      default:
        return 14;
    }
  }

  // Check if equipment can be rented
  bool get canBeRented {
    return availability && status == 'available' && availableQuantity > 0;
  }

  // Check availability for specific dates
  Future<bool> checkAvailabilityForDates({
    required FirebaseFirestore firestore,
    required DateTime startDate,
    required DateTime endDate,
    required int requestedQuantity,
  }) async {
    try {
      // Get overlapping reservations
      final rentalsSnapshot = await firestore
          .collection('rentals')
          .where('equipmentId', isEqualTo: id)
          .where('status', whereIn: ['pending', 'approved', 'checked_out'])
          .get();
      
      num reservedCount = 0;
      for (final rentalDoc in rentalsSnapshot.docs) {
        final rentalData = rentalDoc.data() as Map<String, dynamic>;
        final rentalStart = DateTime.parse(rentalData['startDate']);
        final rentalEnd = DateTime.parse(rentalData['endDate']);
        
        // Check for date overlap
        if (startDate.isBefore(rentalEnd) && endDate.isAfter(rentalStart)) {
          reservedCount += rentalData['quantity'] ?? 1;
        }
      }
      
      // Calculate available after subtracting reserved
      final actuallyAvailable = availableQuantity - reservedCount;
      return actuallyAvailable >= requestedQuantity;
    } catch (e) {
      print('Error checking availability: $e');
      return false;
    }
  }

  // Copy with method for updates - FIXED VERSION
  Equipment copyWith({
    String? id,
    String? name,
    String? category,
    String? type,
    String? description,
    double? rentalPrice,
    bool? availability,
    String? condition,
    int? quantity,
    String? location,
    List<String>? tags,
    String? imageUrl,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? maxRentalDays,
    double? lateFeePerDay,
    int? availableQuantity,
  }) {
    return Equipment(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      type: type ?? this.type,
      description: description ?? this.description,
      rentalPrice: rentalPrice ?? this.rentalPrice,
      availability: availability ?? this.availability,
      condition: condition ?? this.condition,
      quantity: quantity ?? this.quantity,
      location: location ?? this.location,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt, // FIXED: Don't force DateTime.now()
      maxRentalDays: maxRentalDays ?? this.maxRentalDays,
      lateFeePerDay: lateFeePerDay ?? this.lateFeePerDay,
      availableQuantity: availableQuantity ?? this.availableQuantity,
    );
  }

  // Alternative: Create an update method that sets updatedAt
  Equipment updateWith({
    String? name,
    String? category,
    String? type,
    String? description,
    double? rentalPrice,
    bool? availability,
    String? condition,
    int? quantity,
    String? location,
    List<String>? tags,
    String? imageUrl,
    String? status,
    int? maxRentalDays,
    double? lateFeePerDay,
    int? availableQuantity,
  }) {
    return Equipment(
      id: this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      type: type ?? this.type,
      description: description ?? this.description,
      rentalPrice: rentalPrice ?? this.rentalPrice,
      availability: availability ?? this.availability,
      condition: condition ?? this.condition,
      quantity: quantity ?? this.quantity,
      location: location ?? this.location,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      createdAt: this.createdAt,
      updatedAt: DateTime.now(), // This will set current time
      maxRentalDays: maxRentalDays ?? this.maxRentalDays,
      lateFeePerDay: lateFeePerDay ?? this.lateFeePerDay,
      availableQuantity: availableQuantity ?? this.availableQuantity,
    );
  }
}