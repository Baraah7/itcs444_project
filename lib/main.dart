import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MyApp(),
    ),
  );
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