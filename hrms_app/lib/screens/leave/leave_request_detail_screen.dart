import 'package:flutter/material.dart';
import '../../models/approver.dart';
import '../../models/leave_request.dart';
import '../../theme/app_theme.dart';

class LeaveRequestDetailScreen extends StatelessWidget {
  final LeaveRequest request;

  const LeaveRequestDetailScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    String? pendingApprover;
    if (request.status == 'Pending') {
      for (final a in request.approvers) {
        if (a.status == 'Pending') {
          pendingApprover = a.name;
          break;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text(
          'Request details',
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
                              request.type,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              request.dateRangeLabel,
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: request.statusBg, borderRadius: BorderRadius.circular(999)),
                        child: Text(
                          request.status,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: request.statusColor),
                        ),
                      ),
                    ],
                  ),
                  if (pendingApprover != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                      decoration: BoxDecoration(color: AppColors.warningTint, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, size: 17, color: Color(0xFFB45309)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Waiting on $pendingApprover to approve',
                              style: const TextStyle(fontSize: 12.5, color: Color(0xFF92400E), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (request.reason.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Remarks', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Text(
                  request.reason,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.5),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Text('Approval progress', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Column(
                children: [
                  for (var i = 0; i < request.approvers.length; i++)
                    _ApproverRow(
                      approver: request.approvers[i],
                      showConnector: i < request.approvers.length - 1,
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
              child: Text(
                approver.initials,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: approver.color),
              ),
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
                    Text(
                      approver.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: approver.badgeBg, borderRadius: BorderRadius.circular(999)),
                      child: Text(
                        approver.status,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: approver.badgeColor),
                      ),
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
