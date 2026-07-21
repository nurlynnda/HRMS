import 'package:flutter/material.dart';
import 'approver.dart';

class Claim {
  final String id;
  final String category;
  final String dateLabel;
  final double amount;
  final String status;
  final Color statusColor;
  final Color statusBg;
  final String description;
  final List<Approver> approvers;

  const Claim({
    required this.id,
    required this.category,
    required this.dateLabel,
    required this.amount,
    required this.status,
    required this.statusColor,
    required this.statusBg,
    required this.description,
    required this.approvers,
  });
}
