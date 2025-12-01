//Equipment details + availability status
class Equipment {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final bool isAvailable;
  final String category;
  final double? price;
  final String location;
  final DateTime? createdAt;

  Equipment({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.isAvailable,
    required this.category,
    this.price,
    required this.location,
    this.createdAt,
  });

  // Convert Equipment object to Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'category': category,
      'price': price,
      'location': location,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  // Create Equipment object from Map
  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      isAvailable: json['isAvailable'] ?? false,
      category: json['category'] ?? '',
      price: json['price']?.toDouble(),
      location: json['location'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
    );
  }

  // Copy with method for easy updates
  Equipment copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    bool? isAvailable,
    String? category,
    double? price,
    String? location,
    DateTime? createdAt,
  }) {
    return Equipment(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      category: category ?? this.category,
      price: price ?? this.price,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}