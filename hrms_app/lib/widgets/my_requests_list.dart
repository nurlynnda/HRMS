import 'package:flutter/material.dart';
import '../models/leave_request.dart';
import '../theme/app_theme.dart';

/// "My requests" section on the Leave tab: header with a "View all"
/// link and the 3 most recent requests, each tappable to view its
/// detail page (navigation is handled by the caller via [onRequestTap]
/// — this widget stays "dumb", per the app's established pattern).
class MyRequestsList extends StatelessWidget {
  final List<LeaveRequest> requests;
  final VoidCallback onViewAll;
  final ValueChanged<LeaveRequest> onRequestTap;

  const MyRequestsList({
    super.key,
    required this.requests,
    required this.onViewAll,
    required this.onRequestTap,
  });

  @override
  Widget build(BuildContext context) {
    final recent = requests.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My requests',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            TextButton(
              onPressed: onViewAll,
              child: const Text(
                'View all',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
            ),
          ],
        ),
        ...recent.map(
          (r) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: r.status == 'Pending' ? const BorderSide(color: Color(0xFFFDE68A)) : BorderSide.none,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onRequestTap(r),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.type,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          Text(
                            r.dateRangeLabel,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                      decoration: BoxDecoration(color: r.statusBg, borderRadius: BorderRadius.circular(999)),
                      child: Text(
                        r.status,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: r.statusColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, size: 18, color: Color(0xFFCBD5E1)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
