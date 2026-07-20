# HRMS Mobile App — Phase 2: Home Tab Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the Home tab's placeholder with the real dashboard from the
mockup — greeting header, clock-in status card, quick-action icons, a weekly
attendance-hours bar chart, a leave-balance summary with a circular progress
ring, and an announcements list — all driven by hardcoded fake data via a
shared `AppState`.

**Architecture:** Small `StatelessWidget`s under `lib/widgets/`, each taking
plain data-model objects as constructor parameters (no direct `Provider`
coupling inside the widgets themselves). `HomeScreen` is the only place that
reads from `AppState` (via `provider`) and passes data down. `AppState`
(a `ChangeNotifier`) is created once at the app root in `app.dart` and reads
from `lib/data/fake_data.dart` at construction.

**Tech Stack:** Flutter/Dart, `provider` (already a dependency from Phase 1),
Flutter's built-in `CircularProgressIndicator` for the leave-balance ring (no
charting package needed).

## Global Constraints

- Primary accent color: `#10B981` (`AppColors.primary`), gradient partner
  `#059669` (`AppColors.primaryDark`).
- Background `#F1F5F9` (`AppColors.background`). Text: primary `#0F172A`
  (`AppColors.textPrimary`), secondary `#64748B` (`AppColors.textSecondary`),
  muted `#94A3B8` (`AppColors.textMuted`). Danger `#EF4444`
  (`AppColors.danger`). Warning `#F59E0B` (`AppColors.warning`). Border
  `#E2E8F0` (`AppColors.border`). All already defined in
  `hrms_app/lib/theme/app_theme.dart` — import and reuse, do not redefine.
- Card style convention (already in `AppTheme.themeData.cardTheme`): white
  background, 16px border radius, soft shadow — use Flutter's `Card` widget
  (no manual `BoxDecoration` re-implementation of the card shell) so every
  card automatically matches.
- Currency/locale: not relevant to this phase (no money values on Home).
- All data is hardcoded/fake — no network calls, no async loading states.
- Widgets take data via constructor parameters, not by reading `Provider`
  internally — keeps them independently testable and reusable.
- Verification: `flutter analyze` clean, `flutter test` all passing. Android
  emulator is not available on this machine (known, separately-tracked
  environment bug) — do not attempt `flutter run` on Android; Chrome/web or
  widget tests are the verification path for this phase too.

---

### Task 1: Data models for the Home dashboard

**Files:**
- Create: `hrms_app/lib/models/employee.dart`
- Create: `hrms_app/lib/models/clock_status.dart`
- Create: `hrms_app/lib/models/day_hours.dart`
- Create: `hrms_app/lib/models/leave_balance.dart`
- Create: `hrms_app/lib/models/announcement.dart`

**Interfaces:**
- Produces: `Employee(name, initials)`, `ClockStatus(clockedIn, since,
  location, hoursWorkedToday)`, `DayHours(label, hours, highlighted)`,
  `LeaveBalance(type, used, total, color)` with a `remaining` getter,
  `Announcement(icon, title, subtitle)`. These exact class and field names
  are consumed by Tasks 2, 4, 6, 7, 8.

- [ ] **Step 1: Write the five model files**

  Create `hrms_app/lib/models/employee.dart`:
  ```dart
  class Employee {
    final String name;
    final String initials;

    const Employee({required this.name, required this.initials});
  }
  ```

  Create `hrms_app/lib/models/clock_status.dart`:
  ```dart
  class ClockStatus {
    final bool clockedIn;
    final String since;
    final String location;
    final String hoursWorkedToday;

    const ClockStatus({
      required this.clockedIn,
      required this.since,
      required this.location,
      required this.hoursWorkedToday,
    });
  }
  ```

  Create `hrms_app/lib/models/day_hours.dart`:
  ```dart
  class DayHours {
    final String label;
    final double hours;
    final bool highlighted;

    const DayHours({
      required this.label,
      required this.hours,
      this.highlighted = false,
    });
  }
  ```

  Create `hrms_app/lib/models/leave_balance.dart`:
  ```dart
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
  ```

  Create `hrms_app/lib/models/announcement.dart`:
  ```dart
  import 'package:flutter/material.dart';

  class Announcement {
    final IconData icon;
    final String title;
    final String subtitle;

    const Announcement({
      required this.icon,
      required this.title,
      required this.subtitle,
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
  git commit -m "Add data models for the Home dashboard"
  ```

