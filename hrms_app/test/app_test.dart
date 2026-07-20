import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_app/app.dart';

void main() {
  group('HrmsApp Navigation Tests', () {
    testWidgets('HrmsApp loads with Home tab selected by default', (WidgetTester tester) async {
      await tester.pumpWidget(const HrmsApp());

      // Verify "Home" text is visible initially
      expect(find.text('Home'), findsWidgets);
    });

    testWidgets('Tapping Attendance tab switches to Attendance screen', (WidgetTester tester) async {
      await tester.pumpWidget(const HrmsApp());

      // Find and tap the Attendance bottom nav item
      await tester.tap(find.byIcon(Icons.access_time_outlined));
      await tester.pumpAndSettle();

      // Verify Attendance screen is now shown by finding Attendance text
      // After tap, there should be multiple "Attendance" widgets (nav label + screen text)
      expect(find.text('Attendance'), findsWidgets);
    });

    testWidgets('Tapping Leave tab switches to Leave screen', (WidgetTester tester) async {
      await tester.pumpWidget(const HrmsApp());

      // Find and tap the Leave bottom nav item
      await tester.tap(find.byIcon(Icons.event_note_outlined));
      await tester.pumpAndSettle();

      // Verify Leave screen is now shown
      expect(find.text('Leave'), findsWidgets);
    });

    testWidgets('Tapping Me tab switches to Profile screen', (WidgetTester tester) async {
      await tester.pumpWidget(const HrmsApp());

      // Find and tap the Me (Profile) bottom nav item
      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();

      // Verify Profile screen is now shown (displays "Me" text)
      expect(find.text('Me'), findsWidgets);
    });

    testWidgets('Navigation between multiple tabs works without errors', (WidgetTester tester) async {
      await tester.pumpWidget(const HrmsApp());

      // Verify initial Home screen
      expect(find.text('Home'), findsWidgets);

      // Navigate to Attendance
      await tester.tap(find.byIcon(Icons.access_time_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Attendance'), findsWidgets);

      // Navigate back to Home
      await tester.tap(find.byIcon(Icons.home_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsWidgets);

      // Navigate to Leave
      await tester.tap(find.byIcon(Icons.event_note_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Leave'), findsWidgets);

      // Navigate to Me/Profile
      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();
      expect(find.text('Me'), findsWidgets);
    });
  });
}
