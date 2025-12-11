import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itcs444_project/requests_management_page.dart';

void main() {
  testWidgets('RequestsManagementPage renders with tabs',
      (WidgetTester tester) async {
    // Build the widget
    await tester.pumpWidget(const MaterialApp(
      home: RequestsManagementPage(),
    ));

    // Verify that tabs are displayed
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Approved'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
  });
}
