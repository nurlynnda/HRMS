const List<String> monthAbbr = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Formats a leave request's date span, e.g. "Jul 14 · 1 day" for a
/// single day or "Jul 14 – 16 · 3 days" for a range within one month.
String formatDateRangeLabel(DateTime start, DateTime end) {
  final days = end.difference(start).inDays + 1;
  final dayWord = days == 1 ? 'day' : 'days';

  if (start.year == end.year && start.month == end.month && start.day == end.day) {
    return '${monthAbbr[start.month - 1]} ${start.day} · $days $dayWord';
  }
  if (start.year == end.year && start.month == end.month) {
    return '${monthAbbr[start.month - 1]} ${start.day} – ${end.day} · $days $dayWord';
  }
  return '${monthAbbr[start.month - 1]} ${start.day} – ${monthAbbr[end.month - 1]} ${end.day} · $days $dayWord';
}
