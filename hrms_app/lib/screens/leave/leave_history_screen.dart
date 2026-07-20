import 'package:flutter/material.dart';
import '../../models/leave_request.dart';
import '../../theme/app_theme.dart';

class LeaveHistoryScreen extends StatefulWidget {
  final List<LeaveRequest> requests;

  const LeaveHistoryScreen({super.key, required this.requests});

  @override
  State<LeaveHistoryScreen> createState() => _LeaveHistoryScreenState();
}

class _LeaveHistoryScreenState extends State<LeaveHistoryScreen> {
  static const _filters = ['All', 'Approved', 'Pending', 'Rejected'];
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedFilter == 'All'
        ? widget.requests
        : widget.requests.where((r) => r.status == _selectedFilter).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text(
          'Leave History',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Wrap(
            spacing: 8,
            children: _filters
                .map(
                  (f) => ChoiceChip(
                    label: Text(f),
                    selected: _selectedFilter == f,
                    onSelected: (_) => setState(() => _selectedFilter = f),
                    selectedColor: AppColors.primaryTint,
                    labelStyle: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: _selectedFilter == f ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 18),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'No $_selectedFilter records in 2026.',
                  style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
              ),
            )
          else
            ...filtered.map(
              (r) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(color: AppColors.primaryTint, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.event_note_outlined, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.type,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                            Text(
                              r.dateRangeLabel,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                        decoration: BoxDecoration(color: r.statusBg, borderRadius: BorderRadius.circular(999)),
                        child: Text(
                          r.status,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: r.statusColor),
                        ),
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
