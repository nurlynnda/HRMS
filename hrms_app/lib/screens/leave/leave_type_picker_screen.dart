import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/leave_balance.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import 'leave_request_form_screen.dart';

class LeaveTypePickerScreen extends StatelessWidget {
  const LeaveTypePickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final balances = context.watch<AppState>().leaveBalances;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Request Leave', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'Choose a leave type to continue',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          Card(
            child: Column(
              children: [
                for (var i = 0; i < balances.length; i++)
                  _TypeTile(
                    balance: balances[i],
                    showDivider: i > 0,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => LeaveRequestFormScreen(leaveType: balances[i])),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeTile extends StatelessWidget {
  final LeaveBalance balance;
  final bool showDivider;
  final VoidCallback onTap;

  const _TypeTile({required this.balance, required this.showDivider, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: showDivider ? const Border(top: BorderSide(color: Color(0xFFF1F5F9))) : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${balance.type} Leave',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ),
            Text(
              '${balance.remaining} days left',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: balance.color),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 17, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }
}
