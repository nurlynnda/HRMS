import 'package:flutter/material.dart';
import '../models/day_hours.dart';
import '../theme/app_theme.dart';

/// Card showing this week's attendance hours as a simple bar chart, with
/// a total-hours summary above it.
class WeeklyHoursChart extends StatelessWidget {
  final List<DayHours> days;
  final String totalLabel;
  final String changeLabel;

  const WeeklyHoursChart({
    super.key,
    required this.days,
    required this.totalLabel,
    required this.changeLabel,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This week',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Attendance hours',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$totalLabel hrs',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      changeLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
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
                            height: 90 * (day.hours / maxHours),
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              color: day.highlighted
                                  ? AppColors.primaryHighlight
                                  : AppColors.primary,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(8),
                                bottom: Radius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            day.label,
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
          ],
        ),
      ),
    );
  }
}
