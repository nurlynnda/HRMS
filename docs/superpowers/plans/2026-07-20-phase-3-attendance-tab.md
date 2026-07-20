# HRMS Mobile App — Phase 3: Attendance Tab Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the Attendance tab's placeholder with the real screen from
the mockup — today's clock-in/out ring, a weekly on-time/late/avg stats
card, a recent-activity list, a full Attendance History sub-page with
filter chips, and the face-check-in flow that runs before every clock
in/out.

**Architecture:** Same pattern as Phase 2 — small `StatelessWidget`s under
`lib/widgets/` taking data via constructor parameters, composed by
`AttendanceScreen` (which reads `AppState`). One new piece: a
`FaceCheckInOverlay` full-screen route pushed via `Navigator`, and an
`AttendanceHistoryScreen` (a `StatefulWidget`, since the filter chips are
page-local UI state that doesn't need to be shared app-wide) pushed the
same way. `AppState` gains its first two mutating methods (`clockIn()`,
`clockOut()`), matching the "later phases will add methods here" comment
already in `lib/state/app_state.dart`.

**Tech Stack:** Flutter/Dart, `provider` (existing), `dart:async`
`Future.delayed` for a **simulated** face-check-in flow — see the
important note below.

## Global Constraints

- Primary accent `#10B981` (`AppColors.primary`), gradient partner
  `#059669` (`AppColors.primaryDark`). Background `#F1F5F9`. Text: primary
  `#0F172A`, secondary `#64748B`, muted `#94A3B8`. Danger `#EF4444`.
  Warning `#F59E0B`. Border `#E2E8F0`. Tints added in Phase 2:
  `primaryTint` `#ECFDF5`, `primaryHighlight` `#6EE7B7`, `ringTrack`
  `#EEF2F6` — all already in `hrms_app/lib/theme/app_theme.dart`, reuse
  them. This phase adds one new color: `info` `#2563EB` (used for "Leave"
  status, matching the mockup's blue).
- Card style: use Flutter's `Card` widget (matches `AppTheme`'s
  `cardTheme` — 16px radius, white, soft shadow) rather than manual
  `BoxDecoration`.
- All data is hardcoded/fake — no real dates/times computed from
  `DateTime.now()`. Clock-in/out times set by `clockIn()`/`clockOut()` are
  fixed fake strings, consistent with the rest of the app.
- **Face check-in is SIMULATED, not real, for this phase.** The
  `local_auth` package (phone biometrics) only supports Android, iOS,
  Windows, and macOS — not the web — and Android builds are currently
  blocked on this development machine by an unrelated, separately-tracked
  environment bug. Since there is no way to actually run and verify real
  biometric code here right now, `FaceCheckInOverlay` uses a timed
  `Future.delayed` sequence (scanning → verifying → success) that always
  succeeds, standing in for the real prompt. Swapping in a real
  `local_auth` call is explicitly deferred to a future task, once Android
  builds work again and the integration can actually be tested. Do not add
  the `local_auth` dependency in this phase.
- **Unifying clock status with the Home tab:** Phase 2's `AppState.clockStatus`
  (used by `ClockStatusCard` on Home) currently reads a static value from
  `FakeData`. This phase changes it to be *computed* from the same
  `todayAttendance` state that this tab's clock in/out button mutates, so
  clocking in/out on the Attendance tab is reflected on Home too, without
  changing `ClockStatusCard`'s own code or its constructor signature at
  all — only how `AppState.clockStatus` is built changes.
- Verification: `flutter analyze` clean, `flutter test` all passing.
  Android emulator unavailable (known bug) — Chrome/web build and widget
  tests are the verification path, same as Phases 1-2.

---

### Task 1: Data models for Attendance

**Files:**
- Create: `hrms_app/lib/models/today_attendance.dart`
- Create: `hrms_app/lib/models/attendance_record.dart`
- Create: `hrms_app/lib/models/attendance_week_stats.dart`
- Create: `hrms_app/lib/models/attendance_history_stats.dart`

**Interfaces:**
- Produces: `TodayAttendance(clockedIn, clockInTime, clockOutTime,
  workedLabel, targetLabel, progress)`, `AttendanceRecord(day, dayOfWeek,
  dateLabel, timesLabel, note, hoursLabel, status, statusColor)`,
  `AttendanceWeekStats(onTime, late, avgPerDayLabel)`,
  `AttendanceHistoryStats(present, late, leave, avgLabel)`. Consumed by
  Tasks 2, 3, 5, 6, 7, 8.

- [ ] **Step 1: Write the four model files**

  Create `hrms_app/lib/models/today_attendance.dart`:
  ```dart
  /// Today's clock-in/out state — the source of truth the Attendance tab's
  /// ring card and the Home tab's clock-status card both read from.
  class TodayAttendance {
    final bool clockedIn;
    final String? clockInTime;
    final String? clockOutTime;
    final String workedLabel;
    final String targetLabel;
    final double progress;

    const TodayAttendance({
      required this.clockedIn,
      this.clockInTime,
      this.clockOutTime,
      required this.workedLabel,
      required this.targetLabel,
      required this.progress,
    });
  }
  ```

  Create `hrms_app/lib/models/attendance_record.dart`:
  ```dart
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
  ```

  Create `hrms_app/lib/models/attendance_week_stats.dart`:
  ```dart
  class AttendanceWeekStats {
    final int onTime;
    final int late;
    final String avgPerDayLabel;

    const AttendanceWeekStats({
      required this.onTime,
      required this.late,
      required this.avgPerDayLabel,
    });
  }
  ```

  Create `hrms_app/lib/models/attendance_history_stats.dart`:
  ```dart
  class AttendanceHistoryStats {
    final int present;
    final int late;
    final int leave;
    final String avgLabel;

    const AttendanceHistoryStats({
      required this.present,
      required this.late,
      required this.leave,
      required this.avgLabel,
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
  git commit -m "Add data models for the Attendance tab"
  ```

---

### Task 2: Extend theme and fake data for Attendance

**Files:**
- Modify: `hrms_app/lib/theme/app_theme.dart` (add `AppColors.info`)
- Modify: `hrms_app/lib/data/fake_data.dart` (add attendance data, remove
  the now-superseded `clockStatus` static)

**Interfaces:**
- Consumes: `TodayAttendance`, `AttendanceRecord`, `AttendanceWeekStats`,
  `AttendanceHistoryStats` (Task 1).
- Produces: `AppColors.info`; `FakeData.officeLocation`,
  `FakeData.todayAttendance`, `FakeData.weekStats`,
  `FakeData.attendanceRecords` (8 entries), `FakeData.historyStats`.
  Removes `FakeData.clockStatus` (Task 3 replaces its one caller with a
  computed value). Consumed by Task 3.

- [ ] **Step 1: Add the new color**

  In `hrms_app/lib/theme/app_theme.dart`, add one line inside `AppColors`,
  after the existing `border` line:
  ```dart
    static const info = Color(0xFF2563EB);
  ```

- [ ] **Step 2: Update fake_data.dart**

  In `hrms_app/lib/data/fake_data.dart`:
  1. Add these imports alongside the existing ones:
     ```dart
     import '../models/attendance_history_stats.dart';
     import '../models/attendance_record.dart';
     import '../models/attendance_week_stats.dart';
     import '../models/today_attendance.dart';
     ```
  2. **Remove** the existing `clockStatus` static field entirely (Task 3
     will make `AppState.clockStatus` computed instead).
  3. Add these new static members to the `FakeData` class:
     ```dart
       static const officeLocation = 'HQ Office';

       static const todayAttendance = TodayAttendance(
         clockedIn: true,
         clockInTime: '09:02 AM',
         clockOutTime: null,
         workedLabel: '6:12',
         targetLabel: '8h 00m',
         progress: 6.2 / 8.0,
       );

       static const weekStats = AttendanceWeekStats(
         onTime: 5,
         late: 0,
         avgPerDayLabel: '7.7h',
       );

       static const attendanceRecords = [
         AttendanceRecord(
           day: 19,
           dayOfWeek: 'THU',
           dateLabel: 'Thursday, Jun 19',
           timesLabel: '09:00 — 17:24',
           note: '',
           hoursLabel: '8.4h',
           status: 'On time',
           statusColor: AppColors.primary,
         ),
         AttendanceRecord(
           day: 18,
           dayOfWeek: 'WED',
           dateLabel: 'Wednesday, Jun 18',
           timesLabel: '09:05 — 16:35',
           note: '',
           hoursLabel: '7.5h',
           status: 'On time',
           statusColor: AppColors.primary,
         ),
         AttendanceRecord(
           day: 17,
           dayOfWeek: 'TUE',
           dateLabel: 'Tuesday, Jun 17',
           timesLabel: '09:12 — 17:40',
           note: '',
           hoursLabel: '8.5h',
           status: 'Late',
           statusColor: AppColors.warning,
         ),
         AttendanceRecord(
           day: 16,
           dayOfWeek: 'MON',
           dateLabel: 'Monday, Jun 16',
           timesLabel: '09:00 — 17:10',
           note: '',
           hoursLabel: '8.2h',
           status: 'On time',
           statusColor: AppColors.primary,
         ),
         AttendanceRecord(
           day: 13,
           dayOfWeek: 'FRI',
           dateLabel: 'Friday, Jun 13',
           timesLabel: '— : —',
           note: 'Approved leave',
           hoursLabel: '—',
           status: 'Leave',
           statusColor: AppColors.info,
         ),
         AttendanceRecord(
           day: 12,
           dayOfWeek: 'THU',
           dateLabel: 'Thursday, Jun 12',
           timesLabel: '09:03 — 17:20',
           note: '',
           hoursLabel: '8.3h',
           status: 'On time',
           statusColor: AppColors.primary,
         ),
         AttendanceRecord(
           day: 11,
           dayOfWeek: 'WED',
           dateLabel: 'Wednesday, Jun 11',
           timesLabel: '09:20 — 17:15',
           note: '',
           hoursLabel: '7.9h',
           status: 'Late',
           statusColor: AppColors.warning,
         ),
         AttendanceRecord(
           day: 10,
           dayOfWeek: 'TUE',
           dateLabel: 'Tuesday, Jun 10',
           timesLabel: '09:00 — 17:30',
           note: '',
           hoursLabel: '8.5h',
           status: 'On time',
           statusColor: AppColors.primary,
         ),
       ];

       static const historyStats = AttendanceHistoryStats(
         present: 19,
         late: 2,
         leave: 1,
         avgLabel: '7.8h',
       );
     ```

- [ ] **Step 3: Verify it compiles**

  Run: `flutter analyze`
  Expected: `No issues found!` (this will show an error until Task 3
  updates `AppState` to stop reading the removed `FakeData.clockStatus` —
  if `flutter analyze` reports that specific error, that's expected at
  this point; note it in your report but do not attempt to fix
  `AppState` yourself, that's Task 3's job. If there are any OTHER
  analyzer errors, fix those.)

- [ ] **Step 4: Commit**

  ```
  cd C:\Projects\HRMS
  git add hrms_app/lib/theme/app_theme.dart hrms_app/lib/data/fake_data.dart
  git commit -m "Add Attendance tab fake data and the info color"
  ```

---

### Task 3: Extend AppState with attendance data and clock in/out

**Files:**
- Modify: `hrms_app/lib/state/app_state.dart`

**Interfaces:**
- Consumes: `FakeData` (Task 2); `TodayAttendance`, `AttendanceRecord`,
  `AttendanceWeekStats`, `AttendanceHistoryStats` (Task 1); the existing
  `ClockStatus` model (Phase 2, unchanged).
- Produces: `AppState.todayAttendance` (getter), `AppState.clockStatus`
  (now computed from `todayAttendance` instead of a static field —
  **same type and same call signature as before**, so `HomeScreen`'s
  `ClockStatusCard` needs no changes), `AppState.attendanceWeekStats`,
  `AppState.attendanceRecords`, `AppState.attendanceHistoryStats`, and two
  new methods `AppState.clockIn()` / `AppState.clockOut()` that mutate
  `todayAttendance` and call `notifyListeners()`. Consumed by Task 9.

- [ ] **Step 1: Write the failing test for clockIn()/clockOut()**

  Create `hrms_app/test/app_state_test.dart`:
  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:hrms_app/state/app_state.dart';

  void main() {
    test('clockOut() sets clockedIn to false and records a clock-out time', () {
      final appState = AppState();
      expect(appState.todayAttendance.clockedIn, isTrue);

      appState.clockOut();

      expect(appState.todayAttendance.clockedIn, isFalse);
      expect(appState.todayAttendance.clockOutTime, isNotNull);
      expect(appState.clockStatus.clockedIn, isFalse);
    });

    test('clockIn() sets clockedIn to true and clears the clock-out time', () {
      final appState = AppState();
      appState.clockOut();

      appState.clockIn();

      expect(appState.todayAttendance.clockedIn, isTrue);
      expect(appState.todayAttendance.clockOutTime, isNull);
      expect(appState.clockStatus.clockedIn, isTrue);
    });

    test('notifyListeners fires when clocking in or out', () {
      final appState = AppState();
      var notified = false;
      appState.addListener(() => notified = true);

      appState.clockOut();

      expect(notified, isTrue);
    });
  }
  ```

- [ ] **Step 2: Run the test to verify it fails**

  Run: `flutter test test/app_state_test.dart`
  Expected: FAIL — `AppState` doesn't have `todayAttendance`, `clockIn()`,
  or `clockOut()` yet (compile error is an acceptable form of "fails for
  the right reason" here, since the members don't exist).

- [ ] **Step 3: Update AppState**

  Replace the full contents of `hrms_app/lib/state/app_state.dart`:
  ```dart
  import 'package:flutter/foundation.dart';
  import '../data/fake_data.dart';
  import '../models/announcement.dart';
  import '../models/attendance_history_stats.dart';
  import '../models/attendance_record.dart';
  import '../models/attendance_week_stats.dart';
  import '../models/clock_status.dart';
  import '../models/day_hours.dart';
  import '../models/employee.dart';
  import '../models/leave_balance.dart';
  import '../models/today_attendance.dart';

  /// Shared app state. Currently exposes hardcoded fake data plus the
  /// first two mutating methods: clockIn() and clockOut(). Later phases
  /// will add more methods here (submitLeaveRequest(), etc.) following
  /// the same pattern: mutate internal state, call notifyListeners().
  class AppState extends ChangeNotifier {
    Employee get employee => FakeData.employee;

    TodayAttendance _todayAttendance = FakeData.todayAttendance;
    TodayAttendance get todayAttendance => _todayAttendance;

    /// Home tab's clock-status card reads this. Computed from
    /// [todayAttendance] so clocking in/out on the Attendance tab is
    /// reflected here too.
    ClockStatus get clockStatus => ClockStatus(
          clockedIn: _todayAttendance.clockedIn,
          since: _todayAttendance.clockInTime ?? '—',
          location: FakeData.officeLocation,
          hoursWorkedToday: _todayAttendance.workedLabel,
        );

    List<DayHours> get weeklyHours => FakeData.weeklyHours;
    String get weeklyTotalHoursLabel => FakeData.weeklyTotalHoursLabel;
    String get weeklyChangeLabel => FakeData.weeklyChangeLabel;
    List<LeaveBalance> get leaveBalances => FakeData.leaveBalances;
    List<Announcement> get announcements => FakeData.announcements;

    AttendanceWeekStats get attendanceWeekStats => FakeData.weekStats;
    List<AttendanceRecord> get attendanceRecords => FakeData.attendanceRecords;
    AttendanceHistoryStats get attendanceHistoryStats => FakeData.historyStats;

    void clockIn() {
      _todayAttendance = TodayAttendance(
        clockedIn: true,
        clockInTime: '09:02 AM',
        clockOutTime: null,
        workedLabel: _todayAttendance.workedLabel,
        targetLabel: _todayAttendance.targetLabel,
        progress: _todayAttendance.progress,
      );
      notifyListeners();
    }

    void clockOut() {
      _todayAttendance = TodayAttendance(
        clockedIn: false,
        clockInTime: _todayAttendance.clockInTime,
        clockOutTime: '05:15 PM',
        workedLabel: _todayAttendance.workedLabel,
        targetLabel: _todayAttendance.targetLabel,
        progress: _todayAttendance.progress,
      );
      notifyListeners();
    }
  }
  ```

- [ ] **Step 4: Run the test to verify it passes**

  Run: `flutter test test/app_state_test.dart`
  Expected: PASS (all 3 tests)

- [ ] **Step 5: Run the full test suite and analyzer**

  Run: `flutter test`
  Expected: all tests passing — `test/app_test.dart` (5, from Phase 1),
  `test/home_screen_test.dart` (1, from Phase 2 — confirms
  `ClockStatusCard` still renders correctly with the now-computed
  `clockStatus`), and the new `test/app_state_test.dart` (3).

  Run: `flutter analyze`
  Expected: `No issues found!`

- [ ] **Step 6: Commit**

  ```
  cd C:\Projects\HRMS
  git add hrms_app/lib/state/app_state.dart hrms_app/test/app_state_test.dart
  git commit -m "Add attendance data getters and clockIn()/clockOut() to AppState"
  ```

---

### Task 4: Face check-in overlay (simulated)

**Files:**
- Create: `hrms_app/lib/widgets/face_check_in_overlay.dart`

**Interfaces:**
- Produces: `FaceCheckInOverlay({required bool clockingIn})` — a
  `StatefulWidget` meant to be pushed as a full-screen route. Pops itself
  with `Navigator.pop(true)` on simulated success, or `Navigator.pop(false)`
  if the user taps the close button. Consumed by Task 9.

- [ ] **Step 1: Write FaceCheckInOverlay**

  Create `hrms_app/lib/widgets/face_check_in_overlay.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import '../theme/app_theme.dart';

  enum _FaceStage { scanning, verifying, success }

  /// Full-screen face check-in/out flow. SIMULATED for this phase — see
  /// the Phase 3 plan's Global Constraints for why real `local_auth`
  /// biometrics aren't wired in yet. Always "succeeds" after a short
  /// timed sequence standing in for a real prompt.
  class FaceCheckInOverlay extends StatefulWidget {
    final bool clockingIn;

    const FaceCheckInOverlay({super.key, required this.clockingIn});

    @override
    State<FaceCheckInOverlay> createState() => _FaceCheckInOverlayState();
  }

  class _FaceCheckInOverlayState extends State<FaceCheckInOverlay> {
    _FaceStage _stage = _FaceStage.scanning;

    @override
    void initState() {
      super.initState();
      _runSimulatedFlow();
    }

    Future<void> _runSimulatedFlow() async {
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      setState(() => _stage = _FaceStage.verifying);

      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() => _stage = _FaceStage.success);

      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    }

    @override
    Widget build(BuildContext context) {
      final verb = widget.clockingIn ? 'in' : 'out';
      final statusText = switch (_stage) {
        _FaceStage.scanning => 'Align your face within the frame',
        _FaceStage.verifying => 'Verifying your face…',
        _FaceStage.success => 'Identity verified',
      };

      return Scaffold(
        backgroundColor: const Color(0xFF0B1220),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Face Check-$verb',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Verify your identity to clock $verb',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 230,
                      height: 288,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _stage == _FaceStage.success
                            ? AppColors.primary.withValues(alpha: 0.22)
                            : const Color(0xFF243247),
                        border: Border.all(
                          color: _stage == _FaceStage.success ? AppColors.primary : Colors.white24,
                          width: 3,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: _stage == _FaceStage.scanning
                          ? const SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                                strokeWidth: 3,
                              ),
                            )
                          : Icon(
                              _stage == _FaceStage.success
                                  ? Icons.check_circle
                                  : Icons.face_retouching_natural,
                              color: Colors.white,
                              size: 48,
                            ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: _stage == _FaceStage.success ? 15 : 13,
                        fontWeight: _stage == _FaceStage.success ? FontWeight.w700 : FontWeight.w400,
                        color: _stage == _FaceStage.success ? Colors.white : const Color(0xFF94A3B8),
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
  git add hrms_app/lib/widgets/face_check_in_overlay.dart
  git commit -m "Add simulated FaceCheckInOverlay widget"
  ```

---

### Task 5: Today-attendance ring card widget

**Files:**
- Create: `hrms_app/lib/widgets/today_attendance_card.dart`

**Interfaces:**
- Consumes: `TodayAttendance` (Task 1); `AppColors` (Phase 1/2/this phase's
  `info` addition not needed here).
- Produces: `TodayAttendanceCard({required TodayAttendance attendance,
  required VoidCallback onClockButtonPressed})`. Consumed by Task 9.

- [ ] **Step 1: Write TodayAttendanceCard**

  Create `hrms_app/lib/widgets/today_attendance_card.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import '../models/today_attendance.dart';
  import '../theme/app_theme.dart';

  /// Today's clock-in/out card: circular progress ring, clock in/out
  /// times, and the clock in/out button that triggers face check-in.
  class TodayAttendanceCard extends StatelessWidget {
    final TodayAttendance attendance;
    final VoidCallback onClockButtonPressed;

    const TodayAttendanceCard({
      super.key,
      required this.attendance,
      required this.onClockButtonPressed,
    });

    @override
    Widget build(BuildContext context) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 128,
                    height: 128,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 128,
                          height: 128,
                          child: CircularProgressIndicator(
                            value: attendance.progress.clamp(0.0, 1.0),
                            strokeWidth: 12,
                            backgroundColor: AppColors.ringTrack,
                            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              attendance.workedLabel,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'of ${attendance.targetLabel}',
                              style: const TextStyle(
                                fontSize: 11,
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
                          'TODAY',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Clock in',
                                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                                Text(
                                  attendance.clockInTime ?? '— : —',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFCBD5E1),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Clock out',
                                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                                Text(
                                  attendance.clockOutTime ?? '— : —',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: attendance.clockOutTime == null
                                        ? AppColors.textMuted
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: onClockButtonPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: attendance.clockedIn ? AppColors.danger : AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  icon: Icon(attendance.clockedIn ? Icons.logout : Icons.face_retouching_natural),
                  label: Text(
                    attendance.clockedIn ? 'Clock Out' : 'Clock In with Face',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
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
  git add hrms_app/lib/widgets/today_attendance_card.dart
  git commit -m "Add TodayAttendanceCard widget"
  ```

---

### Task 6: Weekly attendance stats card widget

**Files:**
- Create: `hrms_app/lib/widgets/weekly_attendance_stats_card.dart`

**Interfaces:**
- Consumes: `DayHours` (Phase 2), `AttendanceWeekStats` (Task 1);
  `AppColors`.
- Produces: `WeeklyAttendanceStatsCard({required List<DayHours> days,
  required AttendanceWeekStats stats})`. Consumed by Task 9.

- [ ] **Step 1: Write WeeklyAttendanceStatsCard**

  Create `hrms_app/lib/widgets/weekly_attendance_stats_card.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import '../models/attendance_week_stats.dart';
  import '../models/day_hours.dart';
  import '../theme/app_theme.dart';

  /// "This week" card on the Attendance tab: a compact bar chart (reusing
  /// the same weekly-hours data the Home tab shows) plus on-time/late/avg
  /// stat boxes.
  class WeeklyAttendanceStatsCard extends StatelessWidget {
    final List<DayHours> days;
    final AttendanceWeekStats stats;

    const WeeklyAttendanceStatsCard({
      super.key,
      required this.days,
      required this.stats,
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
              const Text(
                'This week',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
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
                              height: 76 * (day.hours / maxHours),
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              decoration: BoxDecoration(
                                color: day.highlighted ? AppColors.primaryHighlight : AppColors.primary,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(7),
                                  bottom: Radius.circular(3),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              day.label.substring(0, 1),
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
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _StatBox(
                      value: '${stats.onTime}',
                      label: 'On time',
                      valueColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatBox(
                      value: '${stats.late}',
                      label: 'Late',
                      valueColor: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatBox(
                      value: stats.avgPerDayLabel,
                      label: 'Avg/day',
                      valueColor: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
  }

  class _StatBox extends StatelessWidget {
    final String value;
    final String label;
    final Color valueColor;

    const _StatBox({required this.value, required this.label, required this.valueColor});

    @override
    Widget build(BuildContext context) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: valueColor)),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
          ],
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
  git add hrms_app/lib/widgets/weekly_attendance_stats_card.dart
  git commit -m "Add WeeklyAttendanceStatsCard widget"
  ```

---

### Task 7: Recent attendance list widget

**Files:**
- Create: `hrms_app/lib/widgets/recent_attendance_list.dart`

**Interfaces:**
- Consumes: `AttendanceRecord` (Task 1); `AppColors`.
- Produces: `RecentAttendanceList({required List<AttendanceRecord> records,
  required VoidCallback onViewAll})` — shows the first 2 records from the
  list (assumes callers pass records already sorted most-recent-first, as
  `FakeData.attendanceRecords` is). Consumed by Task 9.

- [ ] **Step 1: Write RecentAttendanceList**

  Create `hrms_app/lib/widgets/recent_attendance_list.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import '../models/attendance_record.dart';
  import '../theme/app_theme.dart';

  /// "Recent" section on the Attendance tab: header with a "View all" link
  /// and the two most recent attendance records.
  class RecentAttendanceList extends StatelessWidget {
    final List<AttendanceRecord> records;
    final VoidCallback onViewAll;

    const RecentAttendanceList({
      super.key,
      required this.records,
      required this.onViewAll,
    });

    @override
    Widget build(BuildContext context) {
      final recent = records.take(2).toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              TextButton.icon(
                onPressed: onViewAll,
                icon: const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.primary),
                label: const Text(
                  'View all',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ),
            ],
          ),
          ...recent.map(
            (r) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.dateLabel,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            r.timesLabel,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          r.hoursLabel,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          r.status,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: r.statusColor),
                        ),
                      ],
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
  git add hrms_app/lib/widgets/recent_attendance_list.dart
  git commit -m "Add RecentAttendanceList widget"
  ```

---

### Task 8: Attendance History sub-page with filter chips

**Files:**
- Create: `hrms_app/lib/screens/attendance/attendance_history_screen.dart`
- Create: `hrms_app/test/attendance_history_screen_test.dart`

**Interfaces:**
- Consumes: `AttendanceRecord`, `AttendanceHistoryStats` (Task 1).
- Produces: `AttendanceHistoryScreen({required List<AttendanceRecord>
  records, required AttendanceHistoryStats stats})`. Consumed by Task 9.
  Internally manages its own `_selectedFilter` state (page-local UI state,
  not part of `AppState`) — filters `records` by `status` when a chip
  other than "All" is selected.

- [ ] **Step 1: Write the failing test**

  Create `hrms_app/test/attendance_history_screen_test.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:hrms_app/models/attendance_history_stats.dart';
  import 'package:hrms_app/models/attendance_record.dart';
  import 'package:hrms_app/screens/attendance/attendance_history_screen.dart';
  import 'package:hrms_app/theme/app_theme.dart';

  const _records = [
    AttendanceRecord(
      day: 19,
      dayOfWeek: 'THU',
      dateLabel: 'Thursday, Jun 19',
      timesLabel: '09:00 — 17:24',
      note: '',
      hoursLabel: '8.4h',
      status: 'On time',
      statusColor: AppColors.primary,
    ),
    AttendanceRecord(
      day: 17,
      dayOfWeek: 'TUE',
      dateLabel: 'Tuesday, Jun 17',
      timesLabel: '09:12 — 17:40',
      note: '',
      hoursLabel: '8.5h',
      status: 'Late',
      statusColor: AppColors.warning,
    ),
  ];

  const _stats = AttendanceHistoryStats(present: 19, late: 2, leave: 1, avgLabel: '7.8h');

  void main() {
    testWidgets('shows all records by default, filters when a chip is tapped', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AttendanceHistoryScreen(records: _records, stats: _stats),
        ),
      );

      expect(find.text('Thursday, Jun 19'), findsOneWidget);
      expect(find.text('Tuesday, Jun 17'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Late'));
      await tester.pumpAndSettle();

      expect(find.text('Thursday, Jun 19'), findsNothing);
      expect(find.text('Tuesday, Jun 17'), findsOneWidget);
    });
  }
  ```

- [ ] **Step 2: Run the test to verify it fails**

  Run: `flutter test test/attendance_history_screen_test.dart`
  Expected: FAIL — `AttendanceHistoryScreen` doesn't exist yet.

- [ ] **Step 3: Write AttendanceHistoryScreen**

  Create `hrms_app/lib/screens/attendance/attendance_history_screen.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import '../../models/attendance_history_stats.dart';
  import '../../models/attendance_record.dart';
  import '../../theme/app_theme.dart';

  class AttendanceHistoryScreen extends StatefulWidget {
    final List<AttendanceRecord> records;
    final AttendanceHistoryStats stats;

    const AttendanceHistoryScreen({
      super.key,
      required this.records,
      required this.stats,
    });

    @override
    State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
  }

  class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
    static const _filters = ['All', 'On time', 'Late', 'Leave'];
    String _selectedFilter = 'All';

    @override
    Widget build(BuildContext context) {
      final filtered = _selectedFilter == 'All'
          ? widget.records
          : widget.records.where((r) => r.status == _selectedFilter).toList();

      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          foregroundColor: AppColors.textPrimary,
          title: const Text(
            'Attendance History',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatChip(value: '${widget.stats.present}', label: 'Present', color: AppColors.primary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatChip(value: '${widget.stats.late}', label: 'Late', color: AppColors.warning),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatChip(value: '${widget.stats.leave}', label: 'Leave', color: AppColors.info),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatChip(value: widget.stats.avgLabel, label: 'Avg', color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 18),
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
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: r.statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${r.day}',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: r.statusColor),
                              ),
                              Text(
                                r.dayOfWeek,
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: r.statusColor),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.timesLabel,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                r.note.isEmpty ? r.dateLabel : r.note,
                                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              r.hoursLabel,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              r.status,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: r.statusColor),
                            ),
                          ],
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

  class _StatChip extends StatelessWidget {
    final String value;
    final String label;
    final Color color;

    const _StatChip({required this.value, required this.label, required this.color});

    @override
    Widget build(BuildContext context) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(value, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: color)),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }
  }
  ```

- [ ] **Step 4: Run the test to verify it passes**

  Run: `flutter test test/attendance_history_screen_test.dart`
  Expected: PASS

- [ ] **Step 5: Verify analyzer is clean**

  Run: `flutter analyze`
  Expected: `No issues found!`

- [ ] **Step 6: Commit**

  ```
  cd C:\Projects\HRMS
  git add hrms_app/lib/screens/attendance/attendance_history_screen.dart hrms_app/test/attendance_history_screen_test.dart
  git commit -m "Add AttendanceHistoryScreen with filter chips"
  ```

---

### Task 9: Assemble the real AttendanceScreen

**Files:**
- Modify: `hrms_app/lib/screens/attendance/attendance_screen.dart`
  (replaces the Phase 1 placeholder entirely)
- Create: `hrms_app/test/attendance_screen_test.dart`

**Interfaces:**
- Consumes: `AppState` (Task 3, via `context.watch<AppState>()`);
  `TodayAttendanceCard` (Task 5); `WeeklyAttendanceStatsCard` (Task 6);
  `RecentAttendanceList` (Task 7); `AttendanceHistoryScreen` (Task 8);
  `FaceCheckInOverlay` (Task 4).

- [ ] **Step 1: Write the failing tests**

  Create `hrms_app/test/attendance_screen_test.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:provider/provider.dart';
  import 'package:hrms_app/screens/attendance/attendance_screen.dart';
  import 'package:hrms_app/state/app_state.dart';

  void main() {
    testWidgets('AttendanceScreen shows today\'s status and weekly stats', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AppState(),
          child: const MaterialApp(home: Scaffold(body: AttendanceScreen())),
        ),
      );

      expect(find.text('Attendance'), findsOneWidget);
      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('This week'), findsOneWidget);
      expect(find.text('Recent'), findsOneWidget);
    });

    testWidgets('Tapping Clock Out completes the face check-in flow and updates state', (tester) async {
      final appState = AppState();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(home: Scaffold(body: AttendanceScreen())),
        ),
      );

      expect(find.text('Clock Out'), findsOneWidget);

      await tester.tap(find.text('Clock Out'));
      await tester.pumpAndSettle();

      expect(appState.todayAttendance.clockedIn, isFalse);
      expect(find.text('Clock In with Face'), findsOneWidget);
    });

    testWidgets('Tapping View all opens Attendance History', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AppState(),
          child: const MaterialApp(home: Scaffold(body: AttendanceScreen())),
        ),
      );

      await tester.tap(find.text('View all'));
      await tester.pumpAndSettle();

      expect(find.text('Attendance History'), findsOneWidget);
    });
  }
  ```

- [ ] **Step 2: Run the tests to verify they fail**

  Run: `flutter test test/attendance_screen_test.dart`
  Expected: FAIL — the placeholder `AttendanceScreen` only shows centered
  "Attendance" text, so "TODAY"/"This week"/"Recent"/"Clock Out"/"View all"
  aren't found.

- [ ] **Step 3: Replace AttendanceScreen with the real screen**

  Replace the entire contents of
  `hrms_app/lib/screens/attendance/attendance_screen.dart`:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:provider/provider.dart';
  import '../../state/app_state.dart';
  import '../../theme/app_theme.dart';
  import '../../widgets/face_check_in_overlay.dart';
  import '../../widgets/recent_attendance_list.dart';
  import '../../widgets/today_attendance_card.dart';
  import '../../widgets/weekly_attendance_stats_card.dart';
  import 'attendance_history_screen.dart';

  class AttendanceScreen extends StatelessWidget {
    const AttendanceScreen({super.key});

    Future<void> _handleClockButton(BuildContext context, AppState appState) async {
      final clockingIn = !appState.todayAttendance.clockedIn;
      final verified = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => FaceCheckInOverlay(clockingIn: clockingIn),
          fullscreenDialog: true,
        ),
      );
      if (verified == true) {
        if (clockingIn) {
          appState.clockIn();
        } else {
          appState.clockOut();
        }
      }
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
                  'Attendance',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Jun 2026',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TodayAttendanceCard(
              attendance: appState.todayAttendance,
              onClockButtonPressed: () => _handleClockButton(context, appState),
            ),
            const SizedBox(height: 16),
            WeeklyAttendanceStatsCard(
              days: appState.weeklyHours,
              stats: appState.attendanceWeekStats,
            ),
            const SizedBox(height: 16),
            RecentAttendanceList(
              records: appState.attendanceRecords,
              onViewAll: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AttendanceHistoryScreen(
                    records: appState.attendanceRecords,
                    stats: appState.attendanceHistoryStats,
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

- [ ] **Step 4: Run the tests to verify they pass**

  Run: `flutter test test/attendance_screen_test.dart`
  Expected: PASS (all 3 tests)

- [ ] **Step 5: Run the full test suite and analyzer**

  Run: `flutter test`
  Expected: all tests passing — `test/app_test.dart` (5),
  `test/home_screen_test.dart` (1), `test/app_state_test.dart` (3),
  `test/attendance_history_screen_test.dart` (1), and
  `test/attendance_screen_test.dart` (3) — 13 total.

  Run: `flutter analyze`
  Expected: `No issues found!`

- [ ] **Step 6: Build for web as a visual sanity check**

  Run: `flutter build web`
  Expected: builds successfully with no errors.

- [ ] **Step 7: Commit**

  ```
  cd C:\Projects\HRMS
  git add hrms_app/lib/screens/attendance/attendance_screen.dart hrms_app/test/attendance_screen_test.dart
  git commit -m "Assemble the real Attendance screen with face check-in flow"
  ```

---

## Definition of done for Phase 3

- [ ] `flutter analyze` reports no issues
- [ ] `flutter test` passes all 13 tests
- [ ] `flutter build web` succeeds
- [ ] The Attendance tab shows: today's clock ring + clock in/out button,
      a weekly on-time/late/avg stats card, and a recent-activity list
      with a working "View all" link to a filterable Attendance History
      page
- [ ] Tapping the clock button opens the (simulated) face check-in flow
      and, on completion, updates both the Attendance tab and the Home
      tab's clock status
- [ ] All work is committed to `master` in `C:\Projects\HRMS`

Once this is verified, the next plan (Phase 4: Leave tab) will build out
the leave request flow, team calendar, and leave history — replacing the
`LeaveScreen` placeholder. A follow-up task (timing TBD, blocked on the
Android build environment issue) will replace `FaceCheckInOverlay`'s
simulated delay with a real `local_auth` biometric prompt.
