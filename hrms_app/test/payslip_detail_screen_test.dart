import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_app/models/payslip.dart';
import 'package:hrms_app/models/payslip_line_item.dart';
import 'package:hrms_app/screens/payslip/payslip_detail_screen.dart';

const _payslip = Payslip(
  id: 'PS-2026-06',
  month: 'June 2026',
  period: '1 – 30 Jun 2026',
  payDate: 'Jun 28',
  status: 'Paid',
  earnings: [
    PayslipLineItem(label: 'Basic salary', amount: 6000.00),
    PayslipLineItem(label: 'Allowance', amount: 500.00),
  ],
  deductions: [
    PayslipLineItem(label: 'EPF', amount: 700.00),
    PayslipLineItem(label: 'SOCSO', amount: 40.00),
    PayslipLineItem(label: 'EIS', amount: 10.00),
    PayslipLineItem(label: 'PCB', amount: 300.00),
  ],
);

void main() {
  testWidgets(
    'shows month title, net pay, earnings, deductions, and download button',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: PayslipDetailScreen(payslip: _payslip)),
      );

      expect(find.text('June 2026'), findsOneWidget);
      expect(find.text('RM 5,450.00'), findsWidgets);
      expect(find.text('Basic salary'), findsOneWidget);
      expect(find.text('RM 6,500.00'), findsOneWidget);
      expect(find.text('EPF'), findsOneWidget);
      expect(find.text('− RM 1,050.00'), findsOneWidget);
      expect(find.text('Payslip PS-2026-06'), findsOneWidget);

      await tester.tap(find.text('Download PDF'));
      await tester.pump();

      expect(
        find.text("Downloading isn't available in this preview"),
        findsOneWidget,
      );
    },
  );
}
