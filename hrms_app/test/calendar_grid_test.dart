import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_app/utils/calendar_grid.dart';

void main() {
  test('buildMonthGrid pads to a multiple of 7 and contains every day exactly once', () {
    final cells = buildMonthGrid(2026, 6);
    final daysInMonth = DateTime(2026, 7, 0).day;

    expect(cells.length % 7, 0);
    final nonNull = cells.whereType<int>().toList();
    expect(nonNull.length, daysInMonth);
    expect(nonNull.first, 1);
    expect(nonNull.last, daysInMonth);
    expect(nonNull.toSet().length, daysInMonth);
  });

  test('buildMonthGrid works for a different year/month too', () {
    final cells = buildMonthGrid(2027, 2);
    final daysInMonth = DateTime(2027, 3, 0).day;

    expect(cells.length % 7, 0);
    final nonNull = cells.whereType<int>().toList();
    expect(nonNull.length, daysInMonth);
    expect(nonNull.first, 1);
    expect(nonNull.last, daysInMonth);
  });

  test('monthNames has 12 entries starting with January', () {
    expect(monthNames.length, 12);
    expect(monthNames.first, 'January');
    expect(monthNames[5], 'June');
  });
}
