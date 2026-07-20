import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_app/models/approver.dart';
import 'package:hrms_app/models/leave_request.dart';
import 'package:hrms_app/screens/leave/leave_history_screen.dart';
import 'package:hrms_app/theme/app_theme.dart';

const _requests = [
  LeaveRequest(
    type: 'Annual Leave',
    dateRangeLabel: 'Jul 14 – 16 · 3 days',
    status: 'Pending',
    statusColor: AppColors.warning,
    statusBg: AppColors.warningTint,
    reason: 'Family trip.',
    approvers: <Approver>[],
  ),
  LeaveRequest(
    type: 'Medical Leave',
    dateRangeLabel: 'Jun 3 · 1 day',
    status: 'Approved',
    statusColor: AppColors.primary,
    statusBg: AppColors.primaryTint,
    reason: 'Flu recovery.',
    approvers: <Approver>[],
  ),
];

void main() {
  testWidgets('shows all requests by default, filters when a chip is tapped', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LeaveHistoryScreen(requests: _requests)),
    );

    expect(find.text('Annual Leave'), findsOneWidget);
    expect(find.text('Medical Leave'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Approved'));
    await tester.pumpAndSettle();

    expect(find.text('Annual Leave'), findsNothing);
    expect(find.text('Medical Leave'), findsOneWidget);
  });

  testWidgets('tapping a request opens its detail page', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LeaveHistoryScreen(requests: _requests)),
    );

    await tester.tap(find.text('Annual Leave'));
    await tester.pumpAndSettle();

    expect(find.text('Request details'), findsOneWidget);
  });
}
