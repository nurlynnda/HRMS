import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/calendar_grid.dart';

/// Month-grid calendar for picking a leave start/end date range.
///
/// Tap behavior: the first tap (or any tap once a full range is already
/// picked) starts a fresh selection; a tap before the current start
/// replaces the start; any other tap fills in the end date. Past days
/// are disabled. [initialDate] only controls which month is shown before
/// any date is picked (defaults to today) — it exists so tests can pin
/// the displayed month deterministically.
class LeaveDatePickerCalendar extends StatefulWidget {
  final DateTime? start;
  final DateTime? end;
  final DateTime? initialDate;
  final ValueChanged<DateTime?> onStartChanged;
  final ValueChanged<DateTime?> onEndChanged;

  const LeaveDatePickerCalendar({
    super.key,
    required this.start,
    required this.end,
    this.initialDate,
    required this.onStartChanged,
    required this.onEndChanged,
  });

  @override
  State<LeaveDatePickerCalendar> createState() => _LeaveDatePickerCalendarState();
}

class _LeaveDatePickerCalendarState extends State<LeaveDatePickerCalendar> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    final anchor = widget.start ?? widget.initialDate ?? DateTime.now();
    _year = anchor.year;
    _month = anchor.month;
  }

  void _previousMonth() {
    setState(() {
      if (_month == 1) {
        _month = 12;
        _year -= 1;
      } else {
        _month -= 1;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      if (_month == 12) {
        _month = 1;
        _year += 1;
      } else {
        _month += 1;
      }
    });
  }

  void _onDayTapped(int day) {
    final tapped = DateTime(_year, _month, day);
    final start = widget.start;
    final end = widget.end;
    if (start == null || end != null) {
      widget.onStartChanged(tapped);
      widget.onEndChanged(null);
    } else if (tapped.isBefore(start)) {
      widget.onStartChanged(tapped);
    } else {
      widget.onEndChanged(tapped);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isPast(int day) {
    final date = DateTime(_year, _month, day);
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    return date.isBefore(todayOnly);
  }

  bool _isEndpoint(int day) {
    final date = DateTime(_year, _month, day);
    return (widget.start != null && _isSameDay(date, widget.start!)) ||
        (widget.end != null && _isSameDay(date, widget.end!));
  }

  bool _isInRange(int day) {
    final start = widget.start;
    final end = widget.end;
    if (start == null || end == null) return false;
    final date = DateTime(_year, _month, day);
    return date.isAfter(start) && date.isBefore(end);
  }

  @override
  Widget build(BuildContext context) {
    final cells = buildMonthGrid(_year, _month);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _NavButton(icon: Icons.chevron_left, onTap: _previousMonth),
                Text(
                  '${monthNames[_month - 1]} $_year',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                _NavButton(icon: Icons.chevron_right, onTap: _nextMonth),
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
              childAspectRatio: 1,
              children: cells.map((day) {
                if (day == null) return const SizedBox.shrink();
                final past = _isPast(day);
                final endpoint = _isEndpoint(day);
                final inRange = _isInRange(day);
                return Padding(
                  padding: const EdgeInsets.all(2),
                  child: InkWell(
                    onTap: past ? null : () => _onDayTapped(day),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: endpoint
                            ? AppColors.primary
                            : (inRange ? AppColors.primaryTint : Colors.transparent),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: endpoint ? FontWeight.w800 : FontWeight.w600,
                          color: past ? AppColors.textMuted : (endpoint ? Colors.white : AppColors.textPrimary),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
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
  final VoidCallback onTap;

  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, size: 16, color: AppColors.textSecondary),
      ),
    );
  }
}
