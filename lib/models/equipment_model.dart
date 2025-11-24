class Equipment {
  final String id;
  final String name;
  final String type;
  final String description;
  final List<String> imageUrls;
  final String condition;
  final int quantity;
  final int availableQuantity;
  final String location;
  final double? rentalPricePerDay;
  final bool isRentable;
  final bool isDonated;
  final String status;
  final List<String> tags;
  final DateTime addedDate;
  final String? donatedBy;

  Equipment({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.imageUrls,
    required this.condition,
    required this.quantity,
    required this.availableQuantity,
    required this.location,
    this.rentalPricePerDay,
    required this.isRentable,
    required this.isDonated,
    required this.status,
    required this.tags,
    required this.addedDate,
    this.donatedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'description': description,
      'imageUrls': imageUrls,
      'condition': condition,
      'quantity': quantity,
      'availableQuantity': availableQuantity,
      'location': location,
      'rentalPricePerDay': rentalPricePerDay,
      'isRentable': isRentable,
      'isDonated': isDonated,
      'status': status,
      'tags': tags,
      'addedDate': addedDate.millisecondsSinceEpoch,
      'donatedBy': donatedBy,
    };
  }

  factory Equipment.fromMap(Map<String, dynamic> map) {
    return Equipment(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      description: map['description'],
      imageUrls: List<String>.from(map['imageUrls']),
      condition: map['condition'],
      quantity: map['quantity'],
      availableQuantity: map['availableQuantity'],
      location: map['location'],
      rentalPricePerDay: map['rentalPricePerDay'],
      isRentable: map['isRentable'],
      isDonated: map['isDonated'],
      status: map['status'],
      tags: List<String>.from(map['tags']),
      addedDate: DateTime.fromMillisecondsSinceEpoch(map['addedDate']),
      donatedBy: map['donatedBy'],
    );
  }

  Equipment copyWith({
    String? id,
    String? name,
    String? type,
    String? description,
    List<String>? imageUrls,
    String? condition,
    int? quantity,
    int? availableQuantity,
    String? location,
    double? rentalPricePerDay,
    bool? isRentable,
    bool? isDonated,
    String? status,
    List<String>? tags,
    DateTime? addedDate,
    String? donatedBy,
  }) {
    return Equipment(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      imageUrls: imageUrls ?? this.imageUrls,
      condition: condition ?? this.condition,
      quantity: quantity ?? this.quantity,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      location: location ?? this.location,
      rentalPricePerDay: rentalPricePerDay ?? this.rentalPricePerDay,
      isRentable: isRentable ?? this.isRentable,
      isDonated: isDonated ?? this.isDonated,
      status: status ?? this.status,
      tags: tags ?? this.tags,
      addedDate: addedDate ?? this.addedDate,
      donatedBy: donatedBy ?? this.donatedBy,
    );
  }
}