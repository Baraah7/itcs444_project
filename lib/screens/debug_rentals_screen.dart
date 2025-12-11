import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DebugRentalsScreen extends StatelessWidget {
  const DebugRentalsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug Rentals')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('rentals').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 60, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: ${snapshot.error}'),
                    const SizedBox(height: 16),
                    Text('Current User: ${FirebaseAuth.instance.currentUser?.uid ?? "Not logged in"}'),
                  ],
                ),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Rentals: ${docs.length}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Current User: ${FirebaseAuth.instance.currentUser?.uid ?? "Not logged in"}'),
                      Text('User Email: ${FirebaseAuth.instance.currentUser?.email ?? "N/A"}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(data['equipmentName'] ?? 'N/A'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('User: ${data['userFullName'] ?? 'N/A'}'),
                        Text('UserID: ${data['userId'] ?? 'N/A'}'),
                        Text('Status: ${data['status'] ?? 'N/A'}'),
                        Text('ID: ${doc.id}'),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }
}
