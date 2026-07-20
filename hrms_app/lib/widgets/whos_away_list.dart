import 'package:flutter/material.dart';
import '../models/team_absence.dart';
import '../theme/app_theme.dart';

class WhosAwayList extends StatelessWidget {
  final List<TeamAbsence> absences;

  const WhosAwayList({super.key, required this.absences});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Who's away this week",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            Text(
              '${absences.length} people',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...absences.map(
          (a) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.name,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        Text(
                          '${a.role} · ${a.dateRangeLabel}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                    decoration: BoxDecoration(color: a.badgeBg, borderRadius: BorderRadius.circular(999)),
                    child: Text(
                      a.leaveType,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: a.badgeColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
