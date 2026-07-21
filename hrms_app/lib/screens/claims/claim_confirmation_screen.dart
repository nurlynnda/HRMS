import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency.dart';

class ClaimConfirmationScreen extends StatelessWidget {
  final String category;
  final double amount;
  final String reference;

  const ClaimConfirmationScreen({
    super.key,
    required this.category,
    required this.amount,
    required this.reference,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: const BoxDecoration(color: AppColors.primaryTint, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Container(
                        width: 58,
                        height: 58,
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.check, color: Colors.white, size: 30),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Claim submitted',
                      style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Your claim has been sent to Marcus Lee, then Finance for reimbursement.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          _SummaryRow(label: 'Type', value: category),
                          const Divider(height: 24, color: Color(0xFFF1F5F9)),
                          _SummaryRow(label: 'Amount', value: 'RM ${formatCurrency(amount)}'),
                          const Divider(height: 24, color: Color(0xFFF1F5F9)),
                          _SummaryRow(label: 'Reference', value: reference, valueColor: AppColors.primary),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text('Back to Claims', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _SummaryRow({required this.label, required this.value, this.valueColor = AppColors.textPrimary});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: valueColor)),
      ],
    );
  }
}
