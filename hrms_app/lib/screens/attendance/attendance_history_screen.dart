import 'package:flutter/material.dart';
import '../../models/attendance_history_stats.dart';
import '../../models/attendance_record.dart';
import '../../theme/app_theme.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  final List<AttendanceRecord> records;
  final AttendanceHistoryStats stats;

  const AttendanceHistoryScreen({
    super.key,
    required this.records,
    required this.stats,
  });

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  static const _filters = ['All', 'On time', 'Late', 'Leave'];
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedFilter == 'All'
        ? widget.records
        : widget.records.where((r) => r.status == _selectedFilter).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text(
          'Attendance History',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: _StatChip(value: '${widget.stats.present}', label: 'Present', color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatChip(value: '${widget.stats.late}', label: 'Late', color: AppColors.warning),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatChip(value: '${widget.stats.leave}', label: 'Leave', color: AppColors.info),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatChip(value: widget.stats.avgLabel, label: 'Avg', color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 18),
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
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: r.statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${r.day}',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: r.statusColor),
                            ),
                            Text(
                              r.dayOfWeek,
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: r.statusColor),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.timesLabel,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              r.note.isEmpty ? r.dateLabel : r.note,
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            r.hoursLabel,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            r.status,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: r.statusColor),
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

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatChip({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
