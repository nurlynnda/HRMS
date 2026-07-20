import 'package:flutter/material.dart';
import '../models/attendance_week_stats.dart';
import '../models/day_hours.dart';
import '../theme/app_theme.dart';

/// "This week" card on the Attendance tab: a compact bar chart (reusing
/// the same weekly-hours data the Home tab shows) plus on-time/late/avg
/// stat boxes.
class WeeklyAttendanceStatsCard extends StatelessWidget {
  final List<DayHours> days;
  final AttendanceWeekStats stats;

  const WeeklyAttendanceStatsCard({
    super.key,
    required this.days,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final maxHours = days.map((d) => d.hours).reduce((a, b) => a > b ? a : b);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This week',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: days
                  .map(
                    (day) => Expanded(
                      child: Column(
                        children: [
                          Container(
                            height: 76 * (day.hours / maxHours),
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              color: day.highlighted ? AppColors.primaryHighlight : AppColors.primary,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(7),
                                bottom: Radius.circular(3),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            day.label.substring(0, 1),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: day.highlighted ? FontWeight.w700 : FontWeight.w600,
                              color: day.highlighted ? AppColors.primary : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _StatBox(
                    value: '${stats.onTime}',
                    label: 'On time',
                    valueColor: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatBox(
                    value: '${stats.late}',
                    label: 'Late',
                    valueColor: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatBox(
                    value: stats.avgPerDayLabel,
                    label: 'Avg/day',
                    valueColor: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;

  const _StatBox({required this.value, required this.label, required this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: valueColor)),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
