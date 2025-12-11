// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:mockito/mockito.dart';
// import 'package:itcs444_project/models/reservation_model.dart';
// import 'package:itcs444_project/services/reservation_service.dart';
// import 'package:itcs444_project/requests_management_page.dart';

// class MockReservationService extends Mock implements ReservationService {}

// void main() {
//   testWidgets('Reservations marked as available or under maintenance should not be displayed', (WidgetTester tester) async {
//     // Mock the reservation service to return a list of reservations with different statuses
//     final mockReservationService = MockReservationService();
//     when(mockReservationService.getReservationsStream()).thenAnswer((_) => Stream.fromIterable([
//       [
//         Reservation(id: '1', equipmentId: 'eq1', userId: 'user1', startTime: DateTime.now(), endTime: DateTime.now().add(Duration(hours: 1)), status: 'pending'),
//         Reservation(id: '2', equipmentId: 'eq2', userId: 'user2', startTime: DateTime.now(), endTime: DateTime.now().add(Duration(hours: 1)), status: 'available'),
//         Reservation(id: '3', equipmentId: 'eq3', userId: 'user3', startTime: DateTime.now(), endTime: DateTime.now().add(Duration(hours: 1)), status: 'under maintenance'),
//       ]
//     ]));

//     // Build the widget
//     await tester.pumpWidget(MaterialApp(
//       home: RequestsManagementPage(reservationService: mockReservationService),
//     ));

//     // Wait for the stream to emit the data
//     await tester.pumpAndSettle();

//     // Verify that only the pending reservation is displayed
//     expect(find.text('pending'), findsOneWidget);
//     expect(find.text('available'), findsNothing);
//     expect(find.text('under maintenance'), findsNothing);
//   });
// }
