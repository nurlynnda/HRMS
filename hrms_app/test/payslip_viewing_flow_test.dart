import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hrms_app/screens/home/home_screen.dart';
import 'package:hrms_app/state/app_state.dart';

void main() {
  testWidgets('full flow: open Payslip from Home and view the latest payslip detail', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const MaterialApp(home: Scaffold(body: HomeScreen())),
      ),
    );

    await tester.tap(find.text('Payslip'));
    await tester.pumpAndSettle();

    expect(find.text('Payslip history'), findsOneWidget);
    expect(find.text('May 2026'), findsOneWidget);

    await tester.tap(find.text('View details'));
    await tester.pumpAndSettle();

    expect(find.text('June 2026'), findsOneWidget);
    expect(find.text('Payslip PS-2026-06'), findsOneWidget);
    expect(find.text('Earnings'), findsOneWidget);
    expect(find.text('Deductions'), findsOneWidget);
  });
}
