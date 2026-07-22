import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_app/app.dart';
import 'package:hrms_app/widgets/quick_actions_row.dart';

/// Finds an icon within the BottomNavigationBar specifically. Some icons
/// (e.g. attendance/leave) are reused by Home's quick-action shortcuts, so a
/// bare `find.byIcon` can match more than one widget once real dashboard
/// content is on screen.
Finder findNavIcon(IconData icon) => find.descendant(
  of: find.byType(BottomNavigationBar),
  matching: find.byIcon(icon),
);

/// Finds a label within Home's QuickActionsRow specifically. The same
/// labels ("Attendance", "Leave") also appear in the BottomNavigationBar,
/// so a bare `find.text` matches both.
Finder findQuickAction(String label) => find.descendant(
  of: find.byType(QuickActionsRow),
  matching: find.text(label),
);

/// HrmsApp now gates on AppState.isLoggedIn (Phase 8), so every test starts
/// on LoginScreen. Sign in via the Face ID shortcut (fewer steps than
/// filling in the email/password fields) to reach the tab shell.
Future<void> logIn(WidgetTester tester) async {
  await tester.tap(find.text('Sign in with Face ID'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 900));
  await tester.pump(const Duration(milliseconds: 700));
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pumpAndSettle();
}

void main() {
  group('HrmsApp Navigation Tests', () {
    testWidgets('HrmsApp loads with Home tab selected by default', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const HrmsApp());
      await logIn(tester);

      // Verify Home tab is selected (index 0) by checking IndexedStack.index
      expect(
        tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
        equals(0),
      );
      // Verify BottomNavigationBar also shows Home as current
      expect(
        tester
            .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
            .currentIndex,
        equals(0),
      );
    });

    testWidgets('Tapping Attendance tab switches to Attendance screen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const HrmsApp());
      await logIn(tester);

      // Find and tap the Attendance bottom nav item
      await tester.tap(findNavIcon(Icons.access_time_outlined));
      await tester.pumpAndSettle();

      // Verify Attendance tab is now selected (index 1) by checking IndexedStack.index
      expect(
        tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
        equals(1),
      );
      // Verify BottomNavigationBar also shows Attendance as current
      expect(
        tester
            .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
            .currentIndex,
        equals(1),
      );
    });

    testWidgets('Tapping Leave tab switches to Leave screen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const HrmsApp());
      await logIn(tester);

      // Find and tap the Leave bottom nav item
      await tester.tap(findNavIcon(Icons.event_note_outlined));
      await tester.pumpAndSettle();

      // Verify Leave tab is now selected (index 2) by checking IndexedStack.index
      expect(
        tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
        equals(2),
      );
      // Verify BottomNavigationBar also shows Leave as current
      expect(
        tester
            .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
            .currentIndex,
        equals(2),
      );
    });

    testWidgets('Tapping Me tab switches to Profile screen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const HrmsApp());
      await logIn(tester);

      // Find and tap the Me (Profile) bottom nav item
      await tester.tap(findNavIcon(Icons.person_outline));
      await tester.pumpAndSettle();

      // Verify Me tab is now selected (index 3) by checking IndexedStack.index
      expect(
        tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
        equals(3),
      );
      // Verify BottomNavigationBar also shows Me as current
      expect(
        tester
            .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
            .currentIndex,
        equals(3),
      );
    });

    testWidgets('Navigation between multiple tabs works without errors', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const HrmsApp());
      await logIn(tester);

      // Verify initial Home tab (index 0)
      expect(
        tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
        equals(0),
      );

      // Navigate to Attendance (index 1)
      await tester.tap(findNavIcon(Icons.access_time_outlined));
      await tester.pumpAndSettle();
      expect(
        tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
        equals(1),
      );

      // Navigate back to Home (index 0)
      await tester.tap(findNavIcon(Icons.home_outlined));
      await tester.pumpAndSettle();
      expect(
        tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
        equals(0),
      );

      // Navigate to Leave (index 2)
      await tester.tap(findNavIcon(Icons.event_note_outlined));
      await tester.pumpAndSettle();
      expect(
        tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
        equals(2),
      );

      // Navigate to Me/Profile (index 3)
      await tester.tap(findNavIcon(Icons.person_outline));
      await tester.pumpAndSettle();
      expect(
        tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
        equals(3),
      );
    });

    testWidgets(
      'Tapping the Attendance quick action on Home switches to the Attendance tab',
      (WidgetTester tester) async {
        await tester.pumpWidget(const HrmsApp());
        await logIn(tester);

        await tester.tap(findQuickAction('Attendance'));
        await tester.pumpAndSettle();

        expect(
          tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
          equals(1),
        );
        expect(
          tester
              .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
              .currentIndex,
          equals(1),
        );
      },
    );

    testWidgets(
      'Tapping the Leave quick action on Home switches to the Leave tab',
      (WidgetTester tester) async {
        await tester.pumpWidget(const HrmsApp());
        await logIn(tester);

        await tester.tap(findQuickAction('Leave'));
        await tester.pumpAndSettle();

        expect(
          tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
          equals(2),
        );
        expect(
          tester
              .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
              .currentIndex,
          equals(2),
        );
      },
    );
  });
}
