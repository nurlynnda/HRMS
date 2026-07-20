import 'package:flutter/material.dart';

class AttendanceRecord {
  final int day;
  final String dayOfWeek;
  final String dateLabel;
  final String timesLabel;
  final String note;
  final String hoursLabel;
  final String status;
  final Color statusColor;

  const AttendanceRecord({
    required this.day,
    required this.dayOfWeek,
    required this.dateLabel,
    required this.timesLabel,
    required this.note,
    required this.hoursLabel,
    required this.status,
    required this.statusColor,
  });
}
