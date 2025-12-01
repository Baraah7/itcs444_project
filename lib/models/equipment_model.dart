//Equipment details + availability status
enum EquipmentStatus {
  available,
  rented,
  donated,
  underMaintenance,
  reserved
}

enum EquipmentType {
  wheelchair,
  walker,
  crutches,
  hospitalBed,
  oxygenMachine,
  showerChair,
  commode,
  other
}

extension EquipmentTypeExtension on EquipmentType {
  String get name {
    switch (this) {
      case EquipmentType.wheelchair:
        return 'Wheelchair';
      case EquipmentType.walker:
        return 'Walker';
      case EquipmentType.crutches:
        return 'Crutches';
      case EquipmentType.hospitalBed:
        return 'Hospital Bed';
      case EquipmentType.oxygenMachine:
        return 'Oxygen Machine';
      case EquipmentType.showerChair:
        return 'Shower Chair';
      case EquipmentType.commode:
        return 'Commode';
      case EquipmentType.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case EquipmentType.wheelchair:
        return '♿';
      case EquipmentType.walker:
        return '🚶‍♂️';
      case EquipmentType.crutches:
        return '🩼';
      case EquipmentType.hospitalBed:
        return '🛏️';
      case EquipmentType.oxygenMachine:
        return '💨';
      case EquipmentType.showerChair:
        return '🪑';
      case EquipmentType.commode:
        return '🚽';
      case EquipmentType.other:
        return '📦';
    }
  }
}

class Equipment {
  final String id;
  final String name;
  final EquipmentType type;
  final String description;
  final List<String> images;
  final String condition;
  final int quantity;
  final String location;
  final List<String> tags;
  final EquipmentStatus status;
  final double? rentalPricePerDay;
  final bool isDonated;
  final DateTime? lastMaintenanceDate;
  final DateTime? nextMaintenanceDate;
  final DateTime createdAt;

  Equipment({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.images,
    required this.condition,
    required this.quantity,
    required this.location,
    required this.tags,
    required this.status,
    this.rentalPricePerDay,
    this.isDonated = false,
    this.lastMaintenanceDate,
    this.nextMaintenanceDate,
    required this.createdAt,
  });

  bool get isAvailable => status == EquipmentStatus.available && quantity > 0;
  bool get isRentable => rentalPricePerDay != null && rentalPricePerDay! > 0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.index,
      'description': description,
      'images': images,
      'condition': condition,
      'quantity': quantity,
      'location': location,
      'tags': tags,
      'status': status.index,
      'rentalPricePerDay': rentalPricePerDay,
      'isDonated': isDonated,
      'lastMaintenanceDate': lastMaintenanceDate?.toIso8601String(),
      'nextMaintenanceDate': nextMaintenanceDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: EquipmentType.values[json['type'] ?? 0],
      description: json['description'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      condition: json['condition'] ?? 'Good',
      quantity: json['quantity'] ?? 1,
      location: json['location'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      status: EquipmentStatus.values[json['status'] ?? 0],
      rentalPricePerDay: json['rentalPricePerDay']?.toDouble(),
      isDonated: json['isDonated'] ?? false,
      lastMaintenanceDate: json['lastMaintenanceDate'] != null 
          ? DateTime.parse(json['lastMaintenanceDate']) 
          : null,
      nextMaintenanceDate: json['nextMaintenanceDate'] != null 
          ? DateTime.parse(json['nextMaintenanceDate']) 
          : null,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Equipment copyWith({
    String? id,
    String? name,
    EquipmentType? type,
    String? description,
    List<String>? images,
    String? condition,
    int? quantity,
    String? location,
    List<String>? tags,
    EquipmentStatus? status,
    double? rentalPricePerDay,
    bool? isDonated,
    DateTime? lastMaintenanceDate,
    DateTime? nextMaintenanceDate,
    DateTime? createdAt,
  }) {
    return Equipment(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      images: images ?? this.images,
      condition: condition ?? this.condition,
      quantity: quantity ?? this.quantity,
      location: location ?? this.location,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      rentalPricePerDay: rentalPricePerDay ?? this.rentalPricePerDay,
      isDonated: isDonated ?? this.isDonated,
      lastMaintenanceDate: lastMaintenanceDate ?? this.lastMaintenanceDate,
      nextMaintenanceDate: nextMaintenanceDate ?? this.nextMaintenanceDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}