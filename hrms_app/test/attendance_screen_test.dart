import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hrms_app/screens/attendance/attendance_screen.dart';
import 'package:hrms_app/state/app_state.dart';

void main() {
  testWidgets('AttendanceScreen shows today\'s status and weekly stats', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const MaterialApp(home: Scaffold(body: AttendanceScreen())),
      ),
    );

    expect(find.text('Attendance'), findsOneWidget);
    expect(find.text('TODAY'), findsOneWidget);
    expect(find.text('This week'), findsOneWidget);
    expect(find.text('Recent'), findsOneWidget);
  });

  testWidgets('Tapping Clock Out completes the face check-in flow and updates state', (tester) async {
    final appState = AppState();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: const MaterialApp(home: Scaffold(body: AttendanceScreen())),
      ),
    );

    expect(find.text('Clock Out'), findsOneWidget);

    await tester.tap(find.text('Clock Out'));
    await tester.pump();
    // The simulated face check-in flow only animates continuously during
    // its first (scanning) stage, so pumpAndSettle alone would stop
    // pumping as soon as that animation ends — before the later
    // verifying/success stages' delayed timers ever fire. Step through
    // the ~2.2s simulated flow explicitly, then let the final pop
    // transition settle.
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(appState.todayAttendance.clockedIn, isFalse);
    expect(find.text('Clock In with Face'), findsOneWidget);
  });

  testWidgets('Tapping View all opens Attendance History', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const MaterialApp(home: Scaffold(body: AttendanceScreen())),
      ),
    );

    await tester.ensureVisible(find.text('View all'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View all'));
    await tester.pumpAndSettle();

    expect(find.text('Attendance History'), findsOneWidget);
  });
}
