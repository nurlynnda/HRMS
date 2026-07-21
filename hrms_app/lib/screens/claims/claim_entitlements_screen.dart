import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/claim_entitlement.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency.dart';

class ClaimEntitlementsScreen extends StatelessWidget {
  const ClaimEntitlementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final entitlements = context.watch<AppState>().claimEntitlements;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Claim entitlements', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: Text("Your claim limits and what's left.", style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
          ),
          for (final e in entitlements) _EntitlementCard(entitlement: e),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(11)),
            child: const Text(
              "Limits reset on a rolling window from your first claim. Travel has no cap but must be tied to a company project.",
              style: TextStyle(fontSize: 10.5, color: AppColors.textMuted, height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _EntitlementCard extends StatelessWidget {
  final ClaimEntitlement entitlement;

  const _EntitlementCard({required this.entitlement});

  @override
  Widget build(BuildContext context) {
    final cap = entitlement.cap;
    return Card(
      margin: const EdgeInsets.only(bottom: 7),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entitlement.type, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      Text(entitlement.subLabel, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                Text(
                  cap == null ? 'No cap' : 'RM ${formatCurrency(entitlement.remaining!)} left',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: entitlement.color),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: cap == null ? 1.0 : entitlement.progress,
                minHeight: 5,
                backgroundColor: const Color(0xFFEEF2F6),
                valueColor: AlwaysStoppedAnimation(entitlement.color),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              cap == null
                  ? 'RM ${formatCurrency(entitlement.used)} used YTD'
                  : 'RM ${formatCurrency(entitlement.used)} used of RM ${formatCurrency(cap)}',
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
