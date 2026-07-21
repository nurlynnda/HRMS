import 'payslip_line_item.dart';

class Payslip {
  final String id;
  final String month;
  final String period;
  final String payDate;
  final String status;
  final List<PayslipLineItem> earnings;
  final List<PayslipLineItem> deductions;

  const Payslip({
    required this.id,
    required this.month,
    required this.period,
    required this.payDate,
    required this.status,
    required this.earnings,
    required this.deductions,
  });

  double get grossPay => earnings.fold(0.0, (sum, e) => sum + e.amount);
  double get totalDeductions => deductions.fold(0.0, (sum, d) => sum + d.amount);
  double get netPay => grossPay - totalDeductions;
}
