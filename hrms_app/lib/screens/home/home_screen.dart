import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../claims/claims_screen.dart';
import '../../widgets/announcements_list.dart';
import '../../widgets/clock_status_card.dart';
import '../../widgets/home_header.dart';
import '../../widgets/leave_balance_card.dart';
import '../../widgets/quick_actions_row.dart';
import '../../widgets/weekly_hours_chart.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeHeader(employee: appState.employee),
          const SizedBox(height: 20),
          ClockStatusCard(status: appState.clockStatus),
          const SizedBox(height: 18),
          QuickActionsRow(
            onClaimsTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ClaimsScreen()),
            ),
          ),
          const SizedBox(height: 22),
          WeeklyHoursChart(
            days: appState.weeklyHours,
            totalLabel: appState.weeklyTotalHoursLabel,
            changeLabel: appState.weeklyChangeLabel,
          ),
          const SizedBox(height: 14),
          LeaveBalanceCard(balances: appState.leaveBalances),
          const SizedBox(height: 16),
          AnnouncementsList(announcements: appState.announcements),
        ],
      ),
    );
  }
}
