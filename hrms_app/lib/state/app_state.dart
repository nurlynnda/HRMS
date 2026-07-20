import 'package:flutter/foundation.dart';
import '../data/fake_data.dart';
import '../models/announcement.dart';
import '../models/clock_status.dart';
import '../models/day_hours.dart';
import '../models/employee.dart';
import '../models/leave_balance.dart';

/// Shared app state. Currently just exposes the hardcoded fake data;
/// later phases will add methods here (clockIn(), submitLeaveRequest(),
/// etc.) that mutate state and call notifyListeners().
class AppState extends ChangeNotifier {
  Employee get employee => FakeData.employee;
  ClockStatus get clockStatus => FakeData.clockStatus;
  List<DayHours> get weeklyHours => FakeData.weeklyHours;
  String get weeklyTotalHoursLabel => FakeData.weeklyTotalHoursLabel;
  String get weeklyChangeLabel => FakeData.weeklyChangeLabel;
  List<LeaveBalance> get leaveBalances => FakeData.leaveBalances;
  List<Announcement> get announcements => FakeData.announcements;
}
