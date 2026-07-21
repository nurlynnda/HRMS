import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hrms_app/screens/payslip/payslip_screen.dart';
import 'package:hrms_app/state/app_state.dart';

void main() {
  testWidgets('shows the latest payslip summary and full history', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const MaterialApp(home: PayslipScreen()),
      ),
    );

    expect(find.text('Payslip history'), findsOneWidget);
    expect(find.text('View details'), findsOneWidget);
    expect(find.text('June 2026'), findsOneWidget);
    expect(find.text('May 2026'), findsOneWidget);
  });

  testWidgets('tapping View details opens the latest payslip detail screen', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const MaterialApp(home: PayslipScreen()),
      ),
    );

    await tester.tap(find.text('View details'));
    await tester.pumpAndSettle();

    expect(find.text('Payslip PS-2026-06'), findsOneWidget);
  });

  testWidgets('tapping a payslip row opens its own detail screen', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const MaterialApp(home: PayslipScreen()),
      ),
    );

    await tester.tap(find.text('May 2026'));
    await tester.pumpAndSettle();

    expect(find.text('Payslip PS-2026-05'), findsOneWidget);
  });
}
