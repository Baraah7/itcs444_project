import 'package:cloud_firestore/cloud_firestore.dart';

class Donation {
  final String itemName;
  final String itemType;
  final String condition;
  final String status;
  final DateTime submissionDate;
  final String donorID;

  // Extra fields
  final String? description;
  final List<String>? images;
  final int? quantity;
  //final bool? pickupNeeded;
  //final String? pickupAddress;
  final DateTime? approvalDate;
  //final String? rejectionReason;
  //final String? assignedStaffID;

  Donation({
    required this.itemName,
    required this.itemType,
    required this.condition,
    required this.status,
    required this.submissionDate,
    required this.donorID,
    this.description,
    this.images,
    this.quantity,
    //this.pickupNeeded,
    //this.pickupAddress,
    this.approvalDate,
    //this.rejectionReason,
    //this.assignedStaffID,
  });

  factory Donation.fromMap(Map<String, dynamic> data, String id) {
    return Donation(
      itemName: data['itemName'] ?? '',
      itemType: data['itemType'] ?? '',
      condition: data['condition'] ?? '',
      status: data['status'] ?? '',
      submissionDate: (data['submissionDate'] as Timestamp).toDate(),
      donorID: data['donorID'] is DocumentReference
          ? (data['donorID'] as DocumentReference).path
          : data['donorID'] ?? '',

      // Extra fields
      description: data['description'],
      images: data['images'] != null
          ? List<String>.from(data['images'])
          : null,
      quantity: data['quantity'],
      //pickupNeeded: data['pickupNeeded'],
      //pickupAddress: data['pickupAddress'],
      approvalDate: data['approvalDate'] != null
          ? (data['approvalDate'] as Timestamp).toDate()
          : null,
      //rejectionReason: data['rejectionReason'],
      //assignedStaffID: data['assignedStaffID'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemName': itemName,
      'itemType': itemType,
      'condition': condition,
      'status': status,
      'submissionDate': submissionDate,
      'donorID': donorID,

      // Extra fields
      'description': description,
      'images': images,
      'quantity': quantity,
      //'pickupNeeded': pickupNeeded,
      //'pickupAddress': pickupAddress,
      'approvalDate': approvalDate,
      //'rejectionReason': rejectionReason,
      //'assignedStaffID': assignedStaffID,
    };
  }
}
