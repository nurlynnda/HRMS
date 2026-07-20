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
import '../models/approver.dart';
import '../models/leave_request.dart';
import '../models/team_absence.dart';

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

  static const upcomingHolidayLabel = 'Independence Day · Fri, Jul 4';

  static const teamCalendarYear = 2026;
  static const teamCalendarMonth = 6;
  static const teamCalendarTodayDay = 20;
  static const teamCalendarDayColors = <int, List<Color>>{
    20: [AppColors.warning],
    23: [AppColors.primary],
    24: [AppColors.primary],
    25: [AppColors.primary],
    26: [AppColors.primary],
    27: [AppColors.primary],
  };

  static const teamAbsences = [
    TeamAbsence(
      name: 'Marcus Lee',
      role: 'Design Lead',
      dateRangeLabel: 'Jun 23 – 25',
      leaveType: 'Annual',
      badgeColor: AppColors.primary,
      badgeBg: AppColors.primaryTint,
    ),
    TeamAbsence(
      name: 'Priya Nair',
      role: 'UX Researcher',
      dateRangeLabel: 'Today',
      leaveType: 'Sick',
      badgeColor: AppColors.warning,
      badgeBg: AppColors.warningTint,
    ),
    TeamAbsence(
      name: 'Tom Alvarez',
      role: 'Visual Designer',
      dateRangeLabel: 'Jun 26 – 27',
      leaveType: 'Annual',
      badgeColor: AppColors.primary,
      badgeBg: AppColors.primaryTint,
    ),
  ];

  static const _approversAllApproved = [
    Approver(
      initials: 'ML',
      tint: Color(0xFFDBEAFE),
      color: Color(0xFF1D4ED8),
      name: 'Marcus Lee',
      role: 'Design Lead · 1st approver',
      status: 'Approved',
      badgeBg: AppColors.primaryTint,
      badgeColor: AppColors.primary,
      when: 'Jun 1, 9:12 AM',
    ),
    Approver(
      initials: 'RT',
      tint: Color(0xFFF1E9FF),
      color: Color(0xFF6D28D9),
      name: 'Rachel Tan',
      role: 'Dept. Manager · 2nd approver',
      status: 'Approved',
      badgeBg: AppColors.primaryTint,
      badgeColor: AppColors.primary,
      when: 'Jun 1, 2:40 PM',
    ),
    Approver(
      initials: 'JW',
      tint: Color(0xFFFEE9D6),
      color: Color(0xFFC2410C),
      name: 'James Wong',
      role: 'HR Manager · final approver',
      status: 'Approved',
      badgeBg: AppColors.primaryTint,
      badgeColor: AppColors.primary,
      when: 'Jun 2, 10:05 AM',
    ),
  ];

  static const _approversPending = [
    Approver(
      initials: 'ML',
      tint: Color(0xFFDBEAFE),
      color: Color(0xFF1D4ED8),
      name: 'Marcus Lee',
      role: 'Design Lead · 1st approver',
      status: 'Pending',
      badgeBg: AppColors.warningTint,
      badgeColor: AppColors.warning,
      when: '—',
    ),
    Approver(
      initials: 'RT',
      tint: Color(0xFFF1E9FF),
      color: Color(0xFF6D28D9),
      name: 'Rachel Tan',
      role: 'Dept. Manager · 2nd approver',
      status: 'Waiting',
      badgeBg: Color(0xFFF1F5F9),
      badgeColor: AppColors.textSecondary,
      when: '—',
    ),
    Approver(
      initials: 'JW',
      tint: Color(0xFFFEE9D6),
      color: Color(0xFFC2410C),
      name: 'James Wong',
      role: 'HR Manager · final approver',
      status: 'Waiting',
      badgeBg: Color(0xFFF1F5F9),
      badgeColor: AppColors.textSecondary,
      when: '—',
    ),
  ];

  static const _approversRejected = [
    Approver(
      initials: 'ML',
      tint: Color(0xFFDBEAFE),
      color: Color(0xFF1D4ED8),
      name: 'Marcus Lee',
      role: 'Design Lead · 1st approver',
      status: 'Rejected',
      badgeBg: AppColors.dangerTint,
      badgeColor: AppColors.danger,
      when: 'May 10, 4:22 PM',
    ),
    Approver(
      initials: 'RT',
      tint: Color(0xFFF1E9FF),
      color: Color(0xFF6D28D9),
      name: 'Rachel Tan',
      role: 'Dept. Manager · 2nd approver',
      status: 'Waiting',
      badgeBg: Color(0xFFF1F5F9),
      badgeColor: AppColors.textSecondary,
      when: '—',
    ),
    Approver(
      initials: 'JW',
      tint: Color(0xFFFEE9D6),
      color: Color(0xFFC2410C),
      name: 'James Wong',
      role: 'HR Manager · final approver',
      status: 'Waiting',
      badgeBg: Color(0xFFF1F5F9),
      badgeColor: AppColors.textSecondary,
      when: '—',
    ),
  ];

  static const myLeaveRequests = [
    LeaveRequest(
      type: 'Annual Leave',
      dateRangeLabel: 'Jul 14 – 16 · 3 days',
      status: 'Pending',
      statusColor: AppColors.warning,
      statusBg: AppColors.warningTint,
      reason: 'Family trip planned before the new project kicks off.',
      approvers: _approversPending,
    ),
    LeaveRequest(
      type: 'Medical Leave',
      dateRangeLabel: 'Jun 3 · 1 day',
      status: 'Approved',
      statusColor: AppColors.primary,
      statusBg: AppColors.primaryTint,
      reason: 'Doctor-advised rest for flu recovery.',
      approvers: _approversAllApproved,
    ),
    LeaveRequest(
      type: 'Annual Leave',
      dateRangeLabel: 'May 2 – 3 · 2 days',
      status: 'Approved',
      statusColor: AppColors.primary,
      statusBg: AppColors.primaryTint,
      reason: 'Short break to attend a family event.',
      approvers: _approversAllApproved,
    ),
    LeaveRequest(
      type: 'Personal Leave',
      dateRangeLabel: 'Apr 18 · 1 day',
      status: 'Rejected',
      statusColor: AppColors.danger,
      statusBg: AppColors.dangerTint,
      reason: 'Requested during the product launch freeze window.',
      approvers: _approversRejected,
    ),
    LeaveRequest(
      type: 'Annual Leave',
      dateRangeLabel: 'Mar 5 – 6 · 2 days',
      status: 'Approved',
      statusColor: AppColors.primary,
      statusBg: AppColors.primaryTint,
      reason: 'Personal travel.',
      approvers: _approversAllApproved,
    ),
    LeaveRequest(
      type: 'Medical Leave',
      dateRangeLabel: 'Feb 14 · 1 day',
      status: 'Approved',
      statusColor: AppColors.primary,
      statusBg: AppColors.primaryTint,
      reason: 'Medical appointment.',
      approvers: _approversAllApproved,
    ),
  ];
}
