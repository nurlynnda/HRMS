import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hrms_app/screens/claims/claims_screen.dart';
import 'package:hrms_app/state/app_state.dart';

void main() {
  testWidgets('shows pending/approved summary tiles and the recent claims list', (tester) async {
    final appState = AppState();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: const MaterialApp(home: ClaimsScreen()),
      ),
    );

    expect(find.text('Pending'), findsWidgets);
    expect(find.text('Approved YTD'), findsOneWidget);
    expect(find.text('Claim entitlements'), findsOneWidget);
    expect(find.text('Recent claims'), findsOneWidget);
    expect(find.text('Outpatient'), findsWidgets);
  });

  testWidgets('tapping a claim opens its detail screen', (tester) async {
    final appState = AppState();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: const MaterialApp(home: ClaimsScreen()),
      ),
    );

    await tester.tap(find.text('Jun 28 · CLM-0468'));
    await tester.pumpAndSettle();

    expect(find.text('Claim details'), findsOneWidget);
  });

  testWidgets('tapping Claim entitlements opens the entitlements screen', (tester) async {
    final appState = AppState();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: const MaterialApp(home: ClaimsScreen()),
      ),
    );

    await tester.tap(find.text('Claim entitlements'));
    await tester.pumpAndSettle();

    expect(find.text("Your claim limits and what's left."), findsOneWidget);
  });

  testWidgets('tapping New claim opens the new claim form', (tester) async {
    final appState = AppState();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: const MaterialApp(home: ClaimsScreen()),
      ),
    );

    await tester.tap(find.text('New claim'));
    await tester.pumpAndSettle();

    expect(find.text('Claim type'), findsOneWidget);
  });
}