---

### Task 2: Fake data for the Home dashboard

**Files:**
- Create: `hrms_app/lib/data/fake_data.dart`

**Interfaces:**
- Consumes: `Employee`, `ClockStatus`, `DayHours`, `LeaveBalance`,
  `Announcement` (Task 1); `AppColors` (`hrms_app/lib/theme/app_theme.dart`,
  already exists from Phase 1).
- Produces: `FakeData.employee`, `FakeData.clockStatus`,
  `FakeData.weeklyHours` (`List<DayHours>`), `FakeData.weeklyTotalHoursLabel`
  (`String`), `FakeData.weeklyChangeLabel` (`String`),
  `FakeData.leaveBalances` (`List<LeaveBalance>`), `FakeData.announcements`
  (`List<Announcement>`). Consumed by Task 3.

- [ ] **Step 1: Write the fake data file**

  Create `hrms_app/lib/data/fake_data.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import '../models/announcement.dart';
  import '../models/clock_status.dart';
  import '../models/day_hours.dart';
  import '../models/employee.dart';
  import '../models/leave_balance.dart';
  import '../theme/app_theme.dart';

  /// Hardcoded sample data matching the HRMS design mockup, standing in for
  /// a real backend until one exists.
  class FakeData {
    static const employee = Employee(name: 'Sarah Chen', initials: 'SC');

    static const clockStatus = ClockStatus(
      clockedIn: true,
      since: '09:02 AM',
      location: 'HQ Office',
      hoursWorkedToday: '6h 12m',
    );

    static const weeklyHours = [
      DayHours(label: 'Mon', hours: 7.9),
      DayHours(label: 'Tue', hours: 7.7),
      DayHours(label: 'Wed', hours: 7.2),
      DayHours(label: 'Thu', hours: 8.1),
      DayHours(label: 'Fri', hours: 5.9, highlighted: true),
    ];

    static const weeklyTotalHoursLabel = '38.3';
    static const weeklyChangeLabel = '+2.1h vs last wk';

    static const leaveBalances = [
      LeaveBalance(type: 'Annual', used: 12, total: 18, color: AppColors.primary),
      LeaveBalance(type: 'Sick', used: 5, total: 10, color: AppColors.primary),
      LeaveBalance(type: 'Personal', used: 2, total: 5, color: AppColors.warning),
    ];

    static const announcements = [
      Announcement(
        icon: Icons.notifications_none,
        title: 'Q3 Town Hall — all hands',
        subtitle: 'Jun 28 · 3:00 PM · Auditorium',
      ),
      Announcement(
        icon: Icons.check_circle_outline,
        title: 'New dental & vision benefits',
        subtitle: 'Now live · enrol by Jul 15',
      ),
    ];
  }
  ```

- [ ] **Step 2: Verify it compiles**

  Run: `flutter analyze`
  Expected: `No issues found!`

- [ ] **Step 3: Commit**

  ```
  cd C:\Projects\HRMS
  git add hrms_app/lib/data
  git commit -m "Add fake data for the Home dashboard"
  ```

---

### Task 3: AppState and Provider wiring

**Files:**
- Create: `hrms_app/lib/state/app_state.dart`
- Modify: `hrms_app/lib/app.dart`

**Interfaces:**
- Consumes: `FakeData` (Task 2); the `provider` package (already a
  dependency since Phase 1 Task 3).
- Produces: `AppState` (a `ChangeNotifier`) with getters `employee`,
  `clockStatus`, `weeklyHours`, `weeklyTotalHoursLabel`, `weeklyChangeLabel`,
  `leaveBalances`, `announcements` — same names/types as `FakeData`'s
  fields. Consumed by Task 9 (`HomeScreen`) via
  `context.watch<AppState>()`.

