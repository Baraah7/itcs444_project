import 'package:cloud_firestore/cloud_firestore.dart';

const Map<String, int> defaultIconCodes = {
  'Wheelchair': 0xedd8,         
  'Electrical Bed': 57562,     
  'Mechanical Bed': 58810,    
  'Shower Chair': 0xe14e,    
  'Walker': 0xe1e1,          
  'Walker with Wheels': 985172,  
  'Crutches': 58433,            
};


class Donation {
  final String? id;
  final String itemName;
  final String itemType;
  final String condition;
  final DateTime submissionDate;
  final String status;
  final String donorName;
  final String donorContact;
  final String? description;
  final List<String>? imagePaths; // CHANGED: from images to imagePaths
  final int? quantity;
  final DateTime? approvalDate;
  final DateTime? rejectionDate;
  final String? comments;
  final int? iconCode;

  Donation({
    this.id,
    required this.itemName,
    required this.donorName,
    required this.donorContact,
    required this.itemType,
    required this.status,
    required this.condition,
    required this.submissionDate,
    required this.description,
    this.imagePaths, // CHANGED
    required this.quantity,
    this.approvalDate,
    this.rejectionDate,
    this.comments,
    this.iconCode,
  });

  factory Donation.fromMap(Map<String, dynamic> data, String id) {
    return Donation(
      id: id,
      itemName: data['itemName'] ?? '',
      donorName: data['donorName'] ?? '',
      donorContact: data['donorContact'] ?? '',
      status: data['status'] ?? '',
      itemType: data['itemType'] ?? '',
      condition: data['condition'] ?? '',
      submissionDate: (data['submissionDate'] as Timestamp).toDate(),     
      description: data['description'],
      imagePaths: data['imagePaths'] != null // CHANGED
          ? List<String>.from(data['imagePaths'])
          : null,
      quantity: data['quantity'],
      approvalDate: (data['approvalDate'] as Timestamp?)?.toDate(),
      rejectionDate: (data['rejectionDate'] as Timestamp?)?.toDate(),
          comments: data['comments'],
      iconCode: data['iconCode'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemName': itemName,
      'donorName': donorName,
      'donorContact': donorContact,
      'itemType': itemType,
      'status': status,
      'condition': condition,
      'submissionDate': submissionDate,
      'description': description,
      'imagePaths': imagePaths, // CHANGED
      'quantity': quantity,
      'approvalDate': approvalDate,
      'rejectionDate': rejectionDate,
      'comments': comments,
      'iconCode': iconCode,
    };
  }
}