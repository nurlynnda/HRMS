import 'package:flutter/foundation.dart';
import '../data/fake_data.dart';
import '../models/announcement.dart';
import '../models/attendance_history_stats.dart';
import '../models/attendance_record.dart';
import '../models/attendance_week_stats.dart';
import '../models/clock_status.dart';
import '../models/day_hours.dart';
import '../models/employee.dart';
import '../models/leave_balance.dart';
import '../models/today_attendance.dart';

/// Shared app state. Currently exposes hardcoded fake data plus the
/// first two mutating methods: clockIn() and clockOut(). Later phases
/// will add more methods here (submitLeaveRequest(), etc.) following
/// the same pattern: mutate internal state, call notifyListeners().
class AppState extends ChangeNotifier {
  Employee get employee => FakeData.employee;

  TodayAttendance _todayAttendance = FakeData.todayAttendance;
  TodayAttendance get todayAttendance => _todayAttendance;

  /// Home tab's clock-status card reads this. Computed from
  /// [todayAttendance] so clocking in/out on the Attendance tab is
  /// reflected here too.
  ClockStatus get clockStatus => ClockStatus(
        clockedIn: _todayAttendance.clockedIn,
        since: _todayAttendance.clockInTime ?? '—',
        location: FakeData.officeLocation,
        hoursWorkedToday: _todayAttendance.workedLabel,
      );

  List<DayHours> get weeklyHours => FakeData.weeklyHours;
  String get weeklyTotalHoursLabel => FakeData.weeklyTotalHoursLabel;
  String get weeklyChangeLabel => FakeData.weeklyChangeLabel;
  List<LeaveBalance> get leaveBalances => FakeData.leaveBalances;
  List<Announcement> get announcements => FakeData.announcements;

  AttendanceWeekStats get attendanceWeekStats => FakeData.weekStats;
  List<AttendanceRecord> get attendanceRecords => FakeData.attendanceRecords;
  AttendanceHistoryStats get attendanceHistoryStats => FakeData.historyStats;

  void clockIn() {
    _todayAttendance = TodayAttendance(
      clockedIn: true,
      clockInTime: '09:02 AM',
      clockOutTime: null,
      workedLabel: _todayAttendance.workedLabel,
      targetLabel: _todayAttendance.targetLabel,
      progress: _todayAttendance.progress,
    );
    notifyListeners();
  }

  void clockOut() {
    _todayAttendance = TodayAttendance(
      clockedIn: false,
      clockInTime: _todayAttendance.clockInTime,
      clockOutTime: '05:15 PM',
      workedLabel: _todayAttendance.workedLabel,
      targetLabel: _todayAttendance.targetLabel,
      progress: _todayAttendance.progress,
    );
    notifyListeners();
  }
}
