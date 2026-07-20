import 'package:flutter/material.dart';

class LeaveBalance {
  final String type;
  final int used;
  final int total;
  final Color color;

  const LeaveBalance({
    required this.type,
    required this.used,
    required this.total,
    required this.color,
  });

  int get remaining => total - used;
}
