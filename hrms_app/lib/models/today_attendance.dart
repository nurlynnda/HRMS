/// Today's clock-in/out state — the source of truth the Attendance tab's
/// ring card and the Home tab's clock-status card both read from.
class TodayAttendance {
  final bool clockedIn;
  final String? clockInTime;
  final String? clockOutTime;
  final String workedLabel;
  final String targetLabel;
  final double progress;

  const TodayAttendance({
    required this.clockedIn,
    this.clockInTime,
    this.clockOutTime,
    required this.workedLabel,
    required this.targetLabel,
    required this.progress,
  });
}