- [ ] **Step 1: Write AppState**

  Create `hrms_app/lib/state/app_state.dart`:
  ```dart
  import 'package:flutter/foundation.dart';
  import '../data/fake_data.dart';
  import '../models/announcement.dart';
  import '../models/clock_status.dart';
  import '../models/day_hours.dart';
  import '../models/employee.dart';
  import '../models/leave_balance.dart';

  /// Shared app state. Currently just exposes the hardcoded fake data;
  /// later phases will add methods here (clockIn(), submitLeaveRequest(),
  /// etc.) that mutate state and call notifyListeners().
  class AppState extends ChangeNotifier {
    Employee get employee => FakeData.employee;
    ClockStatus get clockStatus => FakeData.clockStatus;
    List<DayHours> get weeklyHours => FakeData.weeklyHours;
    String get weeklyTotalHoursLabel => FakeData.weeklyTotalHoursLabel;
    String get weeklyChangeLabel => FakeData.weeklyChangeLabel;
    List<LeaveBalance> get leaveBalances => FakeData.leaveBalances;
    List<Announcement> get announcements => FakeData.announcements;
  }
  ```

- [ ] **Step 2: Wire ChangeNotifierProvider into app.dart**

  In `hrms_app/lib/app.dart`, add the import and wrap `MaterialApp` with
  `ChangeNotifierProvider`. The full new file:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:provider/provider.dart';
  import 'state/app_state.dart';
  import 'theme/app_theme.dart';
  import 'screens/home/home_screen.dart';
  import 'screens/attendance/attendance_screen.dart';
  import 'screens/leave/leave_screen.dart';
  import 'screens/profile/profile_screen.dart';

  class HrmsApp extends StatelessWidget {
    const HrmsApp({super.key});

    @override
    Widget build(BuildContext context) {
      return ChangeNotifierProvider(
        create: (_) => AppState(),
        child: MaterialApp(
          title: 'HRMS',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.themeData,
          home: const MainTabShell(),
        ),
      );
    }
  }

  class MainTabShell extends StatefulWidget {
    const MainTabShell({super.key});

    @override
    State<MainTabShell> createState() => _MainTabShellState();
  }

  class _MainTabShellState extends State<MainTabShell> {
    int _selectedIndex = 0;

    static const _screens = [
      HomeScreen(),
      AttendanceScreen(),
      LeaveScreen(),
      ProfileScreen(),
    ];

    void _onTabTapped(int index) {
      setState(() => _selectedIndex = index);
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        body: SafeArea(
          child: IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onTabTapped,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.access_time_outlined), label: 'Attendance'),
            BottomNavigationBarItem(icon: Icon(Icons.event_note_outlined), label: 'Leave'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Me'),
          ],
        ),
      );
    }
  }
  ```
  (Only the `HrmsApp.build` method changed — `MainTabShell` is unchanged
  from Phase 1.)

- [ ] **Step 3: Verify it compiles and existing tests still pass**

  Run: `flutter analyze`
  Expected: `No issues found!`

  Run: `flutter test test/app_test.dart`
  Expected: all 5 tests still passing (adding the `Provider` wrapper above
  `MaterialApp` must not break the existing tab-switching tests, since they
  pump `HrmsApp` as a whole).

- [ ] **Step 4: Commit**

  ```
  cd C:\Projects\HRMS
  git add hrms_app/lib/state hrms_app/lib/app.dart
  git commit -m "Add AppState and wire ChangeNotifierProvider into the app root"
  ```

---

### Task 4: Header and clock-status-card widgets

**Files:**
- Create: `hrms_app/lib/widgets/home_header.dart`
- Create: `hrms_app/lib/widgets/clock_status_card.dart`

**Interfaces:**
- Consumes: `Employee`, `ClockStatus` (Task 1); `AppColors` (Phase 1).
- Produces: `HomeHeader({required Employee employee})` and
  `ClockStatusCard({required ClockStatus status})`, both
  `StatelessWidget`s with no other constructor parameters. Consumed by
  Task 9.

- [ ] **Step 1: Write HomeHeader**

  Create `hrms_app/lib/widgets/home_header.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import '../models/employee.dart';
  import '../theme/app_theme.dart';

  /// Top-of-Home greeting: avatar initials, "Good morning, <name>", and a
  /// notification bell with an unread-dot badge.
  class HomeHeader extends StatelessWidget {
    final Employee employee;

    const HomeHeader({super.key, required this.employee});

    @override
    Widget build(BuildContext context) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  employee.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Good morning,',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    employee.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: AppColors.border),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Center(
                  child: Icon(
                    Icons.notifications_none,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 9,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }
  ```

- [ ] **Step 2: Write ClockStatusCard**

  Create `hrms_app/lib/widgets/clock_status_card.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import '../models/clock_status.dart';
  import '../theme/app_theme.dart';

  /// Card showing today's clock-in status and hours worked so far.
  class ClockStatusCard extends StatelessWidget {
    final ClockStatus status;

    const ClockStatusCard({super.key, required this.status});

    @override
    Widget build(BuildContext context) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status.clockedIn ? 'Clocked in' : 'Not clocked in',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Since ${status.since} · ${status.location}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    status.hoursWorkedToday,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Text(
                    'worked today',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
  }
  ```

- [ ] **Step 3: Verify it compiles**

  Run: `flutter analyze`
  Expected: `No issues found!`

- [ ] **Step 4: Commit**

  ```
  cd C:\Projects\HRMS
  git add hrms_app/lib/widgets/home_header.dart hrms_app/lib/widgets/clock_status_card.dart
  git commit -m "Add HomeHeader and ClockStatusCard widgets"
  ```

---

### Task 5: Quick actions row widget

**Files:**
- Create: `hrms_app/lib/widgets/quick_actions_row.dart`

**Interfaces:**
- Consumes: `AppColors` (Phase 1).
- Produces: `QuickActionsRow` (`StatelessWidget`, no constructor
  parameters — the four actions are fixed for this phase). Consumed by
  Task 9.
- Out of scope for this phase: the four icons (Attendance, Leave, Claims,
  Payslip) are display-only and not tappable yet — wiring them to real
  navigation (switching tabs, or to screens that don't exist until later
  phases) is deferred to a future phase to avoid reaching into
  `MainTabShell`'s navigation state prematurely.

- [ ] **Step 1: Write QuickActionsRow**

  Create `hrms_app/lib/widgets/quick_actions_row.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import '../theme/app_theme.dart';

  class _QuickAction {
    final IconData icon;
    final String label;

    const _QuickAction(this.icon, this.label);
  }

  /// Row of four icon shortcuts shown on Home: Attendance, Leave, Claims,
  /// Payslip. Display-only for now — see plan for why they're not wired to
  /// navigation yet.
  class QuickActionsRow extends StatelessWidget {
    const QuickActionsRow({super.key});

    static const _actions = [
      _QuickAction(Icons.access_time_outlined, 'Attendance'),
      _QuickAction(Icons.event_note_outlined, 'Leave'),
      _QuickAction(Icons.receipt_long_outlined, 'Claims'),
      _QuickAction(Icons.credit_card_outlined, 'Payslip'),
    ];

    @override
    Widget build(BuildContext context) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: _actions
            .map(
              (action) => Column(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(action.icon, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    action.label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
            .toList(),
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
  git add hrms_app/lib/widgets/quick_actions_row.dart
  git commit -m "Add QuickActionsRow widget"
  ```

---

### Task 6: Weekly hours bar chart widget

**Files:**
- Create: `hrms_app/lib/widgets/weekly_hours_chart.dart`

**Interfaces:**
- Consumes: `DayHours` (Task 1); `AppColors` (Phase 1).
- Produces: `WeeklyHoursChart({required List<DayHours> days, required
  String totalLabel, required String changeLabel})`. Consumed by Task 9.

- [ ] **Step 1: Write WeeklyHoursChart**

  Create `hrms_app/lib/widgets/weekly_hours_chart.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import '../models/day_hours.dart';
  import '../theme/app_theme.dart';

  /// Card showing this week's attendance hours as a simple bar chart, with
  /// a total-hours summary above it.
  class WeeklyHoursChart extends StatelessWidget {
    final List<DayHours> days;
    final String totalLabel;
    final String changeLabel;

    const WeeklyHoursChart({
      super.key,
      required this.days,
      required this.totalLabel,
      required this.changeLabel,
    });

    @override
    Widget build(BuildContext context) {
      final maxHours = days.map((d) => d.hours).reduce((a, b) => a > b ? a : b);
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This week',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Attendance hours',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$totalLabel hrs',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        changeLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: days
                    .map(
                      (day) => Expanded(
                        child: Column(
                          children: [
                            Container(
                              height: 90 * (day.hours / maxHours),
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              decoration: BoxDecoration(
                                color: day.highlighted
                                    ? const Color(0xFF6EE7B7)
                                    : AppColors.primary,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(8),
                                  bottom: Radius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              day.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: day.highlighted ? FontWeight.w700 : FontWeight.w600,
                                color: day.highlighted ? AppColors.primary : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
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
  git add hrms_app/lib/widgets/weekly_hours_chart.dart
  git commit -m "Add WeeklyHoursChart widget"
  ```

---

### Task 7: Leave balance card widget

**Files:**
- Create: `hrms_app/lib/widgets/leave_balance_card.dart`

**Interfaces:**
- Consumes: `LeaveBalance` (Task 1); `AppColors` (Phase 1).
- Produces: `LeaveBalanceCard({required List<LeaveBalance> balances})`.
  Consumed by Task 9. Assumes `balances` is non-empty and its first
  element is the one shown in the circular-progress ring (matches the
  mockup, where the ring reflects Annual leave).

- [ ] **Step 1: Write LeaveBalanceCard**

  Create `hrms_app/lib/widgets/leave_balance_card.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import '../models/leave_balance.dart';
  import '../theme/app_theme.dart';

  /// Card showing a circular-progress ring for the primary (first) leave
  /// balance, plus a list row for every balance passed in.
  class LeaveBalanceCard extends StatelessWidget {
    final List<LeaveBalance> balances;

    const LeaveBalanceCard({super.key, required this.balances});

    @override
    Widget build(BuildContext context) {
      final primary = balances.first;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 104,
                height: 104,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 104,
                      height: 104,
                      child: CircularProgressIndicator(
                        value: primary.remaining / primary.total,
                        strokeWidth: 11,
                        backgroundColor: const Color(0xFFEEF2F6),
                        valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${primary.remaining}',
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Text(
                          'days left',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Leave balance',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...balances.map(
                      (b) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(color: b.color, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                b.type,
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              ),
                            ),
                            Text(
                              '${b.remaining} / ${b.total}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
  git add hrms_app/lib/widgets/leave_balance_card.dart
  git commit -m "Add LeaveBalanceCard widget"
  ```

---

### Task 8: Announcements list widget

**Files:**
- Create: `hrms_app/lib/widgets/announcements_list.dart`

**Interfaces:**
- Consumes: `Announcement` (Task 1); `AppColors` (Phase 1).
- Produces: `AnnouncementsList({required List<Announcement>
  announcements})`. Consumed by Task 9.

- [ ] **Step 1: Write AnnouncementsList**

  Create `hrms_app/lib/widgets/announcements_list.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import '../models/announcement.dart';
  import '../theme/app_theme.dart';

  /// "Announcements" section: a header row with a "See all" link, followed
  /// by one card per announcement.
  class AnnouncementsList extends StatelessWidget {
    final List<Announcement> announcements;

    const AnnouncementsList({super.key, required this.announcements});

    @override
    Widget build(BuildContext context) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Announcements',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'See all',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...announcements.map(
            (a) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(a.icon, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            a.subtitle,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
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
  git add hrms_app/lib/widgets/announcements_list.dart
  git commit -m "Add AnnouncementsList widget"
  ```

---

### Task 9: Assemble the real HomeScreen

**Files:**
- Modify: `hrms_app/lib/screens/home/home_screen.dart` (replaces the
  Phase 1 placeholder entirely)
- Create: `hrms_app/test/home_screen_test.dart`

**Interfaces:**
- Consumes: `AppState` (Task 3, via `context.watch<AppState>()`);
  `HomeHeader`, `ClockStatusCard` (Task 4); `QuickActionsRow` (Task 5);
  `WeeklyHoursChart` (Task 6); `LeaveBalanceCard` (Task 7);
  `AnnouncementsList` (Task 8).

- [ ] **Step 1: Write the failing test**

  Create `hrms_app/test/home_screen_test.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:provider/provider.dart';
  import 'package:hrms_app/screens/home/home_screen.dart';
  import 'package:hrms_app/state/app_state.dart';

  void main() {
    testWidgets('HomeScreen shows dashboard content from AppState', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AppState(),
          child: const MaterialApp(home: Scaffold(body: HomeScreen())),
        ),
      );

      expect(find.text('Sarah Chen'), findsOneWidget);
      expect(find.text('Clocked in'), findsOneWidget);
      expect(find.text('Leave balance'), findsOneWidget);
      expect(find.text('Announcements'), findsOneWidget);
      expect(find.text('This week'), findsOneWidget);
    });
  }
  ```

- [ ] **Step 2: Run the test to verify it fails**

  Run: `flutter test test/home_screen_test.dart`
  Expected: FAIL — the placeholder `HomeScreen` only shows the text "Home",
  so none of the new assertions find their text yet.

- [ ] **Step 3: Replace HomeScreen with the real dashboard**

  Replace the entire contents of `hrms_app/lib/screens/home/home_screen.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:provider/provider.dart';
  import '../../state/app_state.dart';
  import '../../widgets/announcements_list.dart';
  import '../../widgets/clock_status_card.dart';
  import '../../widgets/home_header.dart';
  import '../../widgets/leave_balance_card.dart';
  import '../../widgets/quick_actions_row.dart';
  import '../../widgets/weekly_hours_chart.dart';

  class HomeScreen extends StatelessWidget {
    const HomeScreen({super.key});

    @override
    Widget build(BuildContext context) {
      final appState = context.watch<AppState>();
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeHeader(employee: appState.employee),
            const SizedBox(height: 20),
            ClockStatusCard(status: appState.clockStatus),
            const SizedBox(height: 18),
            const QuickActionsRow(),
            const SizedBox(height: 22),
            WeeklyHoursChart(
              days: appState.weeklyHours,
              totalLabel: appState.weeklyTotalHoursLabel,
              changeLabel: appState.weeklyChangeLabel,
            ),
            const SizedBox(height: 14),
            LeaveBalanceCard(balances: appState.leaveBalances),
            const SizedBox(height: 16),
            AnnouncementsList(announcements: appState.announcements),
          ],
        ),
      );
    }
  }
  ```

- [ ] **Step 4: Run the test to verify it passes**

  Run: `flutter test test/home_screen_test.dart`
  Expected: PASS

- [ ] **Step 5: Run the full test suite and analyzer**

  Run: `flutter test`
  Expected: all tests passing (both `test/app_test.dart` and the new
  `test/home_screen_test.dart`) — confirms the Phase 1 tab-switching tests
  still work with the real `HomeScreen` in place.

  Run: `flutter analyze`
  Expected: `No issues found!`

- [ ] **Step 6: Build for web as a visual sanity check**

  Run: `flutter build web`
  Expected: builds successfully with no errors — confirms the full widget
  tree (including `CircularProgressIndicator`, gradients, and the bar
  chart) compiles and renders without runtime type errors on a real
  target, not just in the analyzer.

- [ ] **Step 7: Commit**

  ```
  cd C:\Projects\HRMS
  git add hrms_app/lib/screens/home/home_screen.dart hrms_app/test/home_screen_test.dart
  git commit -m "Assemble the real Home dashboard from AppState and widgets"
  ```

---

## Definition of done for Phase 2

- [ ] `flutter analyze` reports no issues
- [ ] `flutter test` passes all tests (Phase 1's `app_test.dart` plus the
      new `home_screen_test.dart`)
- [ ] `flutter build web` succeeds
- [ ] The Home tab shows: greeting header with avatar, clock-in status
      card, four quick-action icons, a weekly-hours bar chart, a
      leave-balance card with a circular-progress ring, and an
      announcements list — all populated from `AppState`'s fake data
- [ ] All work is committed to `master` in `C:\Projects\HRMS`

Once this is verified, the next plan (Phase 3: Attendance tab) will build
out the clock-in/out screen and the face-check-in overlay, replacing the
`AttendanceScreen` placeholder.
