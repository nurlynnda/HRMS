import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hrms_app/screens/profile/profile_screen.dart';
import 'package:hrms_app/state/app_state.dart';

void main() {
  testWidgets('shows the employee header, badges, and menu items', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const MaterialApp(home: Scaffold(body: ProfileScreen())),
      ),
    );

    expect(find.text('Sarah Chen'), findsOneWidget);
    expect(find.text('Product Designer · Design'), findsOneWidget);
    expect(find.text('EMP-2041'), findsOneWidget);
    expect(find.text('Full-time'), findsOneWidget);
    expect(find.text('Personal information'), findsOneWidget);
    expect(find.text('Documents'), findsOneWidget);
    expect(find.text('Payslips'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('tapping Personal information opens its detail screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const MaterialApp(home: Scaffold(body: ProfileScreen())),
      ),
    );

    await tester.tap(find.text('Personal information'));
    await tester.pumpAndSettle();

    expect(find.text('Basic details'), findsOneWidget);
  });

  testWidgets('tapping Documents opens the coming-soon placeholder', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const MaterialApp(home: Scaffold(body: ProfileScreen())),
      ),
    );

    await tester.tap(find.text('Documents'));
    await tester.pumpAndSettle();

    expect(find.text('Documents is coming soon'), findsOneWidget);
  });

  testWidgets('tapping Log out logs the user out', (tester) async {
    final appState = AppState();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: const MaterialApp(home: Scaffold(body: ProfileScreen())),
      ),
    );

    appState.logIn();
    expect(appState.isLoggedIn, isTrue);

    await tester.tap(find.text('Log out'));
    await tester.pump();

    expect(appState.isLoggedIn, isFalse);
  });

  testWidgets('tapping Payslips opens the payslip screen', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const MaterialApp(home: Scaffold(body: ProfileScreen())),
      ),
    );

    await tester.tap(find.text('Payslips'));
    await tester.pumpAndSettle();

    expect(find.text('Payslip history'), findsOneWidget);
  });
}
