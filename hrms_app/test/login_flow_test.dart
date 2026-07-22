import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_app/app.dart';

void main() {
  testWidgets('signing in with email and password reaches the Home tab', (
    tester,
  ) async {
    await tester.pumpWidget(const HrmsApp());

    expect(find.text('Welcome back'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('loginEmailField')),
      'sarah.chen@company.com',
    );
    await tester.enterText(
      find.byKey(const Key('loginPasswordField')),
      'password',
    );
    await tester.pump();

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsNothing);
    expect(find.text('Sarah Chen'), findsOneWidget);
  });
}
