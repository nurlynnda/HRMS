import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_app/utils/currency.dart';

void main() {
  test('formats a small amount with two decimals', () {
    expect(formatCurrency(420), '420.00');
  });

  test('adds a thousands separator', () {
    expect(formatCurrency(1730), '1,730.00');
  });

  test('adds multiple thousands separators for large amounts', () {
    expect(formatCurrency(1234567.89), '1,234,567.89');
  });

  test('formats zero', () {
    expect(formatCurrency(0), '0.00');
  });

  test('rounds to two decimal places', () {
    expect(formatCurrency(99.999), '100.00');
  });
}
