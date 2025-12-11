import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/tracking_providers.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/user/user_dashboard.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/admin/equipment_management.dart';
import 'services/background_notification_service.dart';
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

  // Initialize background notification service
  final backgroundService = BackgroundNotificationService();
  backgroundService.startMonitoring();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => TrackingProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Care Center App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const RoleWrapper(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/user-dashboard': (_) => const UserDashboard(),
        '/admin-dashboard': (_) => const AdminDashboard(),
        '/equipment-management': (_) => const EquipmentPage(),
      },
    );
  }
}

class RoleWrapper extends StatelessWidget {
  const RoleWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if (auth.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!auth.isLoggedIn) {
          return const LoginScreen();
        }

        final user = auth.currentUser;
        if (user == null) {
          return const LoginScreen();
        }

        switch (user.role.toLowerCase()) {
          case 'admin':
            return const AdminDashboard();
          case 'user':
            return const UserDashboard();
          default:
            return const LoginScreen();
        }
      },
    );

  }
}
