import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/leave_request.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/my_requests_list.dart';
import '../../widgets/team_calendar_card.dart';
import '../../widgets/whos_away_list.dart';
import 'leave_history_screen.dart';
import 'leave_request_detail_screen.dart';

class LeaveScreen extends StatelessWidget {
  const LeaveScreen({super.key});

  void _openRequestDetail(BuildContext context, LeaveRequest request) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LeaveRequestDetailScreen(request: request)),
    );
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
                'Leave',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => LeaveHistoryScreen(requests: appState.myLeaveRequests),
                        ),
                      ),
                      icon: const Icon(Icons.history, size: 20, color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 16, color: Colors.white),
                        SizedBox(width: 6),
                        Text('Request', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.primaryTint, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.event_note_outlined, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Upcoming holiday',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      Text(
                        appState.upcomingHolidayLabel,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text('Team calendar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          TeamCalendarCard(
            year: appState.teamCalendarYear,
            month: appState.teamCalendarMonth,
            todayDay: appState.teamCalendarTodayDay,
            dayColors: appState.teamCalendarDayColors,
          ),
          const SizedBox(height: 22),
          WhosAwayList(absences: appState.teamAbsences),
          const SizedBox(height: 22),
          MyRequestsList(
            requests: appState.myLeaveRequests,
            onViewAll: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LeaveHistoryScreen(requests: appState.myLeaveRequests),
              ),
            ),
            onRequestTap: (r) => _openRequestDetail(context, r),
          ),
        ],
      ),
    );
  }
}
