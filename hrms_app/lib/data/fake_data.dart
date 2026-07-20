import 'package:flutter/material.dart';
import '../models/announcement.dart';
import '../models/attendance_history_stats.dart';
import '../models/attendance_record.dart';
import '../models/attendance_week_stats.dart';
import '../models/day_hours.dart';
import '../models/employee.dart';
import '../models/leave_balance.dart';
import '../models/today_attendance.dart';
import '../theme/app_theme.dart';

/// Hardcoded sample data matching the HRMS design mockup, standing in for
/// a real backend until one exists.
class FakeData {
  static const employee = Employee(name: 'Sarah Chen', initials: 'SC');

  static const weeklyHours = [
    DayHours(label: 'Mon', hours: 7.9),
    DayHours(label: 'Tue', hours: 7.7),
    DayHours(label: 'Wed', hours: 7.2),
    DayHours(label: 'Thu', hours: 8.1),
    DayHours(label: 'Fri', hours: 5.9, highlighted: true),
  ];

  static const weeklyTotalHoursLabel = '38.3';
  static const weeklyChangeLabel = '+2.1h vs last wk';

  static const leaveBalances = [
    LeaveBalance(type: 'Annual', used: 12, total: 18, color: AppColors.primary),
    LeaveBalance(type: 'Sick', used: 5, total: 10, color: AppColors.primary),
    LeaveBalance(type: 'Personal', used: 2, total: 5, color: AppColors.warning),
  ];

  static const announcements = [
    Announcement(
      icon: Icons.notifications_none,
      title: 'Q3 Town Hall — all hands',
      subtitle: 'Jun 28 · 3:00 PM · Auditorium',
    ),
    Announcement(
      icon: Icons.check_circle_outline,
      title: 'New dental & vision benefits',
      subtitle: 'Now live · enrol by Jul 15',
    ),
  ];

  static const officeLocation = 'HQ Office';

  static const todayAttendance = TodayAttendance(
    clockedIn: true,
    clockInTime: '09:02 AM',
    clockOutTime: null,
    workedLabel: '6:12',
    targetLabel: '8h 00m',
    progress: 6.2 / 8.0,
  );

  static const weekStats = AttendanceWeekStats(
    onTime: 5,
    late: 0,
    avgPerDayLabel: '7.7h',
  );

  static const attendanceRecords = [
    AttendanceRecord(
      day: 19,
      dayOfWeek: 'THU',
      dateLabel: 'Thursday, Jun 19',
      timesLabel: '09:00 — 17:24',
      note: '',
      hoursLabel: '8.4h',
      status: 'On time',
      statusColor: AppColors.primary,
    ),
    AttendanceRecord(
      day: 18,
      dayOfWeek: 'WED',
      dateLabel: 'Wednesday, Jun 18',
      timesLabel: '09:05 — 16:35',
      note: '',
      hoursLabel: '7.5h',
      status: 'On time',
      statusColor: AppColors.primary,
    ),
    AttendanceRecord(
      day: 17,
      dayOfWeek: 'TUE',
      dateLabel: 'Tuesday, Jun 17',
      timesLabel: '09:12 — 17:40',
      note: '',
      hoursLabel: '8.5h',
      status: 'Late',
      statusColor: AppColors.warning,
    ),
    AttendanceRecord(
      day: 16,
      dayOfWeek: 'MON',
      dateLabel: 'Monday, Jun 16',
      timesLabel: '09:00 — 17:10',
      note: '',
      hoursLabel: '8.2h',
      status: 'On time',
      statusColor: AppColors.primary,
    ),
    AttendanceRecord(
      day: 13,
      dayOfWeek: 'FRI',
      dateLabel: 'Friday, Jun 13',
      timesLabel: '— : —',
      note: 'Approved leave',
      hoursLabel: '—',
      status: 'Leave',
      statusColor: AppColors.info,
    ),
    AttendanceRecord(
      day: 12,
      dayOfWeek: 'THU',
      dateLabel: 'Thursday, Jun 12',
      timesLabel: '09:03 — 17:20',
      note: '',
      hoursLabel: '8.3h',
      status: 'On time',
      statusColor: AppColors.primary,
    ),
    AttendanceRecord(
      day: 11,
      dayOfWeek: 'WED',
      dateLabel: 'Wednesday, Jun 11',
      timesLabel: '09:20 — 17:15',
      note: '',
      hoursLabel: '7.9h',
      status: 'Late',
      statusColor: AppColors.warning,
    ),
    AttendanceRecord(
      day: 10,
      dayOfWeek: 'TUE',
      dateLabel: 'Tuesday, Jun 10',
      timesLabel: '09:00 — 17:30',
      note: '',
      hoursLabel: '8.5h',
      status: 'On time',
      statusColor: AppColors.primary,
    ),
  ];

  static const historyStats = AttendanceHistoryStats(
    present: 19,
    late: 2,
    leave: 1,
    avgLabel: '7.8h',
  );
}
