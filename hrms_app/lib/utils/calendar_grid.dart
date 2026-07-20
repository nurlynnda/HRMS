const List<String> monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Builds a Monday-first calendar grid for [year]/[month]. Returns a flat
/// list of day numbers (1..daysInMonth) padded with `null` before the 1st
/// and after the last day, so the list length is always a multiple of 7
/// (ready to feed straight into a 7-column grid).
List<int?> buildMonthGrid(int year, int month) {
  final firstOfMonth = DateTime(year, month, 1);
  final daysInMonth = DateTime(year, month + 1, 0).day;
  final leadingBlanks = firstOfMonth.weekday - DateTime.monday;

  final cells = <int?>[
    ...List<int?>.filled(leadingBlanks, null),
    ...List<int?>.generate(daysInMonth, (i) => i + 1),
  ];

  final trailingBlanks = (7 - (cells.length % 7)) % 7;
  cells.addAll(List<int?>.filled(trailingBlanks, null));
  return cells;
}
