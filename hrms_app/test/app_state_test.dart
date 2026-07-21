import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_app/state/app_state.dart';

void main() {
  test('clockOut() sets clockedIn to false and records a clock-out time', () {
    final appState = AppState();
    expect(appState.todayAttendance.clockedIn, isTrue);

    appState.clockOut();

    expect(appState.todayAttendance.clockedIn, isFalse);
    expect(appState.todayAttendance.clockOutTime, isNotNull);
    expect(appState.clockStatus.clockedIn, isFalse);
  });

  test('clockIn() sets clockedIn to true and clears the clock-out time', () {
    final appState = AppState();
    appState.clockOut();

    appState.clockIn();

    expect(appState.todayAttendance.clockedIn, isTrue);
    expect(appState.todayAttendance.clockOutTime, isNull);
    expect(appState.clockStatus.clockedIn, isTrue);
  });

  test('notifyListeners fires when clocking in or out', () {
    final appState = AppState();
    var notified = false;
    appState.addListener(() => notified = true);

    appState.clockOut();

    expect(notified, isTrue);
  });

  test('submitLeaveRequest() prepends a new Pending request and notifies', () {
    final appState = AppState();
    final before = appState.myLeaveRequests.length;
    var notified = false;
    appState.addListener(() => notified = true);

    appState.submitLeaveRequest(
      type: 'Personal Leave',
      start: DateTime(2026, 8, 3),
      end: DateTime(2026, 8, 4),
      reason: 'Moving apartment',
    );

    expect(appState.myLeaveRequests.length, before + 1);
    expect(appState.myLeaveRequests.first.type, 'Personal Leave');
    expect(appState.myLeaveRequests.first.status, 'Pending');
    expect(appState.myLeaveRequests.first.dateRangeLabel, 'Aug 3 – 4 · 2 days');
    expect(appState.myLeaveRequests.first.reason, 'Moving apartment');
    expect(appState.myLeaveRequests.first.approvers, isNotEmpty);
    expect(notified, isTrue);
  });

  test('pendingApprovalChain exposes a non-empty approver list', () {
    final appState = AppState();
    expect(appState.pendingApprovalChain, isNotEmpty);
  });

  test('personalInfo exposes the employee\'s work email', () {
    final appState = AppState();
    expect(appState.personalInfo.workEmail, 'sarah.chen@company.com');
  });

  test('submitClaim() prepends a new Pending claim and notifies', () {
    final appState = AppState();
    final before = appState.claims.length;
    var notified = false;
    appState.addListener(() => notified = true);

    appState.submitClaim(category: 'Outpatient', amount: 150.0, description: 'Blood test');

    expect(appState.claims.length, before + 1);
    expect(appState.claims.first.category, 'Outpatient');
    expect(appState.claims.first.status, 'Pending');
    expect(appState.claims.first.amount, 150.0);
    expect(appState.claims.first.description, 'Blood test');
    expect(appState.claims.first.approvers, isNotEmpty);
    expect(notified, isTrue);
  });

  test('pendingClaimsTotal and pendingClaimsCount reflect only Pending claims', () {
    final appState = AppState();
    final expectedTotal = appState.claims
        .where((c) => c.status == 'Pending')
        .fold(0.0, (sum, c) => sum + c.amount);
    final expectedCount = appState.claims.where((c) => c.status == 'Pending').length;

    expect(appState.pendingClaimsTotal, expectedTotal);
    expect(appState.pendingClaimsCount, expectedCount);
  });

  test('approvedClaimsYtdTotal reflects only Approved claims', () {
    final appState = AppState();
    final expectedTotal = appState.claims
        .where((c) => c.status == 'Approved')
        .fold(0.0, (sum, c) => sum + c.amount);

    expect(appState.approvedClaimsYtdTotal, expectedTotal);
  });

  test('claimEntitlements and claimProjects expose non-empty lists', () {
    final appState = AppState();
    expect(appState.claimEntitlements, isNotEmpty);
    expect(appState.claimProjects, isNotEmpty);
  });
}
