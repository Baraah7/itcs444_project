import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/donation_model.dart';
import 'notification_service.dart';

class DonationService {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;
  final NotificationService _notificationService = NotificationService();

  Future<List<String>> uploadDonationImages(List<File> files) async {
    final List<String> downloadUrls = [];

    for (final file in files) {
      try {
        final millis = DateTime.now().millisecondsSinceEpoch;
        final ref = storage.ref().child(
          'donation_images/$millis-${file.path.split('/').last}',
        );

        final uploadTask = await ref.putFile(file);

        if (uploadTask.state != TaskState.success) {
          throw Exception('Upload failed for ${file.path}');
        }

        final url = await ref.getDownloadURL();
        downloadUrls.add(url);
      } on FirebaseException catch (e) {
        print('❌ Error uploading image ${file.path}: $e');
      }
    }

    return downloadUrls;
  }

  // Submit donation with ALL fields including image paths
  Future<String> submitDonation({
    required String itemName,
    required String donorName,
    required String donorContact,
    required String donorPhone,
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
    int? iconCode,
    String? donorID,
  }) async {
    try {
      // Create Donation object with ALL fields
      Donation donation = Donation(
        itemName: itemName,
        donorName: donorName,
        donorContact: donorContact,
        donorPhone: donorPhone,
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
        iconCode: iconCode,
        donorID: donorID,
      );

      // Save to Firestore
      final docRef = await db.collection('donations').add(donation.toMap());

      print('✅ Donation submitted with ID: ${docRef.id}');

      // Notify admins about new donation
      await _notificationService.sendAdminNotification(
        title: 'New Donation Submitted',
        message: 'User $donorName submitted a donation for "$itemName".',
        type: 'donation',
        data: {'donationId': docRef.id},
      );

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
    // 1) Update donation status
    final donationRef = db.collection('donations').doc(donationID);
    await donationRef.update({
      'status': 'Approved',
      'approvalDate': DateTime.now(),
    });

    // 2) Read donation data
    final snapshot = await donationRef.get();
    if (!snapshot.exists) return;

    final donation = snapshot.data() as Map<String, dynamic>;

    // Notify the donor about approval
    final donorId = donation['donorID'] as String?;
    final itemName = donation['itemName'] as String? ?? 'item';
    if (donorId != null) {
      await _notificationService.sendNotification(
        userId: donorId,
        title: 'Donation Approved',
        message: 'Your donation "$itemName" has been approved. Thank you for your contribution!',
        type: 'donation',
        data: {'donationId': donationID},
      );
    }

    final String itemType = (donation['itemType'] ?? '').toString();
    if (itemType.isEmpty) {
      print('❌ Cannot approve donation: itemType is empty');
      return;
    }

    // Quantity: fall back to 1 if null / weird
    int quantity = 1;
    final rawQty = donation['quantity'];
    if (rawQty is int) {
      quantity = rawQty;
    } else if (rawQty != null) {
      quantity = int.tryParse(rawQty.toString()) ?? 1;
    }

    // 3) Reference: equipment/{itemType}/Items
    final itemsCollection = db
        .collection('equipment')
        .doc(itemType)
        .collection('Items');

    // Data for each physical item
    final baseData = {
      'name': donation['itemName'],
      'type': itemType,
      'description': donation['description'],
      'condition': donation['condition'],
      'availability': true, // ✅ important
      'donatedOn': donation['submissionDate'],
      'imagePaths': donation['imagePaths'] ?? [],
      'donationId': donationRef.id, // optional but useful
    };

    // 4) Create one document per physical item
    final batch = db.batch();
    for (var i = 0; i < quantity; i++) {
      final itemDoc = itemsCollection.doc();
      batch.set(itemDoc, baseData);
    }
    await batch.commit();

    print(
      '✅ Approved donation $donationID and added $quantity items under equipment/$itemType/Items',
    );
  }

  //reject donation
  Future<void> rejectDonation(String donationID) async {
    final docref = db.collection('donations').doc(donationID);
    await docref.update({
      'status': 'Rejected',
      'rejectionDate': DateTime.now(),
    });
  }

  //fetch donation by user id
  Future<List<Donation>> fetchDonationsByUserId(String userId) async {
  final snapshot = await db
      .collection('donations')
      .where('donorID', isEqualTo: userId)
      //.where('status', isEqualTo: 'Approved')
      //.orderBy('submissionDate', descending: true) // add back if you like (may need index)
      .get();

  return snapshot.docs.map((doc) {
    return Donation.fromMap(doc.data(), doc.id);
  }).toList();
}
}
