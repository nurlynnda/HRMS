import 'package:flutter/material.dart';
import '../data/fake_data.dart';
import '../models/announcement.dart';
import '../models/approver.dart';
import '../models/attendance_history_stats.dart';
import '../models/attendance_record.dart';
import '../models/attendance_week_stats.dart';
import '../models/claim.dart';
import '../models/claim_entitlement.dart';
import '../models/clock_status.dart';
import '../models/day_hours.dart';
import '../models/employee.dart';
import '../models/leave_balance.dart';
import '../models/personal_info.dart';
import '../models/today_attendance.dart';
import '../models/team_absence.dart';
import '../models/leave_request.dart';
import '../theme/app_theme.dart';
import '../utils/date_range_label.dart';

/// Shared app state. Exposes hardcoded fake data plus mutating methods
/// (clockIn(), clockOut(), submitLeaveRequest()) that all follow the
/// same pattern: mutate internal state, call notifyListeners().
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

  String get upcomingHolidayLabel => FakeData.upcomingHolidayLabel;
  int get teamCalendarYear => FakeData.teamCalendarYear;
  int get teamCalendarMonth => FakeData.teamCalendarMonth;
  int get teamCalendarTodayDay => FakeData.teamCalendarTodayDay;
  Map<int, List<Color>> get teamCalendarDayColors => FakeData.teamCalendarDayColors;
  List<TeamAbsence> get teamAbsences => FakeData.teamAbsences;
  List<LeaveRequest> _myLeaveRequests = List.of(FakeData.myLeaveRequests);
  List<LeaveRequest> get myLeaveRequests => _myLeaveRequests;
  List<Approver> get pendingApprovalChain => FakeData.pendingApprovalChain;
  PersonalInfo get personalInfo => FakeData.personalInfo;

  List<Claim> _claims = List.of(FakeData.claims);
  List<Claim> get claims => _claims;
  List<ClaimEntitlement> get claimEntitlements => FakeData.claimEntitlements;
  List<Approver> get pendingClaimApprovers => FakeData.pendingClaimApprovers;
  List<String> get claimProjects => FakeData.claimProjects;
  double get approvedClaimsYtdCap => FakeData.approvedYtdCap;

  double get pendingClaimsTotal =>
      _claims.where((c) => c.status == 'Pending').fold(0.0, (sum, c) => sum + c.amount);
  int get pendingClaimsCount => _claims.where((c) => c.status == 'Pending').length;
  double get approvedClaimsYtdTotal =>
      _claims.where((c) => c.status == 'Approved').fold(0.0, (sum, c) => sum + c.amount);

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

  /// Adds a new Pending leave request to the front of [myLeaveRequests].
  /// Mirrors clockIn()/clockOut(): mutate internal state, notify.
  void submitLeaveRequest({
    required String type,
    required DateTime start,
    required DateTime end,
    required String reason,
  }) {
    final newRequest = LeaveRequest(
      type: type,
      dateRangeLabel: formatDateRangeLabel(start, end),
      status: 'Pending',
      statusColor: AppColors.warning,
      statusBg: AppColors.warningTint,
      reason: reason,
      approvers: FakeData.pendingApprovalChain,
    );
    _myLeaveRequests = [newRequest, ..._myLeaveRequests];
    notifyListeners();
  }

  /// Adds a new Pending claim to the front of [claims]. Mirrors
  /// submitLeaveRequest(): mutate internal state, notify.
  void submitClaim({
    required String category,
    required double amount,
    required String description,
  }) {
    final now = DateTime.now();
    final newClaim = Claim(
      id: 'CLM-${1000 + _claims.length}',
      category: category,
      dateLabel: '${monthAbbr[now.month - 1]} ${now.day}',
      amount: amount,
      status: 'Pending',
      statusColor: AppColors.warning,
      statusBg: AppColors.warningTint,
      description: description,
      approvers: FakeData.pendingClaimApprovers,
    );
    _claims = [newClaim, ..._claims];
    notifyListeners();
  }
}
