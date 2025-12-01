import 'package:flutter/material.dart';
import 'package:itcs444_project/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'providers/equipment_provider.dart';
import 'providers/reservation_provider.dart';
import 'screens/user/equipment_detail.dart';
import 'screens/user/equipment_list.dart';
import 'screens/user/my_reservations.dart';
import 'screens/user/reservation_screen.dart';
import 'screens/user/reservation_detail.dart';
import 'screens/user/user_dashboard.dart'; 
import 'utils/theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()), // Add this
        ChangeNotifierProvider(create: (_) => EquipmentProvider()),
        ChangeNotifierProvider(create: (_) => ReservationProvider()),
        // Add AuthProvider if you have it
        // ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Care Center Equipment Rental',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const UserDashboard(), // Changed to UserDashboard (without Screen)
        '/equipment-list': (context) => const EquipmentListScreen(),
        '/my-reservations': (context) => const MyReservationsScreen(),
      },
      onGenerateRoute: (settings) {
        // Handle reservation screen with equipment parameter
        if (settings.name == '/reservation') {
          final args = settings.arguments as Map<String, dynamic>;
          final equipment = args['equipment'];
          return MaterialPageRoute(
            builder: (context) => ReservationScreen(equipment: equipment),
          );
        }
        
        // Handle equipment detail screen
        if (settings.name == '/equipment-detail') {
          final args = settings.arguments as Map<String, dynamic>;
          final equipmentId = args['equipmentId'];
          return MaterialPageRoute(
            builder: (context) => EquipmentDetailScreen(equipmentId: equipmentId),
          );
        }
        
        // Handle reservation detail screen
        if (settings.name == '/reservation-detail') {
          final args = settings.arguments as Map<String, dynamic>;
          final reservation = args['reservation'];
          return MaterialPageRoute(
            builder: (context) => ReservationDetailScreen(reservation: reservation),
          );
        }
        
        return null;
      },
    );
  }
}