import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  // CRITICAL: Initialize Firebase BEFORE runApp
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 Starting Firebase initialization...');
  try {
    await Firebase.initializeApp();
    print('✅✅✅ FIREBASE INITIALIZED SUCCESSFULLY! ✅✅✅');
  } catch (e) {
    print('❌❌❌ FIREBASE ERROR: $e ❌❌❌');
    rethrow; // Show the actual error
  }
  
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: Text('Firebase Test')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check, color: Colors.green, size: 60),
              SizedBox(height: 20),
              Text(
                'Firebase Test',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text('If you see the green checkmark and no errors,\nFirebase is working!'),
              SizedBox(height: 30),
              Text('Check VS Code console for messages:'),
              SizedBox(height: 10),
              Text('✅ Should see: "FIREBASE INITIALIZED SUCCESSFULLY!"'),
            ],
          ),
        ),
      ),
    );
  }
}