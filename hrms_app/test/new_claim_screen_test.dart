import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hrms_app/screens/claims/new_claim_screen.dart';
import 'package:hrms_app/state/app_state.dart';

void main() {
  testWidgets('submit is disabled until type, amount, and description are provided', (tester) async {
    // The default 800x600 test surface is too short for this screen's
    // ListView (claim type chips + amount field + approval flow + submit
    // button): a ListView only builds the children that fit within its
    // viewport, so anything below the fold (like the submit button) would
    // never be built into the widget tree and finders/taps on it would fail.
    // Growing the surface lets everything build without scrolling, matching
    // the same short-viewport fix used in leave_request_form_screen_test.dart.
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final appState = AppState();
    final before = appState.claims.length;

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: const MaterialApp(home: NewClaimScreen()),
      ),
    );

    final submitFinder = find.widgetWithText(ElevatedButton, 'Submit claim');
    expect(tester.widget<ElevatedButton>(submitFinder).onPressed, isNull);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Dental'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, '120');
    await tester.pump();
    await tester.enterText(find.byType(TextField).last, 'Cleaning');
    await tester.pump();

    expect(tester.widget<ElevatedButton>(submitFinder).onPressed, isNotNull);

    await tester.tap(submitFinder);
    await tester.pumpAndSettle();

    expect(find.text('Claim submitted'), findsOneWidget);
    expect(appState.claims.length, before + 1);
    expect(appState.claims.first.category, 'Dental');
    expect(appState.claims.first.amount, 120.0);
  });

  testWidgets('selecting Travel requires a project before submit is enabled', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final appState = AppState();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: const MaterialApp(home: NewClaimScreen()),
      ),
    );

    await tester.tap(find.widgetWithText(ChoiceChip, 'Travel'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, '300');
    await tester.pump();
    await tester.enterText(find.byType(TextField).last, 'Client visit');
    await tester.pump();

    final submitFinder = find.widgetWithText(ElevatedButton, 'Submit claim');
    expect(tester.widget<ElevatedButton>(submitFinder).onPressed, isNull);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Project Atlas'));
    await tester.pump();

    expect(tester.widget<ElevatedButton>(submitFinder).onPressed, isNotNull);
  });

  testWidgets('an amount over the remaining limit shows a warning but stays submittable', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final appState = AppState();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: const MaterialApp(home: NewClaimScreen()),
      ),
    );

    await tester.tap(find.widgetWithText(ChoiceChip, 'Specs'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, '500');
    await tester.pump();

    expect(find.textContaining('over your remaining limit'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'New glasses');
    await tester.pump();

    final submitFinder = find.widgetWithText(ElevatedButton, 'Submit claim');
    expect(tester.widget<ElevatedButton>(submitFinder).onPressed, isNotNull);
  });
}
