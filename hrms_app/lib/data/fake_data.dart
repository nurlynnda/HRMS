import 'package:flutter/material.dart';
import '../models/announcement.dart';
import '../models/clock_status.dart';
import '../models/day_hours.dart';
import '../models/employee.dart';
import '../models/leave_balance.dart';
import '../theme/app_theme.dart';

/// Hardcoded sample data matching the HRMS design mockup, standing in for
/// a real backend until one exists.
class FakeData {
  static const employee = Employee(name: 'Sarah Chen', initials: 'SC');

  static const clockStatus = ClockStatus(
    clockedIn: true,
    since: '09:02 AM',
    location: 'HQ Office',
    hoursWorkedToday: '6h 12m',
  );

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
}
