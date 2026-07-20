import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hrms_app/screens/leave/leave_screen.dart';
import 'package:hrms_app/state/app_state.dart';

void main() {
  testWidgets('LeaveScreen shows holiday banner, calendar, and requests', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const MaterialApp(home: Scaffold(body: LeaveScreen())),
      ),
    );

    expect(find.text('Leave'), findsOneWidget);
    expect(find.text('Team calendar'), findsOneWidget);
    expect(find.text("Who's away this week"), findsOneWidget);
    expect(find.text('My requests'), findsOneWidget);
  });

  testWidgets('Tapping a request opens its detail page', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const MaterialApp(home: Scaffold(body: LeaveScreen())),
      ),
    );

    await tester.ensureVisible(find.text('Annual Leave').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annual Leave').first);
    await tester.pumpAndSettle();

    expect(find.text('Request details'), findsOneWidget);
  });

  testWidgets('Tapping the history icon opens Leave History', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const MaterialApp(home: Scaffold(body: LeaveScreen())),
      ),
    );

    await tester.tap(find.byIcon(Icons.history));
    await tester.pumpAndSettle();

    expect(find.text('Leave History'), findsOneWidget);
  });
}
