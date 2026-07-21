import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hrms_app/screens/claims/claim_entitlements_screen.dart';
import 'package:hrms_app/state/app_state.dart';

void main() {
  testWidgets('lists every entitlement with its category and cap status', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const MaterialApp(home: ClaimEntitlementsScreen()),
      ),
    );

    expect(find.text('Claim entitlements'), findsOneWidget);
    expect(find.text('Outpatient'), findsOneWidget);
    expect(find.text('Dental'), findsOneWidget);
    expect(find.text('Specs'), findsOneWidget);
    expect(find.text('Travel'), findsOneWidget);
    expect(find.text('No cap'), findsOneWidget);
  });
}
