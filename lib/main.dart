import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/user/user_dashboard.dart';
import 'screens/admin/admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const MyApp(),
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
        // '/guest': (_) => const GuestScreen(),
      },
    );
  }
}

class RoleWrapper extends StatelessWidget {
  const RoleWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    // ---------------------------------------------
    // 1. Not logged in → Login Page
    // ---------------------------------------------
    if (!auth.isLoggedIn) {
      return const LoginScreen();
    }

    // ---------------------------------------------
    // 2. Logged in → choose dashboard by role
    // ---------------------------------------------
    if (auth.isAdmin) {
      return const AdminDashboard();
    } else if (auth.isRenter || auth.isDonor) {
      return const UserDashboard();
    } else {
      // Default fallback for any other case
      return const LoginScreen();
    }
  }
}


