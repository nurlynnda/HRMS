import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_app/screens/profile/coming_soon_screen.dart';

void main() {
  testWidgets('shows the given title and a coming-soon message', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: ComingSoonScreen(title: 'Payslips')),
    );

    expect(find.text('Payslips'), findsOneWidget);
    expect(find.text('Payslips is coming soon'), findsOneWidget);
  });
}
