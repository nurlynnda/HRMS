import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency.dart';
import 'claim_detail_screen.dart';
import 'claim_entitlements_screen.dart';
import 'new_claim_screen.dart';

class ClaimsScreen extends StatelessWidget {
  const ClaimsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Claims', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NewClaimScreen()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                ),
                child: const Text('New claim', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                  decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pending', style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                      Text('RM ${formatCurrency(appState.pendingClaimsTotal)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                      Text('${appState.pendingClaimsCount} claims', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    border: Border.all(color: const Color(0xFFEEF2F6)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Approved YTD', style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                      Text('RM ${formatCurrency(appState.approvedClaimsYtdTotal)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary)),
                      Text('of RM ${formatCurrency(appState.approvedClaimsYtdCap)} cap', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          InkWell(
            borderRadius: BorderRadius.circular(11),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ClaimEntitlementsScreen()),
            ),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 10, bottom: 18),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                border: Border.all(color: const Color(0xFFEEF2F6)),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Claim entitlements', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        const Text('Outpatient · Dental · Specs limits', style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 15, color: Color(0xFFCBD5E1)),
                ],
              ),
            ),
          ),
          const Text('Recent claims', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          for (final claim in appState.claims)
            Card(
              margin: const EdgeInsets.only(bottom: 7),
              child: InkWell(
                borderRadius: BorderRadius.circular(11),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ClaimDetailScreen(claim: claim)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(claim.category, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                            Text('${claim.dateLabel} · ${claim.id}', style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('RM ${formatCurrency(claim.amount)}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(color: claim.statusBg, borderRadius: BorderRadius.circular(999)),
                            child: Text(claim.status, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: claim.statusColor)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
