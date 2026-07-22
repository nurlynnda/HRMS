import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class _QuickAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

/// Row of four icon shortcuts shown on Home: Attendance, Leave, Claims,
/// Payslip. Attendance/Leave switch the bottom-nav tab; Claims/Payslip push
/// their own screens.
class QuickActionsRow extends StatelessWidget {
  final VoidCallback onAttendanceTap;
  final VoidCallback onLeaveTap;
  final VoidCallback onClaimsTap;
  final VoidCallback onPayslipTap;

  const QuickActionsRow({
    super.key,
    required this.onAttendanceTap,
    required this.onLeaveTap,
    required this.onClaimsTap,
    required this.onPayslipTap,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.access_time_outlined,
        label: 'Attendance',
        onTap: onAttendanceTap,
      ),
      _QuickAction(
        icon: Icons.event_note_outlined,
        label: 'Leave',
        onTap: onLeaveTap,
      ),
      _QuickAction(
        icon: Icons.receipt_long_outlined,
        label: 'Claims',
        onTap: onClaimsTap,
      ),
      _QuickAction(
        icon: Icons.credit_card_outlined,
        label: 'Payslip',
        onTap: onPayslipTap,
      ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions.map((action) {
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: action.onTap,
          child: Column(
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
        );
      }).toList(),
    );
  }
}
