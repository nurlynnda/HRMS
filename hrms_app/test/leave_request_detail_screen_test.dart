import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_app/models/approver.dart';
import 'package:hrms_app/models/leave_request.dart';
import 'package:hrms_app/screens/leave/leave_request_detail_screen.dart';
import 'package:hrms_app/theme/app_theme.dart';

void main() {
  testWidgets('shows request info, waiting banner, and approval progress', (tester) async {
    const request = LeaveRequest(
      type: 'Annual Leave',
      dateRangeLabel: 'Jul 14 – 16 · 3 days',
      status: 'Pending',
      statusColor: AppColors.warning,
      statusBg: AppColors.warningTint,
      reason: 'Family trip.',
      approvers: [
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
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(home: LeaveRequestDetailScreen(request: request)),
    );

    expect(find.text('Annual Leave'), findsOneWidget);
    expect(find.text('Waiting on Marcus Lee to approve'), findsOneWidget);
    expect(find.text('Family trip.'), findsOneWidget);
    expect(find.text('Marcus Lee'), findsWidgets);
  });
}
