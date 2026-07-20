import 'package:flutter/material.dart';

/// One entry in the "Who's away this week" list.
class TeamAbsence {
  final String name;
  final String role;
  final String dateRangeLabel;
  final String leaveType;
  final Color badgeColor;
  final Color badgeBg;

  const TeamAbsence({
    required this.name,
    required this.role,
    required this.dateRangeLabel,
    required this.leaveType,
    required this.badgeColor,
    required this.badgeBg,
  });
}
