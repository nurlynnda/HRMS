import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_app/models/attendance_history_stats.dart';
import 'package:hrms_app/models/attendance_record.dart';
import 'package:hrms_app/screens/attendance/attendance_history_screen.dart';
import 'package:hrms_app/theme/app_theme.dart';

const _records = [
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
    day: 17,
    dayOfWeek: 'TUE',
    dateLabel: 'Tuesday, Jun 17',
    timesLabel: '09:12 — 17:40',
    note: '',
    hoursLabel: '8.5h',
    status: 'Late',
    statusColor: AppColors.warning,
  ),
];

const _stats = AttendanceHistoryStats(present: 19, late: 2, leave: 1, avgLabel: '7.8h');

void main() {
  testWidgets('shows all records by default, filters when a chip is tapped', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AttendanceHistoryScreen(records: _records, stats: _stats),
      ),
    );

    expect(find.text('Thursday, Jun 19'), findsOneWidget);
    expect(find.text('Tuesday, Jun 17'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Late'));
    await tester.pumpAndSettle();

    expect(find.text('Thursday, Jun 19'), findsNothing);
    expect(find.text('Tuesday, Jun 17'), findsOneWidget);
  });
}
