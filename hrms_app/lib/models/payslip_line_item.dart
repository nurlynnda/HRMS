/// One line of a payslip's earnings or deductions breakdown, e.g.
/// "Basic salary" / 6000.00. The same shape is reused for both earnings
/// and deductions — whether a line is added or subtracted is a
/// UI-rendering decision (deductions render with a leading "−" and red
/// text), not something this model encodes.
class PayslipLineItem {
  final String label;
  final double amount;

  const PayslipLineItem({required this.label, required this.amount});
}
