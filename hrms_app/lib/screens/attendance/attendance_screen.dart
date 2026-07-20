import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/face_check_in_overlay.dart';
import '../../widgets/recent_attendance_list.dart';
import '../../widgets/today_attendance_card.dart';
import '../../widgets/weekly_attendance_stats_card.dart';
import 'attendance_history_screen.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  Future<void> _handleClockButton(BuildContext context, AppState appState) async {
    final clockingIn = !appState.todayAttendance.clockedIn;
    final verified = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => FaceCheckInOverlay(clockingIn: clockingIn),
        fullscreenDialog: true,
      ),
    );
    if (verified == true) {
      if (clockingIn) {
        appState.clockIn();
      } else {
        appState.clockOut();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Attendance',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Jun 2026',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TodayAttendanceCard(
            attendance: appState.todayAttendance,
            onClockButtonPressed: () => _handleClockButton(context, appState),
          ),
          const SizedBox(height: 16),
          WeeklyAttendanceStatsCard(
            days: appState.weeklyHours,
            stats: appState.attendanceWeekStats,
          ),
          const SizedBox(height: 16),
          RecentAttendanceList(
            records: appState.attendanceRecords,
            onViewAll: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AttendanceHistoryScreen(
                  records: appState.attendanceRecords,
                  stats: appState.attendanceHistoryStats,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
