# HRMS Mobile App — Phase 4: Leave Tab (View Flows) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the Leave tab's placeholder with the real *viewing* flows
from the mockup — the main Leave screen (upcoming holiday, team calendar,
who's away this week, my requests), a filterable Leave History sub-page,
and a Leave Request Detail sub-page with an approval-progress timeline.

**Scope decision:** The mockup also has a full "create a leave request"
flow (type picker → form with date-range calendar, medical-certificate
photo upload, reason, approval-flow preview → submission → confirmation)
and a standalone "Leave Balance" full-page. Both are deferred to a later
phase: the request-creation flow is a large, separate piece of work in its
own right (and photo upload has the same "can't test on this machine yet"
problem attendance's face check-in had), and the Balance full-page has no
clear navigation entry point in the screens covered here. This phase's
"Request" button is therefore **visual-only, not wired to navigation
yet** — same precedent as `QuickActionsRow` in Phase 2.

**Architecture:** Same pattern as Phases 2-3 — small `StatelessWidget`s
under `lib/widgets/` taking data via constructor parameters, composed by
`LeaveScreen` (which reads `AppState`). Two new sub-screens
(`LeaveHistoryScreen`, `LeaveRequestDetailScreen`) live under
`lib/screens/leave/` alongside `LeaveScreen`, matching Phase 3's
`AttendanceHistoryScreen` precedent — screens may navigate directly to
sibling screens; only `lib/widgets/` stay "dumb" (callback-driven, no
direct navigation). One new piece: `lib/utils/calendar_grid.dart`, a pure
Dart function generating a Monday-first calendar grid — extracted
separately from any widget so its logic is unit-testable without pumping
a widget tree.

## Global Constraints

- Primary accent `#10B981` (`AppColors.primary`), gradient partner
  `#059669`. Background `#F1F5F9`. Text: primary `#0F172A`, secondary
  `#64748B`, muted `#94A3B8`. Danger `#EF4444`. Warning `#F59E0B`. Border
  `#E2E8F0`. Tints: `primaryTint` `#ECFDF5`, `primaryHighlight` `#6EE7B7`,
  `ringTrack` `#EEF2F6`, `info` `#2563EB` — all already in
  `hrms_app/lib/theme/app_theme.dart`. This phase adds two more:
  `warningTint` `#FFFBEB` and `dangerTint` `#FEE2E2`.
- Card style: use Flutter's `Card` widget, not manual `BoxDecoration`, for
  anything matching the established card look (16px radius, white, soft
  shadow).
- All data is hardcoded/fake. No mutation methods are added to `AppState`
  in this phase (there's nothing to mutate yet — request *creation* is
  Phase 5). This phase only adds read-only getters.
- The "Request" button on the Leave tab's header is visual-only (styled
  like a real button, not tappable) — matches the `QuickActionsRow`
  precedent from Phase 2. Do not wire it to navigation.
- The Leave Balance full-page from the mockup is out of scope for this
  phase (see Scope decision above) — do not build it.
- Verification: `flutter analyze` clean, `flutter test` all passing.
  Android emulator unavailable (known, separately-tracked bug) —
  Chrome/web build and widget tests are the verification path, same as
  Phases 1-3.

---

### Task 1: Data models for Leave

**Files:**
- Create: `hrms_app/lib/models/approver.dart`
- Create: `hrms_app/lib/models/leave_request.dart`
- Create: `hrms_app/lib/models/team_absence.dart`

**Interfaces:**
- Produces: `Approver(initials, tint, color, name, role, status, badgeBg,
  badgeColor, when)`, `LeaveRequest(type, dateRangeLabel, status,
  statusColor, statusBg, reason, approvers)`, `TeamAbsence(name, role,
  dateRangeLabel, leaveType, badgeColor, badgeBg)`. Consumed by Tasks 2, 4,
  6, 7, 8, 9.

- [ ] **Step 1: Write the three model files**

  Create `hrms_app/lib/models/approver.dart`:
  ```dart
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
  ```

  Create `hrms_app/lib/models/leave_request.dart`:
  ```dart
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
  ```

  Create `hrms_app/lib/models/team_absence.dart`:
  ```dart
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
  ```

- [ ] **Step 2: Verify it compiles**

  Run: `flutter analyze`
  Expected: `No issues found!`

- [ ] **Step 3: Commit**

  ```
  cd C:\Projects\HRMS
  git add hrms_app/lib/models
  git commit -m "Add data models for the Leave tab"
  ```

---

### Task 2: Extend theme and fake data for Leave

**Files:**
- Modify: `hrms_app/lib/theme/app_theme.dart` (add `warningTint`,
  `dangerTint`)
- Modify: `hrms_app/lib/data/fake_data.dart` (add Leave tab fake data)

**Interfaces:**
- Consumes: `Approver`, `LeaveRequest`, `TeamAbsence` (Task 1).
- Produces: `AppColors.warningTint`, `AppColors.dangerTint`;
  `FakeData.upcomingHolidayLabel`, `FakeData.teamCalendarYear`,
  `FakeData.teamCalendarMonth`, `FakeData.teamCalendarTodayDay`,
  `FakeData.teamCalendarDayColors` (`Map<int, List<Color>>`),
  `FakeData.teamAbsences` (3 entries), `FakeData.myLeaveRequests` (6
  entries). Consumed by Task 4.

- [ ] **Step 1: Add the two new colors**

  In `hrms_app/lib/theme/app_theme.dart`, add two lines inside
  `AppColors`, after the existing `info` line:
  ```dart
    static const warningTint = Color(0xFFFFFBEB);
    static const dangerTint = Color(0xFFFEE2E2);
  ```

- [ ] **Step 2: Update fake_data.dart**

  In `hrms_app/lib/data/fake_data.dart`:
  1. Add these imports alongside the existing ones:
     ```dart
     import '../models/approver.dart';
     import '../models/leave_request.dart';
     import '../models/team_absence.dart';
     ```
  2. Add these new static members to the `FakeData` class:
     ```dart
       static const upcomingHolidayLabel = 'Independence Day · Fri, Jul 4';

       static const teamCalendarYear = 2026;
       static const teamCalendarMonth = 6;
       static const teamCalendarTodayDay = 20;
       static const teamCalendarDayColors = <int, List<Color>>{
         20: [AppColors.warning],
         23: [AppColors.primary],
         24: [AppColors.primary],
         25: [AppColors.primary],
         26: [AppColors.primary],
         27: [AppColors.primary],
       };

       static const teamAbsences = [
         TeamAbsence(
           name: 'Marcus Lee',
           role: 'Design Lead',
           dateRangeLabel: 'Jun 23 – 25',
           leaveType: 'Annual',
           badgeColor: AppColors.primary,
           badgeBg: AppColors.primaryTint,
         ),
         TeamAbsence(
           name: 'Priya Nair',
           role: 'UX Researcher',
           dateRangeLabel: 'Today',
           leaveType: 'Sick',
           badgeColor: AppColors.warning,
           badgeBg: AppColors.warningTint,
         ),
         TeamAbsence(
           name: 'Tom Alvarez',
           role: 'Visual Designer',
           dateRangeLabel: 'Jun 26 – 27',
           leaveType: 'Annual',
           badgeColor: AppColors.primary,
           badgeBg: AppColors.primaryTint,
         ),
       ];

       static const _approversAllApproved = [
         Approver(
           initials: 'ML',
           tint: Color(0xFFDBEAFE),
           color: Color(0xFF1D4ED8),
           name: 'Marcus Lee',
           role: 'Design Lead · 1st approver',
           status: 'Approved',
           badgeBg: AppColors.primaryTint,
           badgeColor: AppColors.primary,
           when: 'Jun 1, 9:12 AM',
         ),
         Approver(
           initials: 'RT',
           tint: Color(0xFFF1E9FF),
           color: Color(0xFF6D28D9),
           name: 'Rachel Tan',
           role: 'Dept. Manager · 2nd approver',
           status: 'Approved',
           badgeBg: AppColors.primaryTint,
           badgeColor: AppColors.primary,
           when: 'Jun 1, 2:40 PM',
         ),
         Approver(
           initials: 'JW',
           tint: Color(0xFFFEE9D6),
           color: Color(0xFFC2410C),
           name: 'James Wong',
           role: 'HR Manager · final approver',
           status: 'Approved',
           badgeBg: AppColors.primaryTint,
           badgeColor: AppColors.primary,
           when: 'Jun 2, 10:05 AM',
         ),
       ];

       static const _approversPending = [
         Approver(
           initials: 'ML',
           tint: Color(0xFFDBEAFE),
           color: Color(0xFF1D4ED8),
           name: 'Marcus Lee',
           role: 'Design Lead · 1st approver',
           status: 'Pending',
           badgeBg: AppColors.warningTint,
           badgeColor: AppColors.warning,
           when: '—',
         ),
         Approver(
           initials: 'RT',
           tint: Color(0xFFF1E9FF),
           color: Color(0xFF6D28D9),
           name: 'Rachel Tan',
           role: 'Dept. Manager · 2nd approver',
           status: 'Waiting',
           badgeBg: Color(0xFFF1F5F9),
           badgeColor: AppColors.textSecondary,
           when: '—',
         ),
         Approver(
           initials: 'JW',
           tint: Color(0xFFFEE9D6),
           color: Color(0xFFC2410C),
           name: 'James Wong',
           role: 'HR Manager · final approver',
           status: 'Waiting',
           badgeBg: Color(0xFFF1F5F9),
           badgeColor: AppColors.textSecondary,
           when: '—',
         ),
       ];

       static const _approversRejected = [
         Approver(
           initials: 'ML',
           tint: Color(0xFFDBEAFE),
           color: Color(0xFF1D4ED8),
           name: 'Marcus Lee',
           role: 'Design Lead · 1st approver',
           status: 'Rejected',
           badgeBg: AppColors.dangerTint,
           badgeColor: AppColors.danger,
           when: 'May 10, 4:22 PM',
         ),
         Approver(
           initials: 'RT',
           tint: Color(0xFFF1E9FF),
           color: Color(0xFF6D28D9),
           name: 'Rachel Tan',
           role: 'Dept. Manager · 2nd approver',
           status: 'Waiting',
           badgeBg: Color(0xFFF1F5F9),
           badgeColor: AppColors.textSecondary,
           when: '—',
         ),
         Approver(
           initials: 'JW',
           tint: Color(0xFFFEE9D6),
           color: Color(0xFFC2410C),
           name: 'James Wong',
           role: 'HR Manager · final approver',
           status: 'Waiting',
           badgeBg: Color(0xFFF1F5F9),
           badgeColor: AppColors.textSecondary,
           when: '—',
         ),
       ];

       static const myLeaveRequests = [
         LeaveRequest(
           type: 'Annual Leave',
           dateRangeLabel: 'Jul 14 – 16 · 3 days',
           status: 'Pending',
           statusColor: AppColors.warning,
           statusBg: AppColors.warningTint,
           reason: 'Family trip planned before the new project kicks off.',
           approvers: _approversPending,
         ),
         LeaveRequest(
           type: 'Medical Leave',
           dateRangeLabel: 'Jun 3 · 1 day',
           status: 'Approved',
           statusColor: AppColors.primary,
           statusBg: AppColors.primaryTint,
           reason: 'Doctor-advised rest for flu recovery.',
           approvers: _approversAllApproved,
         ),
         LeaveRequest(
           type: 'Annual Leave',
           dateRangeLabel: 'May 2 – 3 · 2 days',
           status: 'Approved',
           statusColor: AppColors.primary,
           statusBg: AppColors.primaryTint,
           reason: 'Short break to attend a family event.',
           approvers: _approversAllApproved,
         ),
         LeaveRequest(
           type: 'Personal Leave',
           dateRangeLabel: 'Apr 18 · 1 day',
           status: 'Rejected',
           statusColor: AppColors.danger,
           statusBg: AppColors.dangerTint,
           reason: 'Requested during the product launch freeze window.',
           approvers: _approversRejected,
         ),
         LeaveRequest(
           type: 'Annual Leave',
           dateRangeLabel: 'Mar 5 – 6 · 2 days',
           status: 'Approved',
           statusColor: AppColors.primary,
           statusBg: AppColors.primaryTint,
           reason: 'Personal travel.',
           approvers: _approversAllApproved,
         ),
         LeaveRequest(
           type: 'Medical Leave',
           dateRangeLabel: 'Feb 14 · 1 day',
           status: 'Approved',
           statusColor: AppColors.primary,
           statusBg: AppColors.primaryTint,
           reason: 'Medical appointment.',
           approvers: _approversAllApproved,
         ),
       ];
     ```

- [ ] **Step 3: Verify it compiles**

  Run: `flutter analyze`
  Expected: `No issues found!`

- [ ] **Step 4: Commit**

  ```
  cd C:\Projects\HRMS
  git add hrms_app/lib/theme/app_theme.dart hrms_app/lib/data/fake_data.dart
  git commit -m "Add Leave tab fake data and warning/danger tint colors"
  ```

---

### Task 3: Calendar grid utility

**Files:**
- Create: `hrms_app/lib/utils/calendar_grid.dart`
- Create: `hrms_app/test/calendar_grid_test.dart`

**Interfaces:**
- Produces: `List<int?> buildMonthGrid(int year, int month)` — a
  Monday-first calendar grid, `null` for padding cells before the 1st and
  after the last day of the month, always a multiple of 7 in length.
  Also produces `const List<String> monthNames` (12 entries,
  `monthNames[0] == 'January'`). Consumed by Task 5.

- [ ] **Step 1: Write the failing test**

  Create `hrms_app/test/calendar_grid_test.dart`:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:hrms_app/utils/calendar_grid.dart';

  void main() {
    test('buildMonthGrid pads to a multiple of 7 and contains every day exactly once', () {
      final cells = buildMonthGrid(2026, 6);
      final daysInMonth = DateTime(2026, 7, 0).day;

      expect(cells.length % 7, 0);
      final nonNull = cells.whereType<int>().toList();
      expect(nonNull.length, daysInMonth);
      expect(nonNull.first, 1);
      expect(nonNull.last, daysInMonth);
      expect(nonNull.toSet().length, daysInMonth);
    });

    test('buildMonthGrid works for a different year/month too', () {
      final cells = buildMonthGrid(2027, 2);
      final daysInMonth = DateTime(2027, 3, 0).day;

      expect(cells.length % 7, 0);
      final nonNull = cells.whereType<int>().toList();
      expect(nonNull.length, daysInMonth);
      expect(nonNull.first, 1);
      expect(nonNull.last, daysInMonth);
    });

    test('monthNames has 12 entries starting with January', () {
      expect(monthNames.length, 12);
      expect(monthNames.first, 'January');
      expect(monthNames[5], 'June');
    });
  }
  ```

- [ ] **Step 2: Run the test to verify it fails**

  Run: `flutter test test/calendar_grid_test.dart`
  Expected: FAIL — `lib/utils/calendar_grid.dart` doesn't exist yet.

- [ ] **Step 3: Write the utility**

  Create `hrms_app/lib/utils/calendar_grid.dart`:
  ```dart
  const List<String> monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// Builds a Monday-first calendar grid for [year]/[month]. Returns a flat
  /// list of day numbers (1..daysInMonth) padded with `null` before the 1st
  /// and after the last day, so the list length is always a multiple of 7
  /// (ready to feed straight into a 7-column grid).
  List<int?> buildMonthGrid(int year, int month) {
    final firstOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final leadingBlanks = firstOfMonth.weekday - DateTime.monday;

    final cells = <int?>[
      ...List<int?>.filled(leadingBlanks, null),
      ...List<int?>.generate(daysInMonth, (i) => i + 1),
    ];

    final trailingBlanks = (7 - (cells.length % 7)) % 7;
    cells.addAll(List<int?>.filled(trailingBlanks, null));
    return cells;
  }
  ```

- [ ] **Step 4: Run the test to verify it passes**

  Run: `flutter test test/calendar_grid_test.dart`
  Expected: PASS (all 3 tests)

- [ ] **Step 5: Verify analyzer is clean**

  Run: `flutter analyze`
  Expected: `No issues found!`

- [ ] **Step 6: Commit**

  ```
  cd C:\Projects\HRMS
  git add hrms_app/lib/utils/calendar_grid.dart hrms_app/test/calendar_grid_test.dart
  git commit -m "Add calendar grid utility for the team calendar"
  ```

---

### Task 4: Extend AppState with Leave data getters

**Files:**
- Modify: `hrms_app/lib/state/app_state.dart`

**Interfaces:**
- Consumes: `FakeData` (Task 2); `Approver`, `LeaveRequest`,
  `TeamAbsence` (Task 1).
- Produces: `AppState.upcomingHolidayLabel`, `AppState.teamCalendarYear`,
  `AppState.teamCalendarMonth`, `AppState.teamCalendarTodayDay`,
  `AppState.teamCalendarDayColors`, `AppState.teamAbsences`,
  `AppState.myLeaveRequests`. Consumed by Task 10.

- [ ] **Step 1: Add the imports and getters**

  In `hrms_app/lib/state/app_state.dart`:
  1. Add `import 'package:flutter/material.dart';` alongside the existing
     `import 'package:flutter/foundation.dart';` (needed for the `Color`
     type used by `teamCalendarDayColors`).
  2. Add these three model imports:
     ```dart
     import '../models/team_absence.dart';
     import '../models/leave_request.dart';
     ```
     (`Approver` doesn't need a direct import here — it's only used
     transitively via `LeaveRequest`.)
  3. Add these getters inside the `AppState` class, after the existing
     `announcements` getter:
     ```dart
       String get upcomingHolidayLabel => FakeData.upcomingHolidayLabel;
       int get teamCalendarYear => FakeData.teamCalendarYear;
       int get teamCalendarMonth => FakeData.teamCalendarMonth;
       int get teamCalendarTodayDay => FakeData.teamCalendarTodayDay;
       Map<int, List<Color>> get teamCalendarDayColors => FakeData.teamCalendarDayColors;
       List<TeamAbsence> get teamAbsences => FakeData.teamAbsences;
       List<LeaveRequest> get myLeaveRequests => FakeData.myLeaveRequests;
     ```

- [ ] **Step 2: Verify it compiles and existing tests still pass**

  Run: `flutter analyze`
  Expected: `No issues found!`

  Run: `flutter test`
  Expected: all existing tests still passing (13 from Phases 1-3, plus the
  3 new `calendar_grid_test.dart` tests from Task 3 = 16 total).

- [ ] **Step 3: Commit**

  ```
  cd C:\Projects\HRMS
  git add hrms_app/lib/state/app_state.dart
  git commit -m "Add Leave tab data getters to AppState"
  ```

---

### Task 5: Team calendar card widget

**Files:**
- Create: `hrms_app/lib/widgets/team_calendar_card.dart`

**Interfaces:**
- Consumes: `buildMonthGrid`, `monthNames` (Task 3); `AppColors`.
- Produces: `TeamCalendarCard({required int year, required int month,
  required int todayDay, required Map<int, List<Color>> dayColors})`.
  Consumed by Task 10.

- [ ] **Step 1: Write TeamCalendarCard**

  Create `hrms_app/lib/widgets/team_calendar_card.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import '../theme/app_theme.dart';
  import '../utils/calendar_grid.dart';

  /// Team leave calendar: month grid with a highlighted "today" and small
  /// colored dots under any day someone on the team is away. Month
  /// navigation arrows are visual only for this phase (no month-switching
  /// logic yet).
  class TeamCalendarCard extends StatelessWidget {
    final int year;
    final int month;
    final int todayDay;
    final Map<int, List<Color>> dayColors;

    const TeamCalendarCard({
      super.key,
      required this.year,
      required this.month,
      required this.todayDay,
      required this.dayColors,
    });

    @override
    Widget build(BuildContext context) {
      final cells = buildMonthGrid(year, month);
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const _NavButton(icon: Icons.chevron_left),
                  Text(
                    '${monthNames[month - 1]} $year',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const _NavButton(icon: Icons.chevron_right),
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
                childAspectRatio: 0.85,
                children: cells.map((day) {
                  if (day == null) return const SizedBox.shrink();
                  final isToday = day == todayDay;
                  final dots = dayColors[day] ?? const <Color>[];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isToday ? AppColors.primary : Colors.transparent,
                          ),
                          child: Text(
                            '$day',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: isToday ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        SizedBox(
                          height: 5,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: dots
                                .map(
                                  (c) => Container(
                                    width: 5,
                                    height: 5,
                                    margin: const EdgeInsets.symmetric(horizontal: 1),
                                    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 12),
              const Row(
                children: [
                  _LegendItem(color: AppColors.primary, label: 'Annual'),
                  SizedBox(width: 14),
                  _LegendItem(color: AppColors.warning, label: 'Sick'),
                  SizedBox(width: 14),
                  _LegendItem(color: Color(0xFF8B5CF6), label: 'Personal'),
                ],
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

    const _NavButton({required this.icon});

    @override
    Widget build(BuildContext context) {
      return Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, size: 16, color: AppColors.textSecondary),
      );
    }
  }

  class _LegendItem extends StatelessWidget {
    final Color color;
    final String label;

    const _LegendItem({required this.color, required this.label});

    @override
    Widget build(BuildContext context) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        ],
      );
    }
  }
  ```

- [ ] **Step 2: Verify it compiles**

  Run: `flutter analyze`
  Expected: `No issues found!`

- [ ] **Step 3: Commit**

  ```
  cd C:\Projects\HRMS
  git add hrms_app/lib/widgets/team_calendar_card.dart
  git commit -m "Add TeamCalendarCard widget"
  ```

---

### Task 6: Who's away list widget

**Files:**
- Create: `hrms_app/lib/widgets/whos_away_list.dart`

**Interfaces:**
- Consumes: `TeamAbsence` (Task 1); `AppColors`.
- Produces: `WhosAwayList({required List<TeamAbsence> absences})`.
  Consumed by Task 10.

- [ ] **Step 1: Write WhosAwayList**

  Create `hrms_app/lib/widgets/whos_away_list.dart`:
  ```dart
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
  ```

- [ ] **Step 2: Verify it compiles**

  Run: `flutter analyze`
  Expected: `No issues found!`

- [ ] **Step 3: Commit**

  ```
  cd C:\Projects\HRMS
  git add hrms_app/lib/widgets/whos_away_list.dart
  git commit -m "Add WhosAwayList widget"
  ```

---

### Task 7: My requests list widget

**Files:**
- Create: `hrms_app/lib/widgets/my_requests_list.dart`

**Interfaces:**
- Consumes: `LeaveRequest` (Task 1); `AppColors`.
- Produces: `MyRequestsList({required List<LeaveRequest> requests,
  required VoidCallback onViewAll, required ValueChanged<LeaveRequest>
  onRequestTap})` — shows the first 3 requests, each row calling
  `onRequestTap` with itself when tapped. Consumed by Task 10.

- [ ] **Step 1: Write MyRequestsList**

  Create `hrms_app/lib/widgets/my_requests_list.dart`:
  ```dart
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
  ```

- [ ] **Step 2: Verify it compiles**

  Run: `flutter analyze`
  Expected: `No issues found!`

- [ ] **Step 3: Commit**

  ```
  cd C:\Projects\HRMS
  git add hrms_app/lib/widgets/my_requests_list.dart
  git commit -m "Add MyRequestsList widget"
  ```

---

### Task 8: Leave History sub-page with filter chips

**Files:**
- Create: `hrms_app/lib/screens/leave/leave_history_screen.dart`
- Create: `hrms_app/test/leave_history_screen_test.dart`

**Interfaces:**
- Consumes: `LeaveRequest` (Task 1); `LeaveRequestDetailScreen` (Task 9 —
  see note below on task ordering).
- Produces: `LeaveHistoryScreen({required List<LeaveRequest> requests})`.
  Consumed by Task 10. Internally manages `_selectedFilter` (page-local
  state), and navigates directly to `LeaveRequestDetailScreen` when a row
  is tapped (screens may self-navigate to sibling screens, per this app's
  established convention).

**Note on task ordering:** this task's code imports
`leave_request_detail_screen.dart`, which Task 9 creates. Implement Task 9
(`LeaveRequestDetailScreen`) **before** this task if working out of plan
order, or create a minimal placeholder first — but since this plan is
executed in order, Task 9 comes right after this one. **To keep each task
buildable/testable in isolation, do the two navigation-target files this
way:** write this task's `LeaveHistoryScreen` first without the tap
navigation wired (just render the list), verify and commit; Task 9 will
both create `LeaveRequestDetailScreen` AND add the navigation wiring back
into `LeaveHistoryScreen` as part of its own commit. This keeps every
commit buildable on its own.

- [ ] **Step 1: Write the failing test**

  Create `hrms_app/test/leave_history_screen_test.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:hrms_app/models/leave_request.dart';
  import 'package:hrms_app/screens/leave/leave_history_screen.dart';
  import 'package:hrms_app/theme/app_theme.dart';

  const _requests = [
    LeaveRequest(
      type: 'Annual Leave',
      dateRangeLabel: 'Jul 14 – 16 · 3 days',
      status: 'Pending',
      statusColor: AppColors.warning,
      statusBg: AppColors.warningTint,
      reason: 'Family trip.',
      approvers: <Approver>[],
    ),
    LeaveRequest(
      type: 'Medical Leave',
      dateRangeLabel: 'Jun 3 · 1 day',
      status: 'Approved',
      statusColor: AppColors.primary,
      statusBg: AppColors.primaryTint,
      reason: 'Flu recovery.',
      approvers: <Approver>[],
    ),
  ];

  void main() {
    testWidgets('shows all requests by default, filters when a chip is tapped', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: LeaveHistoryScreen(requests: _requests)),
      );

      expect(find.text('Annual Leave'), findsOneWidget);
      expect(find.text('Medical Leave'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Approved'));
      await tester.pumpAndSettle();

      expect(find.text('Annual Leave'), findsNothing);
      expect(find.text('Medical Leave'), findsOneWidget);
    });
  }
  ```
  (`Approver` needs `import 'package:hrms_app/models/approver.dart';`
  added to the test file's imports for the `<Approver>[]` list literal to
  resolve.)

- [ ] **Step 2: Run the test to verify it fails**

  Run: `flutter test test/leave_history_screen_test.dart`
  Expected: FAIL — `LeaveHistoryScreen` doesn't exist yet.

- [ ] **Step 3: Write LeaveHistoryScreen (without detail navigation yet)**

  Create `hrms_app/lib/screens/leave/leave_history_screen.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import '../../models/leave_request.dart';
  import '../../theme/app_theme.dart';

  class LeaveHistoryScreen extends StatefulWidget {
    final List<LeaveRequest> requests;

    const LeaveHistoryScreen({super.key, required this.requests});

    @override
    State<LeaveHistoryScreen> createState() => _LeaveHistoryScreenState();
  }

  class _LeaveHistoryScreenState extends State<LeaveHistoryScreen> {
    static const _filters = ['All', 'Approved', 'Pending', 'Rejected'];
    String _selectedFilter = 'All';

    @override
    Widget build(BuildContext context) {
      final filtered = _selectedFilter == 'All'
          ? widget.requests
          : widget.requests.where((r) => r.status == _selectedFilter).toList();

      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          foregroundColor: AppColors.textPrimary,
          title: const Text(
            'Leave History',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Wrap(
              spacing: 8,
              children: _filters
                  .map(
                    (f) => ChoiceChip(
                      label: Text(f),
                      selected: _selectedFilter == f,
                      onSelected: (_) => setState(() => _selectedFilter = f),
                      selectedColor: AppColors.primaryTint,
                      labelStyle: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: _selectedFilter == f ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 18),
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'No $_selectedFilter records in 2026.',
                    style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                ),
              )
            else
              ...filtered.map(
                (r) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(color: AppColors.primaryTint, borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.event_note_outlined, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
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
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }
  }
  ```

- [ ] **Step 4: Run the test to verify it passes**

  Run: `flutter test test/leave_history_screen_test.dart`
  Expected: PASS

- [ ] **Step 5: Verify analyzer is clean**

  Run: `flutter analyze`
  Expected: `No issues found!`

- [ ] **Step 6: Commit**

  ```
  cd C:\Projects\HRMS
  git add hrms_app/lib/screens/leave/leave_history_screen.dart hrms_app/test/leave_history_screen_test.dart
  git commit -m "Add LeaveHistoryScreen with filter chips"
  ```

---

### Task 9: Leave Request Detail sub-page (and wire history navigation)

**Files:**
- Create: `hrms_app/lib/screens/leave/leave_request_detail_screen.dart`
- Create: `hrms_app/test/leave_request_detail_screen_test.dart`
- Modify: `hrms_app/lib/screens/leave/leave_history_screen.dart` (wrap
  each request row in `InkWell` that pushes `LeaveRequestDetailScreen`)

**Interfaces:**
- Consumes: `LeaveRequest`, `Approver` (Task 1).
- Produces: `LeaveRequestDetailScreen({required LeaveRequest request})`.
  Consumed by Task 10 (from `LeaveScreen`, via `MyRequestsList`'s
  `onRequestTap`) and by this task's own update to
  `LeaveHistoryScreen`.

- [ ] **Step 1: Write the failing test**

  Create `hrms_app/test/leave_request_detail_screen_test.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:hrms_app/models/approver.dart';
  import 'package:hrms_app/models/leave_request.dart';
  import 'package:hrms_app/screens/leave/leave_request_detail_screen.dart';
  import 'package:hrms_app/theme/app_theme.dart';

  void main() {
    testWidgets('shows request info, waiting banner, and approval progress', (tester) async {
      const request = LeaveRequest(
        type: 'Annual Leave',
        dateRangeLabel: 'Jul 14 – 16 · 3 days',
        status: 'Pending',
        statusColor: AppColors.warning,
        statusBg: AppColors.warningTint,
        reason: 'Family trip.',
        approvers: [
          Approver(
            initials: 'ML',
            tint: Color(0xFFDBEAFE),
            color: Color(0xFF1D4ED8),
            name: 'Marcus Lee',
            role: 'Design Lead · 1st approver',
            status: 'Pending',
            badgeBg: AppColors.warningTint,
            badgeColor: AppColors.warning,
            when: '—',
          ),
        ],
      );

      await tester.pumpWidget(
        const MaterialApp(home: LeaveRequestDetailScreen(request: request)),
      );

      expect(find.text('Annual Leave'), findsOneWidget);
      expect(find.text('Waiting on Marcus Lee to approve'), findsOneWidget);
      expect(find.text('Family trip.'), findsOneWidget);
      expect(find.text('Marcus Lee'), findsWidgets);
    });
  }
  ```

- [ ] **Step 2: Run the test to verify it fails**

  Run: `flutter test test/leave_request_detail_screen_test.dart`
  Expected: FAIL — `LeaveRequestDetailScreen` doesn't exist yet.

- [ ] **Step 3: Write LeaveRequestDetailScreen**

  Create `hrms_app/lib/screens/leave/leave_request_detail_screen.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import '../../models/approver.dart';
  import '../../models/leave_request.dart';
  import '../../theme/app_theme.dart';

  class LeaveRequestDetailScreen extends StatelessWidget {
    final LeaveRequest request;

    const LeaveRequestDetailScreen({super.key, required this.request});

    @override
    Widget build(BuildContext context) {
      String? pendingApprover;
      if (request.status == 'Pending') {
        for (final a in request.approvers) {
          if (a.status == 'Pending') {
            pendingApprover = a.name;
            break;
          }
        }
      }

      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          foregroundColor: AppColors.textPrimary,
          title: const Text(
            'Request details',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                request.type,
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                request.dateRangeLabel,
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: request.statusBg, borderRadius: BorderRadius.circular(999)),
                          child: Text(
                            request.status,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: request.statusColor),
                          ),
                        ),
                      ],
                    ),
                    if (pendingApprover != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                        decoration: BoxDecoration(color: AppColors.warningTint, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, size: 17, color: Color(0xFFB45309)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Waiting on $pendingApprover to approve',
                                style: const TextStyle(fontSize: 12.5, color: Color(0xFF92400E), fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (request.reason.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Remarks', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Text(
                    request.reason,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.5),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text('Approval progress', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                child: Column(
                  children: [
                    for (var i = 0; i < request.approvers.length; i++)
                      _ApproverRow(
                        approver: request.approvers[i],
                        showConnector: i < request.approvers.length - 1,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  class _ApproverRow extends StatelessWidget {
    final Approver approver;
    final bool showConnector;

    const _ApproverRow({required this.approver, required this.showConnector});

    @override
    Widget build(BuildContext context) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: approver.tint, borderRadius: BorderRadius.circular(11)),
                alignment: Alignment.center,
                child: Text(
                  approver.initials,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: approver.color),
                ),
              ),
              if (showConnector) Container(width: 2, height: 24, color: const Color(0xFFEEF2F6)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: showConnector ? 14 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        approver.name,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: approver.badgeBg, borderRadius: BorderRadius.circular(999)),
                        child: Text(
                          approver.status,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: approver.badgeColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(approver.role, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 2),
                  Text(approver.when, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
          ),
        ],
      );
    }
  }
  ```

- [ ] **Step 4: Run the test to verify it passes**

  Run: `flutter test test/leave_request_detail_screen_test.dart`
  Expected: PASS

- [ ] **Step 5: Wire navigation from LeaveHistoryScreen**

  In `hrms_app/lib/screens/leave/leave_history_screen.dart`:
  1. Add the import: `import 'leave_request_detail_screen.dart';`
  2. Wrap the existing `Card(...)` for each request (inside the
     `...filtered.map(...)` block) with an `InkWell` so tapping it
     navigates to the detail screen. Replace:
     ```dart
                 (r) => Card(
                   margin: const EdgeInsets.only(bottom: 10),
                   child: Padding(
     ```
     with:
     ```dart
                 (r) => Card(
                   margin: const EdgeInsets.only(bottom: 10),
                   child: InkWell(
                     borderRadius: BorderRadius.circular(14),
                     onTap: () => Navigator.of(context).push(
                       MaterialPageRoute(builder: (_) => LeaveRequestDetailScreen(request: r)),
                     ),
                     child: Padding(
     ```
     ...and close the new `InkWell(` with an extra `)` right after the
     existing `Padding(...)`'s closing, before the `Card`'s closing `)`
     (i.e. `Padding(...)` becomes the `InkWell`'s `child`, and the
     `InkWell` becomes the `Card`'s `child`).

- [ ] **Step 6: Run both leave test files and the analyzer**

  Run: `flutter test test/leave_history_screen_test.dart test/leave_request_detail_screen_test.dart`
  Expected: PASS (both files' tests)

  Run: `flutter analyze`
  Expected: `No issues found!`

- [ ] **Step 7: Commit**

  ```
  cd C:\Projects\HRMS
  git add hrms_app/lib/screens/leave/leave_request_detail_screen.dart hrms_app/test/leave_request_detail_screen_test.dart hrms_app/lib/screens/leave/leave_history_screen.dart
  git commit -m "Add LeaveRequestDetailScreen and wire history navigation to it"
  ```

---

### Task 10: Assemble the real LeaveScreen

**Files:**
- Modify: `hrms_app/lib/screens/leave/leave_screen.dart` (replaces the
  Phase 1 placeholder entirely)
- Create: `hrms_app/test/leave_screen_test.dart`

**Interfaces:**
- Consumes: `AppState` (Task 4, via `context.watch<AppState>()`);
  `TeamCalendarCard` (Task 5); `WhosAwayList` (Task 6); `MyRequestsList`
  (Task 7); `LeaveHistoryScreen` (Task 8); `LeaveRequestDetailScreen`
  (Task 9).

- [ ] **Step 1: Write the failing tests**

  Create `hrms_app/test/leave_screen_test.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:provider/provider.dart';
  import 'package:hrms_app/screens/leave/leave_screen.dart';
  import 'package:hrms_app/state/app_state.dart';

  void main() {
    testWidgets('LeaveScreen shows holiday banner, calendar, and requests', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AppState(),
          child: const MaterialApp(home: Scaffold(body: LeaveScreen())),
        ),
      );

      expect(find.text('Leave'), findsOneWidget);
      expect(find.text('Team calendar'), findsOneWidget);
      expect(find.text("Who's away this week"), findsOneWidget);
      expect(find.text('My requests'), findsOneWidget);
    });

    testWidgets('Tapping a request opens its detail page', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AppState(),
          child: const MaterialApp(home: Scaffold(body: LeaveScreen())),
        ),
      );

      await tester.tap(find.text('Annual Leave').first);
      await tester.pumpAndSettle();

      expect(find.text('Request details'), findsOneWidget);
    });

    testWidgets('Tapping the history icon opens Leave History', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AppState(),
          child: const MaterialApp(home: Scaffold(body: LeaveScreen())),
        ),
      );

      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      expect(find.text('Leave History'), findsOneWidget);
    });
  }
  ```

- [ ] **Step 2: Run the tests to verify they fail**

  Run: `flutter test test/leave_screen_test.dart`
  Expected: FAIL — the placeholder `LeaveScreen` only shows centered
  "Leave" text.

- [ ] **Step 3: Replace LeaveScreen with the real screen**

  Replace the entire contents of `hrms_app/lib/screens/leave/leave_screen.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:provider/provider.dart';
  import '../../models/leave_request.dart';
  import '../../state/app_state.dart';
  import '../../theme/app_theme.dart';
  import '../../widgets/my_requests_list.dart';
  import '../../widgets/team_calendar_card.dart';
  import '../../widgets/whos_away_list.dart';
  import 'leave_history_screen.dart';
  import 'leave_request_detail_screen.dart';

  class LeaveScreen extends StatelessWidget {
    const LeaveScreen({super.key});

    void _openRequestDetail(BuildContext context, LeaveRequest request) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => LeaveRequestDetailScreen(request: request)),
      );
    }

    @override
    Widget build(BuildContext context) {
      final appState = context.watch<AppState>();
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Leave',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => LeaveHistoryScreen(requests: appState.myLeaveRequests),
                          ),
                        ),
                        icon: const Icon(Icons.history, size: 20, color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 16, color: Colors.white),
                          SizedBox(width: 6),
                          Text('Request', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.primaryTint, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.event_note_outlined, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Upcoming holiday',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        Text(
                          appState.upcomingHolidayLabel,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Text('Team calendar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            TeamCalendarCard(
              year: appState.teamCalendarYear,
              month: appState.teamCalendarMonth,
              todayDay: appState.teamCalendarTodayDay,
              dayColors: appState.teamCalendarDayColors,
            ),
            const SizedBox(height: 22),
            WhosAwayList(absences: appState.teamAbsences),
            const SizedBox(height: 22),
            MyRequestsList(
              requests: appState.myLeaveRequests,
              onViewAll: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LeaveHistoryScreen(requests: appState.myLeaveRequests),
                ),
              ),
              onRequestTap: (r) => _openRequestDetail(context, r),
            ),
          ],
        ),
      );
    }
  }
  ```

- [ ] **Step 4: Run the tests to verify they pass**

  Run: `flutter test test/leave_screen_test.dart`
  Expected: PASS (all 3 tests)

- [ ] **Step 5: Run the full test suite and analyzer**

  Run: `flutter test`
  Expected: all tests passing — 13 from Phases 1-3, 3 from
  `calendar_grid_test.dart`, 1 from `leave_history_screen_test.dart`, 1
  from `leave_request_detail_screen_test.dart`, and 3 from
  `leave_screen_test.dart` = 21 total.

  Run: `flutter analyze`
  Expected: `No issues found!`

- [ ] **Step 6: Build for web as a visual sanity check**

  Run: `flutter build web`
  Expected: builds successfully with no errors.

- [ ] **Step 7: Commit**

  ```
  cd C:\Projects\HRMS
  git add hrms_app/lib/screens/leave/leave_screen.dart hrms_app/test/leave_screen_test.dart
  git commit -m "Assemble the real Leave screen with calendar and requests"
  ```

---

## Definition of done for Phase 4

- [ ] `flutter analyze` reports no issues
- [ ] `flutter test` passes all 21 tests
- [ ] `flutter build web` succeeds
- [ ] The Leave tab shows: upcoming holiday banner, a real team calendar
      with today highlighted and colored dots for teammates who are away,
      "who's away this week", and "my requests" with a working "View all"
      link to a filterable Leave History page
- [ ] Tapping any request (from the main screen or history) opens its
      detail page showing the approval-progress timeline
- [ ] All work is committed to `main` in `C:\Projects\HRMS`

Once this is verified, the next plan (Phase 5) will build the leave
*request creation* flow (type picker → form → submission → confirmation)
deferred from this phase, plus the "Me"/profile tab.
