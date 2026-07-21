/// Formats a Ringgit amount with thousands separators and exactly two
/// decimal places, e.g. 1730.0 -> "1,730.00". Callers prepend "RM "
/// themselves — this returns the number only.
String formatCurrency(double amount) {
  final fixed = amount.toStringAsFixed(2);
  final dotIndex = fixed.indexOf('.');
  final whole = fixed.substring(0, dotIndex);
  final decimals = fixed.substring(dotIndex);
  final isNegative = whole.startsWith('-');
  final digits = isNegative ? whole.substring(1) : whole;

  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }

  return '${isNegative ? '-' : ''}$buffer$decimals';
}
