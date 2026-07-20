import 'package:flutter/material.dart';

/// One step in a leave request's approval chain.
class Approver {
  final String initials;
  final Color tint;
  final Color color;
  final String name;
  final String role;
  final String status;
  final Color badgeBg;
  final Color badgeColor;
  final String when;

  const Approver({
    required this.initials,
    required this.tint,
    required this.color,
    required this.name,
    required this.role,
    required this.status,
    required this.badgeBg,
    required this.badgeColor,
    required this.when,
  });
}
