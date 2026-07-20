class AttendanceHistoryStats {
  final int present;
  final int late;
  final int leave;
  final String avgLabel;

  const AttendanceHistoryStats({
    required this.present,
    required this.late,
    required this.leave,
    required this.avgLabel,
  });
}
