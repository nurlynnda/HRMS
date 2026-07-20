import 'package:flutter/material.dart';
import 'approver.dart';

class LeaveRequest {
  final String type;
  final String dateRangeLabel;
  final String status;
  final Color statusColor;
  final Color statusBg;
  final String reason;
  final List<Approver> approvers;

  const LeaveRequest({
    required this.type,
    required this.dateRangeLabel,
    required this.status,
    required this.statusColor,
    required this.statusBg,
    required this.reason,
    required this.approvers,
  });
}
