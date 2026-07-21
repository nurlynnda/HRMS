import 'package:flutter/material.dart';
import '../../models/approver.dart';
import '../../models/claim.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency.dart';

class ClaimDetailScreen extends StatelessWidget {
  final Claim claim;

  const ClaimDetailScreen({super.key, required this.claim});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text(
          'Claim details',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'RM ${formatCurrency(claim.amount)}',
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${claim.category} · ${claim.id}',
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: claim.statusBg, borderRadius: BorderRadius.circular(999)),
                        child: Text(
                          claim.status,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: claim.statusColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Date', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      Text(claim.dateLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(claim.description, style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.5)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Approval progress', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Column(
                children: [
                  for (var i = 0; i < claim.approvers.length; i++)
                    _ApproverRow(
                      approver: claim.approvers[i],
                      showConnector: i < claim.approvers.length - 1,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApproverRow extends StatelessWidget {
  final Approver approver;
  final bool showConnector;

  const _ApproverRow({required this.approver, required this.showConnector});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: approver.tint, borderRadius: BorderRadius.circular(11)),
              alignment: Alignment.center,
              child: Text(approver.initials, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: approver.color)),
            ),
            if (showConnector) Container(width: 2, height: 24, color: const Color(0xFFEEF2F6)),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: showConnector ? 14 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(approver.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: approver.badgeBg, borderRadius: BorderRadius.circular(999)),
                      child: Text(approver.status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: approver.badgeColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(approver.role, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 2),
                Text(approver.when, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
