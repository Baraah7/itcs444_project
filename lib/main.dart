import 'package:care_center_app/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'screens/equipment_detail_screen.dart';
import 'screens/reservation_confirmation_screen.dart';
import 'screens/reservation_tracking_screen.dart';
import 'models/equipment_model.dart';
import 'utils/theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Care Center - Equipment Rental',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
      routes: {
        '/equipment_detail': (context) {
          final equipment = ModalRoute.of(context)!.settings.arguments as Equipment;
          return EquipmentDetailScreen(equipment: equipment);
        },
        '/reservation_confirmation': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return ReservationConfirmationScreen(
            equipment: args['equipment'] as Equipment,
            startDate: args['startDate'] as DateTime,
            endDate: args['endDate'] as DateTime,
            duration: args['duration'] as int,
          );
        },
        '/reservation_tracking': (context) => const ReservationTrackingScreen(),
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Equipment get _mockEquipment => Equipment(
        id: '1',
        name: 'Premium Wheelchair',
        type: 'Wheelchair',
        description: 'A comfortable and lightweight wheelchair with adjustable features. Perfect for daily use and outdoor activities. Features include padded seat, adjustable armrests, and foldable design for easy storage.',
        imageUrls: [
          'https://images.unsplash.com/photo-1512295091896-6845b0c2f8f8?w=400',
          'https://images.unsplash.com/photo-1576675466969-38eeae4b41f6?w=400',
        ],
        condition: 'excellent',
        quantity: 5,
        availableQuantity: 3,
        location: 'Downtown Care Center',
        rentalPricePerDay: 15.99,
        isRentable: true,
        isDonated: false,
        status: 'available',
        tags: ['lightweight', 'adjustable', 'foldable'],
        addedDate: DateTime.now().subtract(const Duration(days: 30)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Care Center Equipment'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReservationTrackingScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Equipment Reservation System',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Test the complete reservation flow for your task',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            
            // Test Equipment Card
            EquipmentCard(
              name: _mockEquipment.name,
              type: _mockEquipment.type,
              imageUrl: _mockEquipment.imageUrls.isNotEmpty ? _mockEquipment.imageUrls.first : '',
              condition: _mockEquipment.condition,
              pricePerDay: _mockEquipment.rentalPricePerDay,
              isAvailable: _mockEquipment.availableQuantity > 0,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EquipmentDetailScreen(equipment: _mockEquipment),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 20),
            
            // Quick Navigation
            const Text(
              'Quick Navigation:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            AppButton(
              text: 'Start Reservation Flow',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EquipmentDetailScreen(equipment: _mockEquipment),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            
            AppButton(
              text: 'View Reservation Tracking',
              backgroundColor: AppTheme.secondaryColor,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReservationTrackingScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}