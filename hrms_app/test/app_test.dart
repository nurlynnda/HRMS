import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_app/app.dart';

void main() {
  group('HrmsApp Navigation Tests', () {
    testWidgets('HrmsApp loads with Home tab selected by default', (WidgetTester tester) async {
      await tester.pumpWidget(const HrmsApp());

      // Verify Home tab is selected (index 0) by checking IndexedStack.index
      expect(
        tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
        equals(0),
      );
      // Verify BottomNavigationBar also shows Home as current
      expect(
        tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar)).currentIndex,
        equals(0),
      );
    });

    testWidgets('Tapping Attendance tab switches to Attendance screen', (WidgetTester tester) async {
      await tester.pumpWidget(const HrmsApp());

      // Find and tap the Attendance bottom nav item
      await tester.tap(find.byIcon(Icons.access_time_outlined));
      await tester.pumpAndSettle();

      // Verify Attendance tab is now selected (index 1) by checking IndexedStack.index
      expect(
        tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
        equals(1),
      );
      // Verify BottomNavigationBar also shows Attendance as current
      expect(
        tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar)).currentIndex,
        equals(1),
      );
    });

    testWidgets('Tapping Leave tab switches to Leave screen', (WidgetTester tester) async {
      await tester.pumpWidget(const HrmsApp());

      // Find and tap the Leave bottom nav item
      await tester.tap(find.byIcon(Icons.event_note_outlined));
      await tester.pumpAndSettle();

      // Verify Leave tab is now selected (index 2) by checking IndexedStack.index
      expect(
        tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
        equals(2),
      );
      // Verify BottomNavigationBar also shows Leave as current
      expect(
        tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar)).currentIndex,
        equals(2),
      );
    });

    testWidgets('Tapping Me tab switches to Profile screen', (WidgetTester tester) async {
      await tester.pumpWidget(const HrmsApp());

      // Find and tap the Me (Profile) bottom nav item
      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();

      // Verify Me tab is now selected (index 3) by checking IndexedStack.index
      expect(
        tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
        equals(3),
      );
      // Verify BottomNavigationBar also shows Me as current
      expect(
        tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar)).currentIndex,
        equals(3),
      );
    });

    testWidgets('Navigation between multiple tabs works without errors', (WidgetTester tester) async {
      await tester.pumpWidget(const HrmsApp());

      // Verify initial Home tab (index 0)
      expect(
        tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
        equals(0),
      );

      // Navigate to Attendance (index 1)
      await tester.tap(find.byIcon(Icons.access_time_outlined));
      await tester.pumpAndSettle();
      expect(
        tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
        equals(1),
      );

      // Navigate back to Home (index 0)
      await tester.tap(find.byIcon(Icons.home_outlined));
      await tester.pumpAndSettle();
      expect(
        tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
        equals(0),
      );

      // Navigate to Leave (index 2)
      await tester.tap(find.byIcon(Icons.event_note_outlined));
      await tester.pumpAndSettle();
      expect(
        tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
        equals(2),
      );

      // Navigate to Me/Profile (index 3)
      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();
      expect(
        tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
        equals(3),
      );
    });
  });
}
