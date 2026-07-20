# Phase 5: Leave Request Creation + Profile Tab Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let a user pick a leave type, choose dates on a calendar, write a
reason, and submit a new leave request that immediately shows up (as
"Pending") in the Leave tab's "My requests" list — plus build out the
"Me" tab into a real Profile screen with a personal-information detail
page.

**Architecture:** Same feature-folder + Provider pattern as Phases 1-4.
New pure-function date-range formatter in `lib/utils/`, one new stateful
"dumb" calendar-picker widget in `lib/widgets/`, three new screens under
`lib/screens/leave/` for the request flow, and three new screens under
`lib/screens/profile/`. `AppState` grows one new mutating method,
`submitLeaveRequest()`, following the exact same
mutate-then-`notifyListeners()` pattern as `clockIn()`/`clockOut()`.

**Tech Stack:** Flutter (Dart), Provider for state, `flutter_test` for
widget/unit tests. No new packages.

## Global Constraints

- Frontend-only, no real backend — all data is hardcoded in `FakeData`,
  structured so a real backend can be swapped in later.
- Android builds are permanently blocked by an unresolved environment bug
  (`java.io.IOException: Unable to establish loopback connection`,
  JDK-8312215-class). Verification uses `flutter build web` +
  `flutter test`, never `flutter run` on Android, in this environment.
- TDD: write the failing test first, confirm it fails for the right
  reason, then write the minimal implementation, confirm green, commit.
  Never commit red.
- Widgets under `lib/widgets/` take data via constructor params + callbacks
  only — never import `lib/screens/*` or call `Navigator` directly.
  Screens may navigate to sibling/child screens themselves.
- Face check-in biometrics remain simulated (`local_auth` deferred,
  unrelated to this phase — noted here only for continuity).
- **This phase's own deferrals** (cut for scope/YAGNI, no backend to
  justify the complexity yet): no medical-certificate photo upload, no
  leave-category/duration (full-day vs half-day) toggle, no month-scoped
  leave-balance breakdown screen. The request form supports a single
  contiguous date range (or one single day) and a required reason only.
  Documents / Payslips / Settings on the Profile tab are placeholder
  "coming soon" screens — only Personal Information gets a real detail
  page this phase.
- Every subagent dispatch must include the git-safety instructions (no
  branch/remote changes, no `git push`) and the controller must verify
  `git branch --show-current && git remote -v` after each task.
- **Push policy:** ask the user for explicit confirmation before every
  `git push`, including force-pushes (flag the force-push risk
  explicitly when it applies).

---

### Task 1: Date-range label formatter

**Files:**
- Create: `hrms_app/lib/utils/date_range_label.dart`
- Test: `hrms_app/test/date_range_label_test.dart`

**Interfaces:**
- Produces: `const List<String> monthAbbr` (12 three-letter month
  abbreviations, `'Jan'`..`'Dec'`) and
  `String formatDateRangeLabel(DateTime start, DateTime end)` — both used
  by later tasks (calendar widget header reuses `monthNames` from
  `calendar_grid.dart`, not this file; the request form and `AppState`
  use `formatDateRangeLabel` and `monthAbbr`).

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_app/utils/date_range_label.dart';

