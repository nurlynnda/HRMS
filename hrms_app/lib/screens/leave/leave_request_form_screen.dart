import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/leave_balance.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_range_label.dart';
import '../../widgets/leave_date_picker_calendar.dart';
import 'leave_request_confirmation_screen.dart';

class LeaveRequestFormScreen extends StatefulWidget {
  final LeaveBalance leaveType;
  final DateTime? initialCalendarDate;

  const LeaveRequestFormScreen({super.key, required this.leaveType, this.initialCalendarDate});

  @override
  State<LeaveRequestFormScreen> createState() => _LeaveRequestFormScreenState();
}

class _LeaveRequestFormScreenState extends State<LeaveRequestFormScreen> {
  DateTime? _start;
  DateTime? _end;
  final _reasonController = TextEditingController();
  String _reason = '';

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  bool get _canSubmit => _start != null && _reason.trim().isNotEmpty;

  void _submit() {
    if (!_canSubmit) return;
    final start = _start!;
    final end = _end ?? _start!;
    final type = '${widget.leaveType.type} Leave';
    context.read<AppState>().submitLeaveRequest(
          type: type,
          start: start,
          end: end,
          reason: _reason.trim(),
        );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LeaveRequestConfirmationScreen(
          type: type,
          dateRangeLabel: formatDateRangeLabel(start, end),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final approvers = context.watch<AppState>().pendingApprovalChain;
    final start = _start;
    final end = _end;
    final fromLabel = start == null ? '—' : '${monthAbbr[start.month - 1]} ${start.day}';
    final toLabel = end == null
        ? (start == null ? '—' : fromLabel)
        : '${monthAbbr[end.month - 1]} ${end.day}';
    final totalLabel = start == null ? '—' : '${(end ?? start).difference(start).inDays + 1}d';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Request Leave', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.primaryTint, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.event_note_outlined, color: widget.leaveType.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${widget.leaveType.type} Leave',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text('Select dates', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          LeaveDatePickerCalendar(
            start: _start,
            end: _end,
            initialDate: widget.initialCalendarDate,
            onStartChanged: (d) => setState(() => _start = d),
            onEndChanged: (d) => setState(() => _end = d),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('From', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                        Text(fromLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('To', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                        Text(toLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 76,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
                decoration: BoxDecoration(color: AppColors.primaryTint, borderRadius: BorderRadius.circular(14)),
                child: Column(
                  children: [
                    const Text('Total', style: TextStyle(fontSize: 11, color: Color(0xFF047857), fontWeight: FontWeight.w600)),
                    Text(totalLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'Reason ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                TextSpan(text: '*', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.danger)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _reasonController,
            onChanged: (v) => setState(() => _reason = v),
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Enter your reason for this leave (required)',
              filled: true,
              fillColor: AppColors.cardBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text('Approval flow', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  for (final a in approvers)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(color: a.tint, borderRadius: BorderRadius.circular(10)),
                            alignment: Alignment.center,
                            child: Text(a.initials, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: a.color)),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                Text(a.role, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _canSubmit ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: const Color(0xFFCBD5E1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text('Submit request', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
