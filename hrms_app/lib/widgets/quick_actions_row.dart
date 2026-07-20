import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class _QuickAction {
  final IconData icon;
  final String label;

  const _QuickAction(this.icon, this.label);
}

/// Row of four icon shortcuts shown on Home: Attendance, Leave, Claims,
/// Payslip. Display-only for now — see plan for why they're not wired to
/// navigation yet.
class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({super.key});

  static const _actions = [
    _QuickAction(Icons.access_time_outlined, 'Attendance'),
    _QuickAction(Icons.event_note_outlined, 'Leave'),
    _QuickAction(Icons.receipt_long_outlined, 'Claims'),
    _QuickAction(Icons.credit_card_outlined, 'Payslip'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _actions
          .map(
            (action) => Column(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.primaryTint,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(action.icon, color: AppColors.primary, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  action.label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }
}