void main() {
  test('same day returns a single-day label', () {
    expect(formatDateRangeLabel(DateTime(2026, 7, 14), DateTime(2026, 7, 14)), 'Jul 14 · 1 day');
  });

  test('same-month range returns a dash range with day count', () {
    expect(formatDateRangeLabel(DateTime(2026, 7, 14), DateTime(2026, 7, 16)), 'Jul 14 – 16 · 3 days');
  });

  test('cross-month range names both months', () {
    expect(formatDateRangeLabel(DateTime(2026, 7, 30), DateTime(2026, 8, 2)), 'Jul 30 – Aug 2 · 4 days');
  });

  test('monthAbbr has 12 three-letter entries starting with Jan', () {
    expect(monthAbbr.length, 12);
    expect(monthAbbr.first, 'Jan');
    expect(monthAbbr[6], 'Jul');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd hrms_app && flutter test test/date_range_label_test.dart`
Expected: FAIL — `date_range_label.dart` doesn't exist yet (compile error).

- [ ] **Step 3: Write minimal implementation**

```dart
const List<String> monthAbbr = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Formats a leave request's date span, e.g. "Jul 14 · 1 day" for a
/// single day or "Jul 14 – 16 · 3 days" for a range within one month.
String formatDateRangeLabel(DateTime start, DateTime end) {
  final days = end.difference(start).inDays + 1;
  final dayWord = days == 1 ? 'day' : 'days';

  if (start.year == end.year && start.month == end.month && start.day == end.day) {
    return '${monthAbbr[start.month - 1]} ${start.day} · $days $dayWord';
  }
  if (start.year == end.year && start.month == end.month) {
    return '${monthAbbr[start.month - 1]} ${start.day} – ${end.day} · $days $dayWord';
  }
  return '${monthAbbr[start.month - 1]} ${start.day} – ${monthAbbr[end.month - 1]} ${end.day} · $days $dayWord';
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd hrms_app && flutter test test/date_range_label_test.dart`
Expected: PASS (4 tests)

- [ ] **Step 5: Commit**

```bash
git add hrms_app/lib/utils/date_range_label.dart hrms_app/test/date_range_label_test.dart
git commit -m "feat: add date-range label formatter for leave requests"
```

---

### Task 2: Extend Employee model, add PersonalInfo model + fake data

**Files:**
- Modify: `hrms_app/lib/models/employee.dart`
- Create: `hrms_app/lib/models/personal_info.dart`
- Modify: `hrms_app/lib/data/fake_data.dart`

**Interfaces:**
- Consumes: nothing new.
- Produces: `Employee` now has `role`, `department`, `employeeId`,
  `employmentType` (all `String`, required) in addition to existing
  `name`/`initials`. New `PersonalInfo` class with fields:
  `dateOfBirth, gender, maritalStatus, nationality, nric, workEmail,
  mobile, address, emergencyContactName, emergencyContactRelationship,
  emergencyContactPhone, department, position, joinDate, employmentType,
  reportingTo, epfNumber, socsoNumber, incomeTaxNumber` (all `String`).
  `FakeData.employee` updated with the new fields, `FakeData.personalInfo`
  added, `FakeData.pendingApprovalChain` added as a public alias for the
  existing private `_approversPending` list (Task 3's `AppState` needs a
  public approvers list to expose for the request form's approval-flow
  preview). These are plain data classes — no dedicated unit test, same
  as `TeamAbsence`/`AttendanceRecord`; they're exercised by the screen
  widget tests in Tasks 9-10.

- [ ] **Step 1: Update the Employee model**

Replace the full contents of `hrms_app/lib/models/employee.dart`:

```dart
class Employee {
  final String name;
  final String initials;
  final String role;
  final String department;
  final String employeeId;
  final String employmentType;

  const Employee({
    required this.name,
    required this.initials,
    required this.role,
    required this.department,
    required this.employeeId,
    required this.employmentType,
  });
}
```

- [ ] **Step 2: Create the PersonalInfo model**

```dart
/// Static personal/employment/statutory details shown on the Profile
/// tab's "Personal information" screen. Read-only in this frontend-only
/// phase — editing is out of scope until there's a real backend.
class PersonalInfo {
  final String dateOfBirth;
  final String gender;
  final String maritalStatus;
  final String nationality;
  final String nric;
  final String workEmail;
  final String mobile;
  final String address;
  final String emergencyContactName;
  final String emergencyContactRelationship;
  final String emergencyContactPhone;
  final String department;
  final String position;
  final String joinDate;
  final String employmentType;
  final String reportingTo;
  final String epfNumber;
  final String socsoNumber;
  final String incomeTaxNumber;

  const PersonalInfo({
    required this.dateOfBirth,
    required this.gender,
    required this.maritalStatus,
    required this.nationality,
    required this.nric,
    required this.workEmail,
    required this.mobile,
    required this.address,
    required this.emergencyContactName,
    required this.emergencyContactRelationship,
    required this.emergencyContactPhone,
    required this.department,
    required this.position,
    required this.joinDate,
    required this.employmentType,
    required this.reportingTo,
    required this.epfNumber,
    required this.socsoNumber,
    required this.incomeTaxNumber,
  });
}
```

Save as `hrms_app/lib/models/personal_info.dart`.

- [ ] **Step 3: Update fake_data.dart**

In `hrms_app/lib/data/fake_data.dart`:

Add the import near the top, with the other model imports:

```dart
import '../models/personal_info.dart';
```

Replace the `employee` constant:

```dart
  static const employee = Employee(
    name: 'Sarah Chen',
    initials: 'SC',
    role: 'Product Designer',
    department: 'Design',
    employeeId: 'EMP-2041',
    employmentType: 'Full-time',
  );
```

Add, directly after the `_approversPending` list definition:

```dart
  /// Public alias so AppState (a different file) can expose the pending
  /// approval chain for the new-request form's preview.
  static const pendingApprovalChain = _approversPending;
```

Add, anywhere after the class's other top-level constants (e.g. right
before `myLeaveRequests`):

```dart
  static const personalInfo = PersonalInfo(
    dateOfBirth: '12 Mar 1993',
    gender: 'Female',
    maritalStatus: 'Single',
    nationality: 'Malaysian',
    nric: '930312-14-5xxx',
    workEmail: 'sarah.chen@company.com',
    mobile: '+60 12-345 6789',
    address: '12, Jalan Damai 3, Taman Desa, 58100 Kuala Lumpur',
    emergencyContactName: 'David Chen',
    emergencyContactRelationship: 'Brother',
    emergencyContactPhone: '+60 13-222 8890',
    department: 'Design',
    position: 'Product Designer',
    joinDate: '3 Feb 2022',
    employmentType: 'Full-time',
    reportingTo: 'Marcus Lee',
    epfNumber: '1234 5678',
    socsoNumber: '9303 1214 5xxx',
    incomeTaxNumber: 'SG 1234567890',
  );
```

- [ ] **Step 4: Run the full test suite to confirm nothing broke**

Run: `cd hrms_app && flutter test`
Expected: All existing tests still PASS (the `Employee` constructor change
is additive-only at its one call site in `fake_data.dart`, which this
step already updated).

- [ ] **Step 5: Commit**

```bash
git add hrms_app/lib/models/employee.dart hrms_app/lib/models/personal_info.dart hrms_app/lib/data/fake_data.dart
git commit -m "feat: extend Employee and add PersonalInfo fake data for the Profile tab"
```

---

### Task 3: AppState.submitLeaveRequest() + pendingApprovalChain + personalInfo getters

**Files:**
- Modify: `hrms_app/lib/state/app_state.dart`
- Modify: `hrms_app/test/app_state_test.dart`

**Interfaces:**
- Consumes: `FakeData.pendingApprovalChain`, `FakeData.personalInfo`
  (Task 2), `formatDateRangeLabel` (Task 1).
- Produces: `AppState.myLeaveRequests` becomes backed by mutable internal
  state (was a direct passthrough to `FakeData.myLeaveRequests`).
  `AppState.pendingApprovalChain` (`List<Approver>` getter).
  `AppState.personalInfo` (`PersonalInfo` getter). New method:
  `void submitLeaveRequest({required String type, required DateTime
  start, required DateTime end, required String reason})` — builds a new
  `LeaveRequest` with status `'Pending'`, prepends it to
  `myLeaveRequests`, calls `notifyListeners()`. Later tasks (6, 8, 11)
  call this method and read `myLeaveRequests`/`pendingApprovalChain`.

- [ ] **Step 1: Write the failing tests**

Add to `hrms_app/test/app_state_test.dart` (append inside the existing
`main()`, after the current three tests):

```dart
  test('submitLeaveRequest() prepends a new Pending request and notifies', () {
    final appState = AppState();
    final before = appState.myLeaveRequests.length;
    var notified = false;
    appState.addListener(() => notified = true);

    appState.submitLeaveRequest(
      type: 'Personal Leave',
      start: DateTime(2026, 8, 3),
      end: DateTime(2026, 8, 4),
      reason: 'Moving apartment',
    );

    expect(appState.myLeaveRequests.length, before + 1);
    expect(appState.myLeaveRequests.first.type, 'Personal Leave');
    expect(appState.myLeaveRequests.first.status, 'Pending');
    expect(appState.myLeaveRequests.first.dateRangeLabel, 'Aug 3 – 4 · 2 days');
    expect(appState.myLeaveRequests.first.reason, 'Moving apartment');
    expect(appState.myLeaveRequests.first.approvers, isNotEmpty);
    expect(notified, isTrue);
  });

  test('pendingApprovalChain exposes a non-empty approver list', () {
    final appState = AppState();
    expect(appState.pendingApprovalChain, isNotEmpty);
  });

  test('personalInfo exposes the employee\'s work email', () {
    final appState = AppState();
    expect(appState.personalInfo.workEmail, 'sarah.chen@company.com');
  });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd hrms_app && flutter test test/app_state_test.dart`
Expected: FAIL — `submitLeaveRequest`, `pendingApprovalChain`, and
`personalInfo` don't exist on `AppState` yet (compile error).

- [ ] **Step 3: Write the minimal implementation**

In `hrms_app/lib/state/app_state.dart`, add imports at the top (with the
existing model imports):

```dart
import '../models/approver.dart';
import '../models/personal_info.dart';
import '../theme/app_theme.dart';
import '../utils/date_range_label.dart';
```

Replace the line:

```dart
  List<LeaveRequest> get myLeaveRequests => FakeData.myLeaveRequests;
```

with:

```dart
  List<LeaveRequest> _myLeaveRequests = List.of(FakeData.myLeaveRequests);
  List<LeaveRequest> get myLeaveRequests => _myLeaveRequests;
  List<Approver> get pendingApprovalChain => FakeData.pendingApprovalChain;
  PersonalInfo get personalInfo => FakeData.personalInfo;
```

Add, after `clockOut()`, before the closing `}` of the class:

```dart
  /// Adds a new Pending leave request to the front of [myLeaveRequests].
  /// Mirrors clockIn()/clockOut(): mutate internal state, notify.
  void submitLeaveRequest({
    required String type,
    required DateTime start,
    required DateTime end,
    required String reason,
  }) {
    final newRequest = LeaveRequest(
      type: type,
      dateRangeLabel: formatDateRangeLabel(start, end),
      status: 'Pending',
      statusColor: AppColors.warning,
      statusBg: AppColors.warningTint,
      reason: reason,
      approvers: FakeData.pendingApprovalChain,
    );
    _myLeaveRequests = [newRequest, ..._myLeaveRequests];
    notifyListeners();
  }
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd hrms_app && flutter test test/app_state_test.dart`
Expected: PASS (6 tests total)

- [ ] **Step 5: Commit**

```bash
git add hrms_app/lib/state/app_state.dart hrms_app/test/app_state_test.dart
git commit -m "feat: add AppState.submitLeaveRequest() and profile-related getters"
```

---

### Task 4: LeaveDatePickerCalendar widget

**Files:**
- Create: `hrms_app/lib/widgets/leave_date_picker_calendar.dart`
- Test: `hrms_app/test/leave_date_picker_calendar_test.dart`

**Interfaces:**
- Consumes: `buildMonthGrid`, `monthNames` from
  `hrms_app/lib/utils/calendar_grid.dart` (already exists).
- Produces: `LeaveDatePickerCalendar` widget, constructor:
  `{DateTime? start, DateTime? end, DateTime? initialDate, required
  ValueChanged<DateTime?> onStartChanged, required ValueChanged<DateTime?>
  onEndChanged}`. `initialDate` only affects which month is shown when
  neither `start` nor `end` is set yet (defaults to `DateTime.now()` in
  production; tests pass a fixed future date for determinism). Tap
  behavior: first tap (or any tap once a full range is already selected)
  sets a fresh start and clears end; a tap before the current start
  replaces the start; any other tap sets the end. Days before today are
  disabled. Task 6 uses this inside the request form screen.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_app/widgets/leave_date_picker_calendar.dart';

void main() {
  testWidgets('tapping a day with no start selected sets the start date', (tester) async {
    DateTime? start;
    DateTime? end;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => LeaveDatePickerCalendar(
              start: start,
              end: end,
              initialDate: DateTime(2030, 1, 1),
              onStartChanged: (d) => setState(() => start = d),
              onEndChanged: (d) => setState(() => end = d),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('10'));
    await tester.pump();

    expect(start, DateTime(2030, 1, 10));
    expect(end, isNull);
  });

  testWidgets('tapping a later day once a start is set fills the end date', (tester) async {
    DateTime? start = DateTime(2030, 1, 10);
    DateTime? end;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => LeaveDatePickerCalendar(
              start: start,
              end: end,
              initialDate: DateTime(2030, 1, 1),
              onStartChanged: (d) => setState(() => start = d),
              onEndChanged: (d) => setState(() => end = d),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('20'));
    await tester.pump();

    expect(end, DateTime(2030, 1, 20));
  });

  testWidgets('tapping a day before the current start replaces the start', (tester) async {
    DateTime? start = DateTime(2030, 1, 10);
    DateTime? end;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => LeaveDatePickerCalendar(
              start: start,
              end: end,
              initialDate: DateTime(2030, 1, 1),
              onStartChanged: (d) => setState(() => start = d),
              onEndChanged: (d) => setState(() => end = d),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('5'));
    await tester.pump();

    expect(start, DateTime(2030, 1, 5));
    expect(end, isNull);
  });

  testWidgets('the next-month arrow advances the header label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LeaveDatePickerCalendar(
            start: null,
            end: null,
            initialDate: DateTime(2030, 1, 1),
            onStartChanged: (_) {},
            onEndChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('January 2030'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pump();

    expect(find.text('February 2030'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd hrms_app && flutter test test/leave_date_picker_calendar_test.dart`
Expected: FAIL — `leave_date_picker_calendar.dart` doesn't exist yet.

- [ ] **Step 3: Write minimal implementation**

```dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/calendar_grid.dart';

/// Month-grid calendar for picking a leave start/end date range.
///
/// Tap behavior: the first tap (or any tap once a full range is already
/// picked) starts a fresh selection; a tap before the current start
/// replaces the start; any other tap fills in the end date. Past days
/// are disabled. [initialDate] only controls which month is shown before
/// any date is picked (defaults to today) — it exists so tests can pin
/// the displayed month deterministically.
class LeaveDatePickerCalendar extends StatefulWidget {
  final DateTime? start;
  final DateTime? end;
  final DateTime? initialDate;
  final ValueChanged<DateTime?> onStartChanged;
  final ValueChanged<DateTime?> onEndChanged;

  const LeaveDatePickerCalendar({
    super.key,
    required this.start,
    required this.end,
    this.initialDate,
    required this.onStartChanged,
    required this.onEndChanged,
  });

  @override
  State<LeaveDatePickerCalendar> createState() => _LeaveDatePickerCalendarState();
}

class _LeaveDatePickerCalendarState extends State<LeaveDatePickerCalendar> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    final anchor = widget.start ?? widget.initialDate ?? DateTime.now();
    _year = anchor.year;
    _month = anchor.month;
  }

  void _previousMonth() {
    setState(() {
      if (_month == 1) {
        _month = 12;
        _year -= 1;
      } else {
        _month -= 1;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      if (_month == 12) {
        _month = 1;
        _year += 1;
      } else {
        _month += 1;
      }
    });
  }

  void _onDayTapped(int day) {
    final tapped = DateTime(_year, _month, day);
    final start = widget.start;
    final end = widget.end;
    if (start == null || end != null) {
      widget.onStartChanged(tapped);
      widget.onEndChanged(null);
    } else if (tapped.isBefore(start)) {
      widget.onStartChanged(tapped);
    } else {
      widget.onEndChanged(tapped);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isPast(int day) {
    final date = DateTime(_year, _month, day);
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    return date.isBefore(todayOnly);
  }

  bool _isEndpoint(int day) {
    final date = DateTime(_year, _month, day);
    return (widget.start != null && _isSameDay(date, widget.start!)) ||
        (widget.end != null && _isSameDay(date, widget.end!));
  }

  bool _isInRange(int day) {
    final start = widget.start;
    final end = widget.end;
    if (start == null || end == null) return false;
    final date = DateTime(_year, _month, day);
    return date.isAfter(start) && date.isBefore(end);
  }

  @override
  Widget build(BuildContext context) {
    final cells = buildMonthGrid(_year, _month);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _NavButton(icon: Icons.chevron_left, onTap: _previousMonth),
                Text(
                  '${monthNames[_month - 1]} $_year',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                _NavButton(icon: Icons.chevron_right, onTap: _nextMonth),
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
              childAspectRatio: 1,
              children: cells.map((day) {
                if (day == null) return const SizedBox.shrink();
                final past = _isPast(day);
                final endpoint = _isEndpoint(day);
                final inRange = _isInRange(day);
                return Padding(
                  padding: const EdgeInsets.all(2),
                  child: InkWell(
                    onTap: past ? null : () => _onDayTapped(day),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: endpoint
                            ? AppColors.primary
                            : (inRange ? AppColors.primaryTint : Colors.transparent),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: endpoint ? FontWeight.w800 : FontWeight.w600,
                          color: past ? AppColors.textMuted : (endpoint ? Colors.white : AppColors.textPrimary),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
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
  final VoidCallback onTap;

  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, size: 16, color: AppColors.textSecondary),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd hrms_app && flutter test test/leave_date_picker_calendar_test.dart`
Expected: PASS (4 tests)

- [ ] **Step 5: Commit**

```bash
git add hrms_app/lib/widgets/leave_date_picker_calendar.dart hrms_app/test/leave_date_picker_calendar_test.dart
git commit -m "feat: add LeaveDatePickerCalendar widget"
```

---

### Task 5: LeaveTypePickerScreen

**Files:**
- Create: `hrms_app/lib/screens/leave/leave_type_picker_screen.dart`
- Test: `hrms_app/test/leave_type_picker_screen_test.dart`

**Interfaces:**
- Consumes: `AppState.leaveBalances` (existing), `LeaveBalance` model
  (existing, fields `type`, `remaining`, `color`).
- Produces: `LeaveTypePickerScreen` (no constructor params). Tapping a
  tile pushes `LeaveRequestFormScreen(leaveType: <the tapped LeaveBalance>)`
  — `LeaveRequestFormScreen` is built in Task 6; this task's file imports
  it, so build Task 6's file (even as a stub) is not required first since
  both land in the same PR sequence — but to keep this task's tests
  green in isolation, Task 6 must exist before this task's tests are run.
  **Do these two tasks in order (5 then 6) or write Task 6's screen file
  first** — the plan lists them 5-then-6 for narrative order, but the
  Task 6 file must physically exist for Task 5's screen to compile.
  Simplest: implement Task 6's screen file contents as part of this
  task's Step 3 too (shown below), then Task 6 just adds Task 6's own
  test.

**Note for the implementer:** because `LeaveTypePickerScreen` navigates
to `LeaveRequestFormScreen`, create the file from Task 6 (the screen
only, not its test) as part of Step 3 below so the project compiles.
Task 6 will then add that screen's test.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hrms_app/screens/leave/leave_type_picker_screen.dart';
import 'package:hrms_app/state/app_state.dart';

void main() {
  testWidgets('lists each leave type with its remaining balance and opens the form on tap', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const MaterialApp(home: LeaveTypePickerScreen()),
      ),
    );

    expect(find.text('Choose a leave type to continue'), findsOneWidget);
    expect(find.text('Annual Leave'), findsOneWidget);
    expect(find.text('Sick Leave'), findsOneWidget);
    expect(find.text('Personal Leave'), findsOneWidget);

    await tester.tap(find.text('Annual Leave'));
    await tester.pumpAndSettle();

    expect(find.text('Select dates'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd hrms_app && flutter test test/leave_type_picker_screen_test.dart`
Expected: FAIL — neither screen file exists yet.

- [ ] **Step 3: Write minimal implementation**

Create `hrms_app/lib/screens/leave/leave_type_picker_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/leave_balance.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import 'leave_request_form_screen.dart';

class LeaveTypePickerScreen extends StatelessWidget {
  const LeaveTypePickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final balances = context.watch<AppState>().leaveBalances;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Request Leave', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'Choose a leave type to continue',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          Card(
            child: Column(
              children: [
                for (var i = 0; i < balances.length; i++)
                  _TypeTile(
                    balance: balances[i],
                    showDivider: i > 0,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => LeaveRequestFormScreen(leaveType: balances[i])),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeTile extends StatelessWidget {
  final LeaveBalance balance;
  final bool showDivider;
  final VoidCallback onTap;

  const _TypeTile({required this.balance, required this.showDivider, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: showDivider ? const Border(top: BorderSide(color: Color(0xFFF1F5F9))) : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${balance.type} Leave',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ),
            Text(
              '${balance.remaining} days left',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: balance.color),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 17, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }
}
```

Create `hrms_app/lib/screens/leave/leave_request_form_screen.dart`
(built in full now so the project compiles; Task 6 adds its test):

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/leave_balance.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_range_label.dart';
import '../../widgets/leave_date_picker_calendar.dart';
import 'leave_request_confirmation_screen.dart';

class LeaveRequestFormScreen extends StatefulWidget {
  final LeaveBalance leaveType;
  final DateTime? initialCalendarDate;

  const LeaveRequestFormScreen({super.key, required this.leaveType, this.initialCalendarDate});

  @override
  State<LeaveRequestFormScreen> createState() => _LeaveRequestFormScreenState();
}

class _LeaveRequestFormScreenState extends State<LeaveRequestFormScreen> {
  DateTime? _start;
  DateTime? _end;
  final _reasonController = TextEditingController();
  String _reason = '';

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  bool get _canSubmit => _start != null && _reason.trim().isNotEmpty;

  void _submit() {
    if (!_canSubmit) return;
    final start = _start!;
    final end = _end ?? _start!;
    final type = '${widget.leaveType.type} Leave';
    context.read<AppState>().submitLeaveRequest(
          type: type,
          start: start,
          end: end,
          reason: _reason.trim(),
        );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LeaveRequestConfirmationScreen(
          type: type,
          dateRangeLabel: formatDateRangeLabel(start, end),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final approvers = context.watch<AppState>().pendingApprovalChain;
    final start = _start;
    final end = _end;
    final fromLabel = start == null ? '—' : '${monthAbbr[start.month - 1]} ${start.day}';
    final toLabel = end == null
        ? (start == null ? '—' : fromLabel)
        : '${monthAbbr[end.month - 1]} ${end.day}';
    final totalLabel = start == null ? '—' : '${(end ?? start).difference(start).inDays + 1}d';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Request Leave', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.primaryTint, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.event_note_outlined, color: widget.leaveType.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${widget.leaveType.type} Leave',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text('Select dates', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          LeaveDatePickerCalendar(
            start: _start,
            end: _end,
            initialDate: widget.initialCalendarDate,
            onStartChanged: (d) => setState(() => _start = d),
            onEndChanged: (d) => setState(() => _end = d),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('From', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                        Text(fromLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('To', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                        Text(toLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 76,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
                decoration: BoxDecoration(color: AppColors.primaryTint, borderRadius: BorderRadius.circular(14)),
                child: Column(
                  children: [
                    const Text('Total', style: TextStyle(fontSize: 11, color: Color(0xFF047857), fontWeight: FontWeight.w600)),
                    Text(totalLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'Reason ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                TextSpan(text: '*', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.danger)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _reasonController,
            onChanged: (v) => setState(() => _reason = v),
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Enter your reason for this leave (required)',
              filled: true,
              fillColor: AppColors.cardBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text('Approval flow', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  for (final a in approvers)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(color: a.tint, borderRadius: BorderRadius.circular(10)),
                            alignment: Alignment.center,
                            child: Text(a.initials, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: a.color)),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                Text(a.role, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _canSubmit ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: const Color(0xFFCBD5E1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text('Submit request', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
```

Create `hrms_app/lib/screens/leave/leave_request_confirmation_screen.dart`
(also needed to compile; Task 7 adds its test):

```dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class LeaveRequestConfirmationScreen extends StatelessWidget {
  final String type;
  final String dateRangeLabel;

  const LeaveRequestConfirmationScreen({super.key, required this.type, required this.dateRangeLabel});

  @override
  Widget build(BuildContext context) {
    final duration = dateRangeLabel.contains(' · ') ? dateRangeLabel.split(' · ').last : dateRangeLabel;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: const BoxDecoration(color: AppColors.primaryTint, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Container(
                        width: 58,
                        height: 58,
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.check, color: Colors.white, size: 30),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Request submitted',
                      style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Your leave request has been sent for approval.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          _SummaryRow(label: 'Type', value: type),
                          const Divider(height: 24, color: Color(0xFFF1F5F9)),
                          _SummaryRow(label: 'Dates', value: dateRangeLabel),
                          const Divider(height: 24, color: Color(0xFFF1F5F9)),
                          _SummaryRow(label: 'Duration', value: duration, valueColor: AppColors.primary),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text('Back to Leave', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _SummaryRow({required this.label, required this.value, this.valueColor = AppColors.textPrimary});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: valueColor)),
      ],
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd hrms_app && flutter test test/leave_type_picker_screen_test.dart`
Expected: PASS (1 test)

- [ ] **Step 5: Commit**

```bash
git add hrms_app/lib/screens/leave/leave_type_picker_screen.dart hrms_app/lib/screens/leave/leave_request_form_screen.dart hrms_app/lib/screens/leave/leave_request_confirmation_screen.dart hrms_app/test/leave_type_picker_screen_test.dart
git commit -m "feat: add leave type picker, request form, and confirmation screens"
```

---

### Task 6: LeaveRequestFormScreen tests

**Files:**
- Test: `hrms_app/test/leave_request_form_screen_test.dart`

The screen itself was already built in Task 5 (it had to exist for
`LeaveTypePickerScreen` to compile). This task adds its dedicated test
coverage.

**Interfaces:**
- Consumes: `LeaveRequestFormScreen` (Task 5), `LeaveBalance` (existing),
  `AppState` (Task 3).

- [ ] **Step 1: Write the test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hrms_app/models/leave_balance.dart';
import 'package:hrms_app/screens/leave/leave_request_form_screen.dart';
import 'package:hrms_app/state/app_state.dart';
import 'package:hrms_app/theme/app_theme.dart';

const _annual = LeaveBalance(type: 'Annual', used: 12, total: 18, color: AppColors.primary);

void main() {
  testWidgets('submit is disabled until dates and a reason are provided, then adds a pending request', (tester) async {
    final appState = AppState();
    final requestsBefore = appState.myLeaveRequests.length;

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: MaterialApp(
          home: LeaveRequestFormScreen(leaveType: _annual, initialCalendarDate: DateTime(2030, 1, 1)),
        ),
      ),
    );

    final submitButtonFinder = find.widgetWithText(ElevatedButton, 'Submit request');
    expect(tester.widget<ElevatedButton>(submitButtonFinder).onPressed, isNull);

    await tester.tap(find.text('10'));
    await tester.pump();
    await tester.tap(find.text('12'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Family trip');
    await tester.pump();

    expect(tester.widget<ElevatedButton>(submitButtonFinder).onPressed, isNotNull);

    await tester.tap(submitButtonFinder);
    await tester.pumpAndSettle();

    expect(find.text('Request submitted'), findsOneWidget);
    expect(appState.myLeaveRequests.length, requestsBefore + 1);
    expect(appState.myLeaveRequests.first.type, 'Annual Leave');
    expect(appState.myLeaveRequests.first.status, 'Pending');
    expect(appState.myLeaveRequests.first.reason, 'Family trip');
  });

  testWidgets('picking a single day is enough to submit', (tester) async {
    final appState = AppState();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: MaterialApp(
          home: LeaveRequestFormScreen(leaveType: _annual, initialCalendarDate: DateTime(2030, 1, 1)),
        ),
      ),
    );

    await tester.tap(find.text('10'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Doctor visit');
    await tester.pump();

    final submitButtonFinder = find.widgetWithText(ElevatedButton, 'Submit request');
    expect(tester.widget<ElevatedButton>(submitButtonFinder).onPressed, isNotNull);

    await tester.tap(submitButtonFinder);
    await tester.pumpAndSettle();

    expect(appState.myLeaveRequests.first.dateRangeLabel, 'Jan 10 · 1 day');
  });
}
```

- [ ] **Step 2: Run test to verify it passes**

Run: `cd hrms_app && flutter test test/leave_request_form_screen_test.dart`
Expected: PASS (2 tests) — the screen was already implemented in Task 5,
so this should go straight to green. If it doesn't, fix
`leave_request_form_screen.dart` (not the test) until it does.

- [ ] **Step 3: Commit**

```bash
git add hrms_app/test/leave_request_form_screen_test.dart
git commit -m "test: cover LeaveRequestFormScreen submit gating and submission"
```

---

### Task 7: LeaveRequestConfirmationScreen tests

**Files:**
- Test: `hrms_app/test/leave_request_confirmation_screen_test.dart`

The screen was already built in Task 5. This task adds its test.

**Interfaces:**
- Consumes: `LeaveRequestConfirmationScreen` (Task 5).

- [ ] **Step 1: Write the test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_app/screens/leave/leave_request_confirmation_screen.dart';

void main() {
  testWidgets('shows the submitted request summary and pops back to the first route on tap', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const LeaveRequestConfirmationScreen(
                      type: 'Annual Leave',
                      dateRangeLabel: 'Jan 10 – 12 · 3 days',
                    ),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Request submitted'), findsOneWidget);
    expect(find.text('Annual Leave'), findsOneWidget);
    expect(find.text('Jan 10 – 12 · 3 days'), findsOneWidget);
    expect(find.text('3 days'), findsOneWidget);

    await tester.tap(find.text('Back to Leave'));
    await tester.pumpAndSettle();

    expect(find.text('open'), findsOneWidget);
    expect(find.text('Request submitted'), findsNothing);
  });
}
```

- [ ] **Step 2: Run test to verify it passes**

Run: `cd hrms_app && flutter test test/leave_request_confirmation_screen_test.dart`
Expected: PASS (1 test)

- [ ] **Step 3: Commit**

```bash
git add hrms_app/test/leave_request_confirmation_screen_test.dart
git commit -m "test: cover LeaveRequestConfirmationScreen summary and back navigation"
```

---

### Task 8: Wire the "Request" button on LeaveScreen

**Files:**
- Modify: `hrms_app/lib/screens/leave/leave_screen.dart`
- Modify: `hrms_app/test/leave_screen_test.dart`

**Interfaces:**
- Consumes: `LeaveTypePickerScreen` (Task 5).

- [ ] **Step 1: Write the failing test**

Add to `hrms_app/test/leave_screen_test.dart` (append inside `main()`,
after the existing three `testWidgets`):

```dart
  testWidgets('Tapping the Request button opens the leave type picker', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const MaterialApp(home: Scaffold(body: LeaveScreen())),
      ),
    );

    await tester.tap(find.text('Request'));
    await tester.pumpAndSettle();

    expect(find.text('Choose a leave type to continue'), findsOneWidget);
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd hrms_app && flutter test test/leave_screen_test.dart`
Expected: FAIL — tapping "Request" currently does nothing, so
`find.text('Choose a leave type to continue')` finds no widget.

- [ ] **Step 3: Write the minimal implementation**

In `hrms_app/lib/screens/leave/leave_screen.dart`, add an import:

```dart
import 'leave_type_picker_screen.dart';
```

Wrap the existing "Request" `Container` (the one with the `Icons.add`
icon + `'Request'` text, inside the `Row` at the top of `build()`) in an
`InkWell`. Replace:

```dart
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
```

with:

```dart
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LeaveTypePickerScreen()),
                    ),
                    child: Container(
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
                  ),
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd hrms_app && flutter test test/leave_screen_test.dart`
Expected: PASS (4 tests)

- [ ] **Step 5: Commit**

```bash
git add hrms_app/lib/screens/leave/leave_screen.dart hrms_app/test/leave_screen_test.dart
git commit -m "feat: wire the Leave tab's Request button to the type picker"
```

---

### Task 9: ComingSoonScreen + PersonalInfoScreen

**Files:**
- Create: `hrms_app/lib/screens/profile/coming_soon_screen.dart`
- Create: `hrms_app/lib/screens/profile/personal_info_screen.dart`
- Test: `hrms_app/test/personal_info_screen_test.dart`
- Test: `hrms_app/test/coming_soon_screen_test.dart`

**Interfaces:**
- Consumes: `AppState.employee`, `AppState.personalInfo` (Task 3).
- Produces: `ComingSoonScreen({required String title})` — generic
  placeholder used by Task 10 for Documents/Payslips/Settings.
  `PersonalInfoScreen` (no constructor params) — used by Task 10.

- [ ] **Step 1: Write the failing tests**

`hrms_app/test/coming_soon_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_app/screens/profile/coming_soon_screen.dart';

void main() {
  testWidgets('shows the given title and a coming-soon message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ComingSoonScreen(title: 'Payslips')),
    );

    expect(find.text('Payslips'), findsOneWidget);
    expect(find.text('Payslips is coming soon'), findsOneWidget);
  });
}
```

`hrms_app/test/personal_info_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hrms_app/screens/profile/personal_info_screen.dart';
import 'package:hrms_app/state/app_state.dart';

void main() {
  testWidgets('shows employee identity and grouped personal info sections', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const MaterialApp(home: PersonalInfoScreen()),
      ),
    );

    expect(find.text('Sarah Chen'), findsOneWidget);
    expect(find.text('Basic details'), findsOneWidget);
    expect(find.text('Contact'), findsOneWidget);
    expect(find.text('Emergency contact'), findsOneWidget);
    expect(find.text('Employment'), findsOneWidget);
    expect(find.text('Statutory'), findsOneWidget);
    expect(find.text('sarah.chen@company.com'), findsOneWidget);
  });

  testWidgets('tapping Edit shows a not-available message', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const MaterialApp(home: PersonalInfoScreen()),
      ),
    );

    await tester.tap(find.text('Edit'));
    await tester.pump();

    expect(find.text('Editing is not available in this preview'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd hrms_app && flutter test test/coming_soon_screen_test.dart test/personal_info_screen_test.dart`
Expected: FAIL — neither screen file exists yet.

- [ ] **Step 3: Write minimal implementation**

Create `hrms_app/lib/screens/profile/coming_soon_screen.dart`:

```dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Generic placeholder for Profile menu items not yet built in this
/// frontend-only preview (Documents, Payslips, Settings — see Phase 5
/// plan's Global Constraints for why they're deferred).
class ComingSoonScreen extends StatelessWidget {
  final String title;

  const ComingSoonScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.construction_outlined, size: 40, color: AppColors.textMuted),
              const SizedBox(height: 14),
              Text(
                '$title is coming soon',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                "This section isn't available in this preview yet.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

Create `hrms_app/lib/screens/profile/personal_info_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

class PersonalInfoScreen extends StatelessWidget {
  const PersonalInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final employee = appState.employee;
    final info = appState.personalInfo;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Personal information', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        actions: [
          TextButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Editing is not available in this preview')),
            ),
            child: const Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, AppColors.primaryDark],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(employee.initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(employee.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                        Text(
                          '${employee.role} · ${employee.department} · ${employee.employeeId}',
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _Section(title: 'Basic details', rows: [
            _InfoRow('Full name', employee.name),
            _InfoRow('Date of birth', info.dateOfBirth),
            _InfoRow('Gender', info.gender),
            _InfoRow('Marital status', info.maritalStatus),
            _InfoRow('Nationality', info.nationality),
            _InfoRow('NRIC', info.nric),
          ]),
          const SizedBox(height: 16),
          _Section(title: 'Contact', rows: [
            _InfoRow('Work email', info.workEmail),
            _InfoRow('Mobile', info.mobile),
            _InfoRow('Address', info.address),
          ]),
          const SizedBox(height: 16),
          _Section(title: 'Emergency contact', rows: [
            _InfoRow('Name', info.emergencyContactName),
            _InfoRow('Relationship', info.emergencyContactRelationship),
            _InfoRow('Phone', info.emergencyContactPhone),
          ]),
          const SizedBox(height: 16),
          _Section(title: 'Employment', rows: [
            _InfoRow('Department', info.department),
            _InfoRow('Position', info.position),
            _InfoRow('Join date', info.joinDate),
            _InfoRow('Employment type', info.employmentType),
            _InfoRow('Reporting to', info.reportingTo),
          ]),
          const SizedBox(height: 16),
          _Section(title: 'Statutory', rows: [
            _InfoRow('EPF no.', info.epfNumber),
            _InfoRow('SOCSO no.', info.socsoNumber),
            _InfoRow('Income tax (PCB)', info.incomeTaxNumber),
          ]),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(11)),
            child: const Text(
              'Statutory and employment details are managed by HR. To update them, tap Edit or contact your HR admin.',
              style: TextStyle(fontSize: 10.5, color: AppColors.textMuted, height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);
}

class _Section extends StatelessWidget {
  final String title;
  final List<_InfoRow> rows;

  const _Section({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++)
                  Container(
                    decoration: BoxDecoration(
                      border: i < rows.length - 1
                          ? const Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))
                          : null,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(rows[i].label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            rows[i].value,
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd hrms_app && flutter test test/coming_soon_screen_test.dart test/personal_info_screen_test.dart`
Expected: PASS (3 tests total)

- [ ] **Step 5: Commit**

```bash
git add hrms_app/lib/screens/profile/coming_soon_screen.dart hrms_app/lib/screens/profile/personal_info_screen.dart hrms_app/test/coming_soon_screen_test.dart hrms_app/test/personal_info_screen_test.dart
git commit -m "feat: add ComingSoonScreen and PersonalInfoScreen"
```

---

### Task 10: ProfileScreen

**Files:**
- Modify: `hrms_app/lib/screens/profile/profile_screen.dart`
- Test: `hrms_app/test/profile_screen_test.dart`

**Interfaces:**
- Consumes: `AppState.employee` (Task 2/3), `PersonalInfoScreen`,
  `ComingSoonScreen` (Task 9).

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hrms_app/screens/profile/profile_screen.dart';
import 'package:hrms_app/state/app_state.dart';

void main() {
  testWidgets('shows the employee header, badges, and menu items', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const MaterialApp(home: Scaffold(body: ProfileScreen())),
      ),
    );

    expect(find.text('Sarah Chen'), findsOneWidget);
    expect(find.text('Product Designer · Design'), findsOneWidget);
    expect(find.text('EMP-2041'), findsOneWidget);
    expect(find.text('Full-time'), findsOneWidget);
    expect(find.text('Personal information'), findsOneWidget);
    expect(find.text('Documents'), findsOneWidget);
    expect(find.text('Payslips'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('tapping Personal information opens its detail screen', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const MaterialApp(home: Scaffold(body: ProfileScreen())),
      ),
    );

    await tester.tap(find.text('Personal information'));
    await tester.pumpAndSettle();

    expect(find.text('Basic details'), findsOneWidget);
  });

  testWidgets('tapping Documents opens the coming-soon placeholder', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const MaterialApp(home: Scaffold(body: ProfileScreen())),
      ),
    );

    await tester.tap(find.text('Documents'));
    await tester.pumpAndSettle();

    expect(find.text('Documents is coming soon'), findsOneWidget);
  });

  testWidgets('tapping Log out shows a not-available message', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const MaterialApp(home: Scaffold(body: ProfileScreen())),
      ),
    );

    await tester.tap(find.text('Log out'));
    await tester.pump();

    expect(find.text('Logging out is not available in this preview'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd hrms_app && flutter test test/profile_screen_test.dart`
Expected: FAIL — `ProfileScreen` is still the Phase-1 placeholder
(`Center(child: Text('Me'))`).

- [ ] **Step 3: Write the minimal implementation**

Replace the full contents of
`hrms_app/lib/screens/profile/profile_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import 'coming_soon_screen.dart';
import 'personal_info_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final employee = context.watch<AppState>().employee;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        const Text('Profile', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  alignment: Alignment.center,
                  child: Text(employee.initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 26)),
                ),
                const SizedBox(height: 14),
                Text(employee.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text('${employee.role} · ${employee.department}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Badge(label: employee.employeeId, bg: const Color(0xFFF1F5F9), fg: const Color(0xFF475569)),
                    const SizedBox(width: 8),
                    _Badge(label: employee.employmentType, bg: AppColors.primaryTint, fg: AppColors.primary),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              _MenuTile(
                icon: Icons.person_outline,
                iconBg: AppColors.primaryTint,
                iconColor: AppColors.primary,
                label: 'Personal information',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PersonalInfoScreen()),
                ),
              ),
              _MenuTile(
                icon: Icons.description_outlined,
                iconBg: const Color(0xFFF5F3FF),
                iconColor: const Color(0xFF8B5CF6),
                label: 'Documents',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ComingSoonScreen(title: 'Documents')),
                ),
              ),
              _MenuTile(
                icon: Icons.receipt_long_outlined,
                iconBg: AppColors.warningTint,
                iconColor: AppColors.warning,
                label: 'Payslips',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ComingSoonScreen(title: 'Payslips')),
                ),
              ),
              _MenuTile(
                icon: Icons.settings_outlined,
                iconBg: const Color(0xFFF1F5F9),
                iconColor: const Color(0xFF475569),
                label: 'Settings',
                showDivider: false,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ComingSoonScreen(title: 'Settings')),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Logging out is not available in this preview')),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.dangerTint),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Log out', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _Badge({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final bool showDivider;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    this.showDivider = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: showDivider ? const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))) : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 19, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ),
            const Icon(Icons.chevron_right, size: 18, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd hrms_app && flutter test test/profile_screen_test.dart`
Expected: PASS (4 tests)

- [ ] **Step 5: Commit**

```bash
git add hrms_app/lib/screens/profile/profile_screen.dart hrms_app/test/profile_screen_test.dart
git commit -m "feat: build out the Profile tab with header, menu, and log out"
```

---

### Task 11: End-to-end leave request flow test + full suite/build verification

**Files:**
- Test: `hrms_app/test/leave_request_flow_test.dart`

This is the integration test tying the whole feature together: from the
Leave tab's "Request" button, through type selection, date/reason entry,
submission, confirmation, and back to the Leave tab where the new
request now appears in "My requests".

**Interfaces:**
- Consumes: `LeaveScreen` (Task 8) and everything it now transitively
  wires up.

- [ ] **Step 1: Write the test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hrms_app/screens/leave/leave_screen.dart';
import 'package:hrms_app/state/app_state.dart';

void main() {
  testWidgets('full flow: request a leave, submit it, and see it in My requests', (tester) async {
    final appState = AppState();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: const MaterialApp(home: Scaffold(body: LeaveScreen())),
      ),
    );

    await tester.tap(find.text('Request'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Personal Leave'));
    await tester.pumpAndSettle();

    // Move to next month so every day is guaranteed to be in the future,
    // regardless of what day the test happens to run on.
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pump();
    await tester.tap(find.text('10'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Moving apartment');
    await tester.pump();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Submit request'));
    await tester.pumpAndSettle();

    expect(find.text('Request submitted'), findsOneWidget);

    await tester.tap(find.text('Back to Leave'));
    await tester.pumpAndSettle();

    expect(find.text('Personal Leave'), findsWidgets);
    expect(appState.myLeaveRequests.first.type, 'Personal Leave');
    expect(appState.myLeaveRequests.first.reason, 'Moving apartment');
    expect(appState.myLeaveRequests.first.status, 'Pending');
  });
}
```

- [ ] **Step 2: Run test to verify it passes**

Run: `cd hrms_app && flutter test test/leave_request_flow_test.dart`
Expected: PASS (1 test)

- [ ] **Step 3: Run the entire test suite**

Run: `cd hrms_app && flutter test`
Expected: PASS — every test file, old and new, green.

- [ ] **Step 4: Verify the web build still compiles**

Run: `cd hrms_app && flutter build web`
Expected: Build succeeds with no errors (this is the project's Android-
build-blocked verification path — see Global Constraints).

- [ ] **Step 5: Commit**

```bash
git add hrms_app/test/leave_request_flow_test.dart
git commit -m "test: add end-to-end leave request creation flow test"
```

---

## After all tasks: whole-branch review

Once every task above is committed, do a final whole-branch review pass
(per `superpowers:subagent-driven-development`) covering:
- Every new/changed file compiles and all `flutter test` suites pass.
- The "dumb widget" convention held: `lib/widgets/leave_date_picker_calendar.dart`
  takes only constructor params/callbacks, no `Navigator` calls, no
  imports from `lib/screens/*`.
- No stray `print()`/debug statements, no TODOs.
- `git branch --show-current` is still `main`, `git remote -v` still
  only points at `https://github.com/nurlynnda/HRMS.git` — no
  unauthorized branch/remote changes across all 11 tasks' subagent runs.
- Then, per the established push policy, **ask the user before pushing**.
