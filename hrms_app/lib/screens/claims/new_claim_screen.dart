import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/claim_entitlement.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency.dart';
import 'claim_confirmation_screen.dart';

class NewClaimScreen extends StatefulWidget {
  const NewClaimScreen({super.key});

  @override
  State<NewClaimScreen> createState() => _NewClaimScreenState();
}

class _NewClaimScreenState extends State<NewClaimScreen> {
  ClaimEntitlement? _selectedType;
  String? _selectedProject;
  double? _amount;
  String _description = '';
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _needsProject => _selectedType?.type == 'Travel';

  bool get _canSubmit =>
      _selectedType != null &&
      _amount != null &&
      _amount! > 0 &&
      _description.trim().isNotEmpty &&
      (!_needsProject || _selectedProject != null);

  double? get _excess {
    final type = _selectedType;
    final amount = _amount;
    if (type == null || amount == null || type.cap == null) return null;
    final overage = (type.used + amount) - type.cap!;
    return overage > 0 ? overage : null;
  }

  void _selectType(ClaimEntitlement type) {
    setState(() {
      _selectedType = type;
      if (type.type != 'Travel') _selectedProject = null;
    });
  }

  void _submit() {
    if (!_canSubmit) return;
    final appState = context.read<AppState>();
    final category = _selectedType!.type;
    final amount = _amount!;
    appState.submitClaim(category: category, amount: amount, description: _description.trim());
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ClaimConfirmationScreen(
          category: category,
          amount: amount,
          reference: appState.claims.first.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final entitlements = appState.claimEntitlements;
    final projects = appState.claimProjects;
    final approvers = appState.pendingClaimApprovers;
    final excess = _excess;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text('New claim', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          const Text('Claim type', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final e in entitlements)
                ChoiceChip(
                  label: Text(e.type),
                  selected: _selectedType == e,
                  onSelected: (_) => _selectType(e),
                  selectedColor: AppColors.primaryTint,
                  labelStyle: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: _selectedType == e ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          if (_selectedType != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: BoxDecoration(color: AppColors.primaryTint, borderRadius: BorderRadius.circular(11)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedType!.cap == null
                        ? '${_selectedType!.type} · No cap'
                        : '${_selectedType!.type} · RM ${formatCurrency(_selectedType!.remaining!)} left',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  Text(_selectedType!.subLabel, style: const TextStyle(fontSize: 10.5, color: Color(0xFF475569), fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          const Text('Amount', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(11)),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Text('RM', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textMuted)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (v) => setState(() => _amount = double.tryParse(v)),
                    decoration: const InputDecoration(border: InputBorder.none, hintText: '0.00'),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          if (excess != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.warningTint,
                border: Border.all(color: const Color(0xFFFDE68A)),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text(
                'RM ${formatCurrency(excess)} over your remaining limit. You can still submit — only RM ${formatCurrency(_amount! - excess)} will be reimbursed.',
                style: const TextStyle(fontSize: 10.5, color: Color(0xFF92400E), height: 1.55),
              ),
            ),
          ],
          if (_needsProject) ...[
            const SizedBox(height: 14),
            const Text('Project', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final p in projects)
                  ChoiceChip(
                    label: Text(p),
                    selected: _selectedProject == p,
                    onSelected: (_) => setState(() => _selectedProject = p),
                    selectedColor: AppColors.primaryTint,
                    labelStyle: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: _selectedProject == p ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          const Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'Description ', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                TextSpan(text: '*', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.danger)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            onChanged: (v) => setState(() => _description = v),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'What was this expense for?',
              filled: true,
              fillColor: AppColors.cardBackground,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: AppColors.border)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Approval flow', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                children: [
                  for (final a in approvers)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(a.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          Text(a.role, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _canSubmit ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: const Color(0xFFCBD5E1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Submit claim', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
