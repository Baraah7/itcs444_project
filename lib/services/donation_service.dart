import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/donation_model.dart';

class DonationService {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  // Submit donation with ALL fields including image paths
  Future<String> submitDonation({
    required String itemName,
    required String donorName,
    required String donorContact,
    required String itemType,
    required String condition,
    required String status,
    required DateTime submissionDate,
    String? description,
    List<String>? imagePaths, // Local file paths
    int? quantity,
    DateTime? approvalDate,
    DateTime? rejectionDate,
    String? comments,
  }) async {
    try {
      // Create Donation object with ALL fields
      Donation donation = Donation(
        itemName: itemName,
        donorName: donorName,
        donorContact: donorContact,
        itemType: itemType,
        condition: condition,
        status: status,
        submissionDate: submissionDate,
        description: description,
        imagePaths: imagePaths, // Store local paths
        quantity: quantity,
        approvalDate: approvalDate,
        rejectionDate: rejectionDate,
        comments: comments,
      );

      // Save to Firestore
      final docRef = await db.collection('donations').add(donation.toMap());

      print('✅ Donation submitted with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print("❌ Error submitting donation: $e");
      rethrow;
    }
  }

  //fetch one donation
  Future<Donation> fetchDonation(String donationId) async {
    final docRef = FirebaseFirestore.instance
        .collection("donations")
        .doc(donationId);

    DocumentSnapshot doc = await docRef.get();

    if (!doc.exists) {
      throw Exception("Donation not found");
    }

    return Donation.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  //fetch donations
  Future<List<Donation>> fetchAllDonations() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection("donations")
        .get();

    return snapshot.docs.map((doc) {
      return Donation.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
  }

  //approve donation
  Future<void> approveDonation(String donationID) async {
    final donationRef = db.collection('donations').doc(donationID);
    await donationRef.update({
      'status': 'Approved',
      'approvalDate': DateTime.now(),
    });

    final snapshot = await donationRef.get();
    if (!snapshot.exists) return;

    final donation = snapshot.data() as Map<String, dynamic>;

    await db.collection('equipment').add({
      'name': donation['itemName'],
      'type': donation['itemType'],
      'description': donation['description'],
      'condition': donation['condition'],
      'quantity': donation['quantity'] ?? 1,
      'status': 'Available', // Default equipment status
      //'donatedBy': donation['donorName'], // Optional: track donor
      'donatedOn': donation['submissionDate'],
      'images': donation['imagePaths'] ?? [],
    });
  }

  //reject donation
  Future<void> rejectDonation(String donationID) async {
    final docref = db.collection('donations').doc(donationID);
    await docref.update({
      'status': 'Rejected',
      'rejectionDate': DateTime.now(),
    });
  }

  //store images
  Future<List<String>> uploadDonationImages(List<File> files) async {
    final List<String> downloadUrls = [];

    for (final file in files) {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = storage.ref().child('donation_images/$fileName.jpg');

      // Upload file
      await ref.putFile(file);

      // Get public URL
      final url = await ref.getDownloadURL();
      downloadUrls.add(url);
    }

    return downloadUrls;
  }
}
