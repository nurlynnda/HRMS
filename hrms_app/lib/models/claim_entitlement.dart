import 'package:flutter/material.dart';

/// One claim category's usage limit, e.g. Outpatient RM 800/yr. [cap]
/// is null for uncapped categories (Travel), which always render as
/// "No cap" instead of a progress bar.
class ClaimEntitlement {
  final String type;
  final String subLabel;
  final double used;
  final double? cap;
  final Color color;

  const ClaimEntitlement({
    required this.type,
    required this.subLabel,
    required this.used,
    required this.cap,
    required this.color,
  });

  double? get remaining => cap == null ? null : cap! - used;
  double get progress => cap == null ? 0 : (used / cap!).clamp(0.0, 1.0);
}
