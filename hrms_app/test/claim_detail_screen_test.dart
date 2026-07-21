import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_app/models/approver.dart';
import 'package:hrms_app/models/claim.dart';
import 'package:hrms_app/screens/claims/claim_detail_screen.dart';
import 'package:hrms_app/theme/app_theme.dart';

const _claim = Claim(
  id: 'CLM-0468',
  category: 'Outpatient',
  dateLabel: 'Jun 28',
  amount: 220.0,
  status: 'Pending',
  statusColor: AppColors.warning,
  statusBg: AppColors.warningTint,
  description: 'GP visit for flu symptoms.',
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

void main() {
  testWidgets('shows claim amount, category, status, description, and approvers', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ClaimDetailScreen(claim: _claim)),
    );

    expect(find.text('RM 220.00'), findsOneWidget);
    expect(find.text('Outpatient · CLM-0468'), findsOneWidget);
    expect(find.text('Pending'), findsWidgets);
    expect(find.text('GP visit for flu symptoms.'), findsOneWidget);
    expect(find.text('Marcus Lee'), findsOneWidget);
  });
}
