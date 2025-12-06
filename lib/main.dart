import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/shared/donation_form.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //await Firebase.initializeApp();

  //new web stuff
  if (kIsWeb) {
    // Web initialization with YOUR FIREBASE CONFIG
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyB7ckqv8rC21nfbY9i3eq1J5WHWW4HHdqI",
        authDomain: "project-8094b.firebaseapp.com",
        projectId: "project-8094b",
        storageBucket: "project-8094b.firebasestorage.app",
        messagingSenderId: "612721487222",
        appId: "1:612721487222:web:a6a5ecfefcd728e7355e57",
        measurementId: "G-NZ0ZBGLNJP",
      ),
    );
  } else {
    // Android initialization (uses google-services.json)
    await Firebase.initializeApp();
  }

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DonationForm(title: ''),
    );
  }
}
