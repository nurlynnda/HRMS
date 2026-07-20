import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/calendar_grid.dart';

/// Team leave calendar: month grid with a highlighted "today" and small
/// colored dots under any day someone on the team is away. Month
/// navigation arrows are visual only for this phase (no month-switching
/// logic yet).
class TeamCalendarCard extends StatelessWidget {
  final int year;
  final int month;
  final int todayDay;
  final Map<int, List<Color>> dayColors;

  const TeamCalendarCard({
    super.key,
    required this.year,
    required this.month,
    required this.todayDay,
    required this.dayColors,
  });

  @override
  Widget build(BuildContext context) {
    final cells = buildMonthGrid(year, month);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _NavButton(icon: Icons.chevron_left),
                Text(
                  '${monthNames[month - 1]} $year',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const _NavButton(icon: Icons.chevron_right),
              ],
            ),
            const SizedBox(height: 14),
            const Row(
              children: [
                Expanded(child: _WeekdayLabel('M')),
                Expanded(child: _WeekdayLabel('T')),
                Expanded(child: _WeekdayLabel('W')),
                Expanded(child: _WeekdayLabel('T')),
                Expanded(child: _WeekdayLabel('F')),
                Expanded(child: _WeekdayLabel('S', muted: true)),
                Expanded(child: _WeekdayLabel('S', muted: true)),
              ],
            ),
            const SizedBox(height: 4),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 0.85,
              children: cells.map((day) {
                if (day == null) return const SizedBox.shrink();
                final isToday = day == todayDay;
                final dots = dayColors[day] ?? const <Color>[];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isToday ? AppColors.primary : Colors.transparent,
                        ),
                        child: Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isToday ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      SizedBox(
                        height: 5,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: dots
                              .map(
                                (c) => Container(
                                  width: 5,
                                  height: 5,
                                  margin: const EdgeInsets.symmetric(horizontal: 1),
                                  decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),
            const Row(
              children: [
                _LegendItem(color: AppColors.primary, label: 'Annual'),
                SizedBox(width: 14),
                _LegendItem(color: AppColors.warning, label: 'Sick'),
                SizedBox(width: 14),
                _LegendItem(color: Color(0xFF8B5CF6), label: 'Personal'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  final String label;
  final bool muted;

  const _WeekdayLabel(this.label, {this.muted = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: muted ? const Color(0xFFCBD5E1) : AppColors.textMuted,
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;

  const _NavButton({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(9)),
      child: Icon(icon, size: 16, color: AppColors.textSecondary),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
