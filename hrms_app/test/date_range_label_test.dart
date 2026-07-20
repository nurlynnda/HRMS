import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_app/utils/date_range_label.dart';

void main() {
  test('same day returns a single-day label', () {
    expect(formatDateRangeLabel(DateTime(2026, 7, 14), DateTime(2026, 7, 14)), 'Jul 14 · 1 day');
  });

  test('same-month range returns a dash range with day count', () {
    expect(formatDateRangeLabel(DateTime(2026, 7, 14), DateTime(2026, 7, 16)), 'Jul 14 – 16 · 3 days');
  });

  test('cross-month range names both months', () {
    expect(formatDateRangeLabel(DateTime(2026, 7, 30), DateTime(2026, 8, 2)), 'Jul 30 – Aug 2 · 4 days');
  });

  test('monthAbbr has 12 three-letter entries starting with Jan', () {
    expect(monthAbbr.length, 12);
    expect(monthAbbr.first, 'Jan');
    expect(monthAbbr[6], 'Jul');
  });
}
