//Donation submissions + approval status
class Donation {
  final String id;
  final String donorId;
  final String donorName;
  final String equipmentName;
  final String equipmentDescription;
  final String? equipmentImageUrl;
  final double estimatedValue;
  final DonationStatus status;
  final DateTime donationDate;
  final String? notes;
  final String? adminNotes;

  Donation({
    required this.id,
    required this.donorId,
    required this.donorName,
    required this.equipmentName,
    required this.equipmentDescription,
    this.equipmentImageUrl,
    required this.estimatedValue,
    required this.status,
    required this.donationDate,
    this.notes,
    this.adminNotes,
  });

  // Convert Donation object to Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'donorId': donorId,
      'donorName': donorName,
      'equipmentName': equipmentName,
      'equipmentDescription': equipmentDescription,
      'equipmentImageUrl': equipmentImageUrl,
      'estimatedValue': estimatedValue,
      'status': status.toString().split('.').last,
      'donationDate': donationDate.toIso8601String(),
      'notes': notes,
      'adminNotes': adminNotes,
    };
  }

  // Create Donation object from Map
  factory Donation.fromJson(Map<String, dynamic> json) {
    return Donation(
      id: json['id'] ?? '',
      donorId: json['donorId'] ?? '',
      donorName: json['donorName'] ?? '',
      equipmentName: json['equipmentName'] ?? '',
      equipmentDescription: json['equipmentDescription'] ?? '',
      equipmentImageUrl: json['equipmentImageUrl'],
      estimatedValue: (json['estimatedValue'] ?? 0).toDouble(),
      status: _parseDonationStatus(json['status']),
      donationDate: DateTime.parse(json['donationDate']),
      notes: json['notes'],
      adminNotes: json['adminNotes'],
    );
  }

  // Helper method to parse status string to enum
  static DonationStatus _parseDonationStatus(String status) {
    switch (status) {
      case 'pending':
        return DonationStatus.pending;
      case 'underReview':
        return DonationStatus.underReview;
      case 'accepted':
        return DonationStatus.accepted;
      case 'rejected':
        return DonationStatus.rejected;
      case 'processed':
        return DonationStatus.processed;
      default:
        return DonationStatus.pending;
    }
  }

  // Copy with method for easy updates
  Donation copyWith({
    String? id,
    String? donorId,
    String? donorName,
    String? equipmentName,
    String? equipmentDescription,
    String? equipmentImageUrl,
    double? estimatedValue,
    DonationStatus? status,
    DateTime? donationDate,
    String? notes,
    String? adminNotes,
  }) {
    return Donation(
      id: id ?? this.id,
      donorId: donorId ?? this.donorId,
      donorName: donorName ?? this.donorName,
      equipmentName: equipmentName ?? this.equipmentName,
      equipmentDescription: equipmentDescription ?? this.equipmentDescription,
      equipmentImageUrl: equipmentImageUrl ?? this.equipmentImageUrl,
      estimatedValue: estimatedValue ?? this.estimatedValue,
      status: status ?? this.status,
      donationDate: donationDate ?? this.donationDate,
      notes: notes ?? this.notes,
      adminNotes: adminNotes ?? this.adminNotes,
    );
  }

  // Helper methods
  bool get isPending => status == DonationStatus.pending;
  bool get isUnderReview => status == DonationStatus.underReview;
  bool get isAccepted => status == DonationStatus.accepted;
  bool get isRejected => status == DonationStatus.rejected;
  bool get isProcessed => status == DonationStatus.processed;
}

enum DonationStatus {
  pending,
  underReview,
  accepted,
  rejected,
  processed,
}