import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_app/widgets/quick_actions_row.dart';

void main() {
  Widget wrap({
    required VoidCallback onAttendanceTap,
    required VoidCallback onLeaveTap,
    required VoidCallback onClaimsTap,
    required VoidCallback onPayslipTap,
  }) => MaterialApp(
    home: Scaffold(
      body: QuickActionsRow(
        onAttendanceTap: onAttendanceTap,
        onLeaveTap: onLeaveTap,
        onClaimsTap: onClaimsTap,
        onPayslipTap: onPayslipTap,
      ),
    ),
  );

  testWidgets('tapping Attendance calls onAttendanceTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(
        onAttendanceTap: () => tapped = true,
        onLeaveTap: () {},
        onClaimsTap: () {},
        onPayslipTap: () {},
      ),
    );

    await tester.tap(find.text('Attendance'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('tapping Leave calls onLeaveTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(
        onAttendanceTap: () {},
        onLeaveTap: () => tapped = true,
        onClaimsTap: () {},
        onPayslipTap: () {},
      ),
    );

    await tester.tap(find.text('Leave'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('tapping Claims calls onClaimsTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(
        onAttendanceTap: () {},
        onLeaveTap: () {},
        onClaimsTap: () => tapped = true,
        onPayslipTap: () {},
      ),
    );

    await tester.tap(find.text('Claims'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('tapping Payslip calls onPayslipTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(
        onAttendanceTap: () {},
        onLeaveTap: () {},
        onClaimsTap: () {},
        onPayslipTap: () => tapped = true,
      ),
    );

    await tester.tap(find.text('Payslip'));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
