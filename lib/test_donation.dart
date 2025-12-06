import 'package:flutter/material.dart';

// Simple test - no Firebase, no services
void main() {
  runApp(MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: Text('Test')),
      body: Center(child: Text('If this works, donation_page.dart is fine')),
    ),
  ));
}