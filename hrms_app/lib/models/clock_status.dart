class ClockStatus {
  final bool clockedIn;
  final String since;
  final String location;
  final String hoursWorkedToday;

  const ClockStatus({
    required this.clockedIn,
    required this.since,
    required this.location,
    required this.hoursWorkedToday,
  });
}
