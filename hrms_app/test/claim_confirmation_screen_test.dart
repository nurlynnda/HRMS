import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_app/screens/claims/claim_confirmation_screen.dart';

void main() {
  testWidgets('shows the submitted claim summary and pops back to the previous screen on tap', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ClaimConfirmationScreen(
                      category: 'Dental',
                      amount: 200.0,
                      reference: 'CLM-1005',
                    ),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Claim submitted'), findsOneWidget);
    expect(find.text('Dental'), findsOneWidget);
    expect(find.text('RM 200.00'), findsOneWidget);
    expect(find.text('CLM-1005'), findsOneWidget);

    await tester.tap(find.text('Back to Claims'));
    await tester.pumpAndSettle();

    expect(find.text('open'), findsOneWidget);
    expect(find.text('Claim submitted'), findsNothing);
  });
}
