import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hrms_app/screens/home/home_screen.dart';
import 'package:hrms_app/state/app_state.dart';

void main() {
  testWidgets('full flow: submit a claim from Home and see it in Claims', (tester) async {
    // The default 800x600 test surface is too short for NewClaimScreen's
    // ListView (claim type chips + amount field + approval flow + submit
    // button): a ListView only builds the children that fit within its
    // viewport, so the submit button below the fold would never be built
    // into the widget tree and a tap on it would fail. Growing the surface
    // lets everything build without scrolling, matching the same fix used
    // in new_claim_screen_test.dart and leave_request_form_screen_test.dart.
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final appState = AppState();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: const MaterialApp(home: Scaffold(body: HomeScreen())),
      ),
    );

    await tester.tap(find.text('Claims'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('New claim'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Outpatient'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, '85');
    await tester.pump();
    await tester.enterText(find.byType(TextField).last, 'Pharmacy purchase');
    await tester.pump();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Submit claim'));
    await tester.pumpAndSettle();

    expect(find.text('Claim submitted'), findsOneWidget);

    await tester.tap(find.text('Back to Claims'));
    await tester.pumpAndSettle();

    expect(find.text('Recent claims'), findsOneWidget);
    expect(appState.claims.first.category, 'Outpatient');
    expect(appState.claims.first.amount, 85.0);
    expect(appState.claims.first.description, 'Pharmacy purchase');
    expect(appState.claims.first.status, 'Pending');
  });
}
