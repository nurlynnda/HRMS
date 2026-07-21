# Phase 6: Claims (list, entitlements, form, detail, confirmation) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let a user tap "Claims" from Home's quick actions, see their pending/
approved claim totals and entitlement limits, submit a new expense claim
(type, amount, description), and see it immediately as "Pending" in their
claims list — matching item 6 of the design spec's phased build order
(`docs/superpowers/specs/2026-07-20-hrms-mobile-frontend-design.md`).

**Architecture:** Same feature-folder + Provider pattern as Phases 1-5.
Claims is not a bottom-nav tab — it's pushed from Home's `QuickActionsRow`
"Claims" tile, same way Phase 5's Personal Information screen is pushed
from Profile. New pure-function currency formatter in `lib/utils/`, two
new data models, and five new screens under `lib/screens/claims/`.
`AppState` grows one new mutating method, `submitClaim()`, following the
exact same mutate-then-`notifyListeners()` pattern as `clockIn()`/
`clockOut()`/`submitLeaveRequest()`.

**Tech Stack:** Flutter (Dart), Provider for state, `flutter_test` for
widget/unit tests. No new packages.

## Global Constraints

- Frontend-only, no real backend — all data hardcoded in `FakeData`,
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
- **This phase's own deferrals** (cut for scope/YAGNI, no backend to
  justify the complexity yet, same spirit as Phase 5's MC-upload
  deferral): no receipt photo upload (the mockup's "Upload or snap your
  receipt" step is skipped entirely — no required-attachment gate on
  submit), no manual claim-date picker (the claim date is always today,
  non-editable). Documents/Payslips/Settings on the Profile tab remain
  the Phase 5 placeholder "coming soon" screens — Payslip is its own
  future phase (item 7 in the spec's build order) and is out of scope
  here even though it appears as a Home quick-action tile.
- Claims is reached via Home's `QuickActionsRow` "Claims" tile, **not**
  a new bottom-nav tab — the bottom nav stays Home/Attendance/Leave/Me.
- Every subagent dispatch must include the git-safety instructions (no
  branch/remote changes, no `git push`) and the controller must verify
  `git branch --show-current && git remote -v` after each task.
- **Push policy:** ask the user for explicit confirmation before every
  `git push`, including force-pushes (flag the force-push risk
  explicitly when it applies).

---

### Task 1: Currency formatter

**Files:**
- Create: `hrms_app/lib/utils/currency.dart`
- Test: `hrms_app/test/currency_test.dart`

**Interfaces:**
- Produces: `String formatCurrency(double amount)` — formats with
  thousands separators and exactly 2 decimal places, e.g. `1730.0` →
  `'1,730.00'`. Callers prepend `'RM '` themselves (this function returns
  the number only, no currency symbol). Used by every Claims screen in
  later tasks.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_app/utils/currency.dart';

void main() {
  test('formats a small amount with two decimals', () {
    expect(formatCurrency(420), '420.00');
  });

  test('adds a thousands separator', () {
    expect(formatCurrency(1730), '1,730.00');
  });

  test('adds multiple thousands separators for large amounts', () {
    expect(formatCurrency(1234567.89), '1,234,567.89');
  });

  test('formats zero', () {
    expect(formatCurrency(0), '0.00');
  });

  test('rounds to two decimal places', () {
    expect(formatCurrency(99.999), '100.00');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd hrms_app && flutter test test/currency_test.dart`
Expected: FAIL — `currency.dart` doesn't exist yet (compile error).

- [ ] **Step 3: Write minimal implementation**

```dart
/// Formats a Ringgit amount with thousands separators and exactly two
/// decimal places, e.g. 1730.0 -> "1,730.00". Callers prepend "RM "
/// themselves — this returns the number only.
String formatCurrency(double amount) {
  final fixed = amount.toStringAsFixed(2);
  final dotIndex = fixed.indexOf('.');
  final whole = fixed.substring(0, dotIndex);
  final decimals = fixed.substring(dotIndex);
  final isNegative = whole.startsWith('-');
  final digits = isNegative ? whole.substring(1) : whole;

  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }

  return '${isNegative ? '-' : ''}$buffer$decimals';
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd hrms_app && flutter test test/currency_test.dart`
Expected: PASS (5 tests)

- [ ] **Step 5: Commit**

```bash
git add hrms_app/lib/utils/currency.dart hrms_app/test/currency_test.dart
git commit -m "feat: add currency formatter for claims"
```

---

### Task 2: Claim + ClaimEntitlement models and fake data

**Files:**
- Create: `hrms_app/lib/models/claim_entitlement.dart`
- Create: `hrms_app/lib/models/claim.dart`
- Modify: `hrms_app/lib/data/fake_data.dart`

**Interfaces:**
- Consumes: nothing new.
- Produces: `ClaimEntitlement` class with fields `type, subLabel, used,
  cap` (`cap` is `double?` — null means uncapped) `, color`, plus computed
  getters `double? get remaining` (`cap == null ? null : cap! - used`)
  and `double get progress` (`cap == null ? 0 : (used / cap!).clamp(0.0,
  1.0)`). `Claim` class with fields `id, category, dateLabel, amount,
  status, statusColor, statusBg, description, approvers` (all `final`,
  `approvers` is `List<Approver>` reusing the existing `Approver` model
  from Phase 5). `FakeData.claimEntitlements` (4 entries: Outpatient,
  Dental, Specs, Travel — Travel has `cap: null`), `FakeData.claims` (6
  sample claims), `FakeData.pendingClaimApprovers` (public alias, same
  pattern as Phase 5's `FakeData.pendingApprovalChain`), `FakeData.
  claimProjects` (`List<String>`), `FakeData.approvedYtdCap` (`double`).
  These are plain data classes — no dedicated unit test, same as
  `TeamAbsence`/`LeaveBalance`; exercised by screen widget tests in later
  tasks.

- [ ] **Step 1: Create the ClaimEntitlement model**

```dart
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
```

Save as `hrms_app/lib/models/claim_entitlement.dart`.

- [ ] **Step 2: Create the Claim model**

```dart
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
```

Save as `hrms_app/lib/models/claim.dart`.

- [ ] **Step 3: Update fake_data.dart**

In `hrms_app/lib/data/fake_data.dart`, add imports near the top with the
other model imports:

```dart
import '../models/claim.dart';
import '../models/claim_entitlement.dart';
```

Add, anywhere after the class's other top-level constants (e.g. right
before `myLeaveRequests`):

```dart
  static const claimEntitlements = [
    ClaimEntitlement(
      type: 'Outpatient',
      subLabel: 'Per visit · resets yearly',
      used: 320,
      cap: 800,
      color: AppColors.primary,
    ),
    ClaimEntitlement(
      type: 'Dental',
      subLabel: 'Per visit · resets yearly',
      used: 150,
      cap: 500,
      color: AppColors.info,
    ),
    ClaimEntitlement(
      type: 'Specs',
      subLabel: 'Once every 2 years',
      used: 0,
      cap: 400,
      color: Color(0xFF8B5CF6),
    ),
    ClaimEntitlement(
      type: 'Travel',
      subLabel: 'Tied to a company project',
      used: 1260,
      cap: null,
      color: Color(0xFFF59E0B),
    ),
  ];

  static const approvedYtdCap = 4000.0;

  static const claimProjects = ['Project Atlas', 'Project Nova', 'Project Vertex', 'Internal'];

  static const _pendingClaimApprovers = [
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
      initials: 'FT',
      tint: Color(0xFFECFDF5),
      color: AppColors.primaryDark,
      name: 'Finance Team',
      role: 'Final approver',
      status: 'Waiting',
      badgeBg: Color(0xFFF1F5F9),
      badgeColor: AppColors.textSecondary,
      when: '—',
    ),
  ];

  /// Public alias so AppState (a different file) can expose the pending
  /// claim approval chain for the new-claim form's preview.
  static const pendingClaimApprovers = _pendingClaimApprovers;

  static const _approvedClaimApprovers = [
    Approver(
      initials: 'ML',
      tint: Color(0xFFDBEAFE),
      color: Color(0xFF1D4ED8),
      name: 'Marcus Lee',
      role: 'Design Lead · 1st approver',
      status: 'Approved',
      badgeBg: AppColors.primaryTint,
      badgeColor: AppColors.primary,
      when: 'Jun 15, 11:02 AM',
    ),
    Approver(
      initials: 'FT',
      tint: Color(0xFFECFDF5),
      color: AppColors.primaryDark,
      name: 'Finance Team',
      role: 'Final approver',
      status: 'Approved',
      badgeBg: AppColors.primaryTint,
      badgeColor: AppColors.primary,
      when: 'Jun 16, 3:40 PM',
    ),
  ];

  static const claims = [
    Claim(
      id: 'CLM-0468',
      category: 'Outpatient',
      dateLabel: 'Jun 28',
      amount: 220.00,
      status: 'Pending',
      statusColor: AppColors.warning,
      statusBg: AppColors.warningTint,
      description: 'GP visit for flu symptoms.',
      approvers: _pendingClaimApprovers,
    ),
    Claim(
      id: 'CLM-0465',
      category: 'Dental',
      dateLabel: 'Jun 22',
      amount: 200.00,
      status: 'Pending',
      statusColor: AppColors.warning,
      statusBg: AppColors.warningTint,
      description: 'Routine scaling and polishing.',
      approvers: _pendingClaimApprovers,
    ),
    Claim(
      id: 'CLM-0451',
      category: 'Outpatient',
      dateLabel: 'Jun 10',
      amount: 100.00,
      status: 'Approved',
      statusColor: AppColors.primary,
      statusBg: AppColors.primaryTint,
      description: 'Follow-up consultation.',
      approvers: _approvedClaimApprovers,
    ),
    Claim(
      id: 'CLM-0438',
      category: 'Travel',
      dateLabel: 'May 28',
      amount: 860.00,
      status: 'Approved',
      statusColor: AppColors.primary,
      statusBg: AppColors.primaryTint,
      description: 'Client site visit — flights and lodging.',
      approvers: _approvedClaimApprovers,
    ),
    Claim(
      id: 'CLM-0410',
      category: 'Dental',
      dateLabel: 'Apr 30',
      amount: 150.00,
      status: 'Rejected',
      statusColor: AppColors.danger,
      statusBg: AppColors.dangerTint,
      description: 'Cosmetic whitening — not covered.',
      approvers: [
        Approver(
          initials: 'ML',
          tint: Color(0xFFDBEAFE),
          color: Color(0xFF1D4ED8),
          name: 'Marcus Lee',
          role: 'Design Lead · 1st approver',
          status: 'Rejected',
          badgeBg: AppColors.dangerTint,
          badgeColor: AppColors.danger,
          when: 'May 2, 9:15 AM',
        ),
        Approver(
          initials: 'FT',
          tint: Color(0xFFECFDF5),
          color: AppColors.primaryDark,
          name: 'Finance Team',
          role: 'Final approver',
          status: 'Waiting',
          badgeBg: Color(0xFFF1F5F9),
          badgeColor: AppColors.textSecondary,
          when: '—',
        ),
      ],
    ),
    Claim(
      id: 'CLM-0402',
      category: 'Outpatient',
      dateLabel: 'Apr 12',
      amount: 570.00,
      status: 'Approved',
      statusColor: AppColors.primary,
      statusBg: AppColors.primaryTint,
      description: 'Specialist referral and lab tests.',
      approvers: _approvedClaimApprovers,
    ),
  ];
```

- [ ] **Step 4: Run the full test suite to confirm nothing broke**

Run: `cd hrms_app && flutter test`
Expected: All existing tests still PASS (purely additive constants).

- [ ] **Step 5: Commit**

```bash
git add hrms_app/lib/models/claim_entitlement.dart hrms_app/lib/models/claim.dart hrms_app/lib/data/fake_data.dart
git commit -m "feat: add Claim/ClaimEntitlement models and fake claims data"
```

---

### Task 3: AppState.submitClaim() + claims getters

**Files:**
- Modify: `hrms_app/lib/state/app_state.dart`
- Modify: `hrms_app/test/app_state_test.dart`

**Interfaces:**
- Consumes: `FakeData.claims`, `FakeData.claimEntitlements`, `FakeData.
  pendingClaimApprovers`, `FakeData.claimProjects`, `FakeData.
  approvedYtdCap` (Task 2), `monthAbbr` (already imported from Phase 5's
  `date_range_label.dart`).
- Produces: `AppState.claims` (`List<Claim>`, mutable-backed, prepend-on-
  submit like `myLeaveRequests`). `AppState.claimEntitlements` (`List<
  ClaimEntitlement>`). `AppState.pendingClaimApprovers` (`List<
  Approver>`). `AppState.claimProjects` (`List<String>`). `AppState.
  approvedClaimsYtdCap` (`double`). Computed getters `AppState.
  pendingClaimsTotal` (`double`, sum of `Pending`-status claims'
  amounts) and `AppState.pendingClaimsCount` (`int`) and `AppState.
  approvedClaimsYtdTotal` (`double`, sum of `Approved`-status claims'
  amounts) — all derived live from `claims`, never separately hardcoded,
  so they can never drift out of sync with the list. New method: `void
  submitClaim({required String category, required double amount,
  required String description})` — builds a new `Claim` with status
  `'Pending'`, `dateLabel` set to today (`'${monthAbbr[now.month - 1]}
  ${now.day}'`), `id` set to `'CLM-${1000 + _claims.length}'`, prepends
  it to `claims`, calls `notifyListeners()`. Later tasks (7, 9, 10) call
  this method and read the getters above.

- [ ] **Step 1: Write the failing tests**

Add to `hrms_app/test/app_state_test.dart` (append inside the existing
`main()`, after the current tests):

```dart
  test('submitClaim() prepends a new Pending claim and notifies', () {
    final appState = AppState();
    final before = appState.claims.length;
    var notified = false;
    appState.addListener(() => notified = true);

    appState.submitClaim(category: 'Outpatient', amount: 150.0, description: 'Blood test');

    expect(appState.claims.length, before + 1);
    expect(appState.claims.first.category, 'Outpatient');
    expect(appState.claims.first.status, 'Pending');
    expect(appState.claims.first.amount, 150.0);
    expect(appState.claims.first.description, 'Blood test');
    expect(appState.claims.first.approvers, isNotEmpty);
    expect(notified, isTrue);
  });

  test('pendingClaimsTotal and pendingClaimsCount reflect only Pending claims', () {
    final appState = AppState();
    final expectedTotal = appState.claims
        .where((c) => c.status == 'Pending')
        .fold(0.0, (sum, c) => sum + c.amount);
    final expectedCount = appState.claims.where((c) => c.status == 'Pending').length;

    expect(appState.pendingClaimsTotal, expectedTotal);
    expect(appState.pendingClaimsCount, expectedCount);
  });

  test('approvedClaimsYtdTotal reflects only Approved claims', () {
    final appState = AppState();
    final expectedTotal = appState.claims
        .where((c) => c.status == 'Approved')
        .fold(0.0, (sum, c) => sum + c.amount);

    expect(appState.approvedClaimsYtdTotal, expectedTotal);
  });

  test('claimEntitlements and claimProjects expose non-empty lists', () {
    final appState = AppState();
    expect(appState.claimEntitlements, isNotEmpty);
    expect(appState.claimProjects, isNotEmpty);
  });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd hrms_app && flutter test test/app_state_test.dart`
Expected: FAIL — `submitClaim`, `claims`, `claimEntitlements`, etc. don't
exist on `AppState` yet (compile error).

- [ ] **Step 3: Write the minimal implementation**

In `hrms_app/lib/state/app_state.dart`, add imports at the top (with the
existing model imports):

```dart
import '../models/claim.dart';
import '../models/claim_entitlement.dart';
```

Add, after the `myLeaveRequests`-related getters, before `AttendanceWeekStats get attendanceWeekStats`:

```dart
  List<Claim> _claims = List.of(FakeData.claims);
  List<Claim> get claims => _claims;
  List<ClaimEntitlement> get claimEntitlements => FakeData.claimEntitlements;
  List<Approver> get pendingClaimApprovers => FakeData.pendingClaimApprovers;
  List<String> get claimProjects => FakeData.claimProjects;
  double get approvedClaimsYtdCap => FakeData.approvedYtdCap;

  double get pendingClaimsTotal =>
      _claims.where((c) => c.status == 'Pending').fold(0.0, (sum, c) => sum + c.amount);
  int get pendingClaimsCount => _claims.where((c) => c.status == 'Pending').length;
  double get approvedClaimsYtdTotal =>
      _claims.where((c) => c.status == 'Approved').fold(0.0, (sum, c) => sum + c.amount);
```

Add, after `submitLeaveRequest()`, before the closing `}` of the class:

```dart
  /// Adds a new Pending claim to the front of [claims]. Mirrors
  /// submitLeaveRequest(): mutate internal state, notify.
  void submitClaim({
    required String category,
    required double amount,
    required String description,
  }) {
    final now = DateTime.now();
    final newClaim = Claim(
      id: 'CLM-${1000 + _claims.length}',
      category: category,
      dateLabel: '${monthAbbr[now.month - 1]} ${now.day}',
      amount: amount,
      status: 'Pending',
      statusColor: AppColors.warning,
      statusBg: AppColors.warningTint,
      description: description,
      approvers: FakeData.pendingClaimApprovers,
    );
    _claims = [newClaim, ..._claims];
    notifyListeners();
  }
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd hrms_app && flutter test test/app_state_test.dart`
Expected: PASS (10 tests total)

- [ ] **Step 5: Commit**

```bash
git add hrms_app/lib/state/app_state.dart hrms_app/test/app_state_test.dart
git commit -m "feat: add AppState.submitClaim() and claims getters"
```

---

### Task 4: ClaimEntitlementsScreen

**Files:**
- Create: `hrms_app/lib/screens/claims/claim_entitlements_screen.dart`
- Test: `hrms_app/test/claim_entitlements_screen_test.dart`

**Interfaces:**
- Consumes: `AppState.claimEntitlements` (Task 3), `ClaimEntitlement`
  model (Task 2), `formatCurrency` (Task 1).
- Produces: `ClaimEntitlementsScreen` (no constructor params). Used by
  Task 8 (`ClaimsScreen` navigates to it via `Navigator.push`).

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hrms_app/screens/claims/claim_entitlements_screen.dart';
import 'package:hrms_app/state/app_state.dart';

void main() {
  testWidgets('lists every entitlement with its category and cap status', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const MaterialApp(home: ClaimEntitlementsScreen()),
      ),
    );

    expect(find.text('Claim entitlements'), findsOneWidget);
    expect(find.text('Outpatient'), findsOneWidget);
    expect(find.text('Dental'), findsOneWidget);
    expect(find.text('Specs'), findsOneWidget);
    expect(find.text('Travel'), findsOneWidget);
    expect(find.text('No cap'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd hrms_app && flutter test test/claim_entitlements_screen_test.dart`
Expected: FAIL — `claim_entitlements_screen.dart` doesn't exist yet.

- [ ] **Step 3: Write minimal implementation**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/claim_entitlement.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency.dart';

class ClaimEntitlementsScreen extends StatelessWidget {
  const ClaimEntitlementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final entitlements = context.watch<AppState>().claimEntitlements;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Claim entitlements', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: Text("Your claim limits and what's left.", style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
          ),
          for (final e in entitlements) _EntitlementCard(entitlement: e),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(11)),
            child: const Text(
              "Limits reset on a rolling window from your first claim. Travel has no cap but must be tied to a company project.",
              style: TextStyle(fontSize: 10.5, color: AppColors.textMuted, height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _EntitlementCard extends StatelessWidget {
  final ClaimEntitlement entitlement;

  const _EntitlementCard({required this.entitlement});

  @override
  Widget build(BuildContext context) {
    final cap = entitlement.cap;
    return Card(
      margin: const EdgeInsets.only(bottom: 7),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entitlement.type, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      Text(entitlement.subLabel, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                Text(
                  cap == null ? 'No cap' : 'RM ${formatCurrency(entitlement.remaining!)} left',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: entitlement.color),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: cap == null ? 1.0 : entitlement.progress,
                minHeight: 5,
                backgroundColor: const Color(0xFFEEF2F6),
                valueColor: AlwaysStoppedAnimation(entitlement.color),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              cap == null
                  ? 'RM ${formatCurrency(entitlement.used)} used YTD'
                  : 'RM ${formatCurrency(entitlement.used)} used of RM ${formatCurrency(cap)}',
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd hrms_app && flutter test test/claim_entitlements_screen_test.dart`
Expected: PASS (1 test)

- [ ] **Step 5: Commit**

```bash
git add hrms_app/lib/screens/claims/claim_entitlements_screen.dart hrms_app/test/claim_entitlements_screen_test.dart
git commit -m "feat: add ClaimEntitlementsScreen"
```

---

### Task 5: ClaimConfirmationScreen

**Files:**
- Create: `hrms_app/lib/screens/claims/claim_confirmation_screen.dart`
- Test: `hrms_app/test/claim_confirmation_screen_test.dart`

**Interfaces:**
- Consumes: `formatCurrency` (Task 1).
- Produces: `ClaimConfirmationScreen({required String category, required
  double amount, required String reference})`. Its "Back to Claims"
  button calls `Navigator.of(context).pop()` — a **single** pop, not
  `popUntil((route) => route.isFirst)`. This differs from Phase 5's
  `LeaveRequestConfirmationScreen`: there, the Leave tab itself was the
  first route in the stack (reached via bottom nav, not a push), so
  popping to the first route correctly landed back on it. Here, Claims
  is reached via a `Navigator.push` from Home (not a tab), so the stack
  when this screen is showing is `[..., ClaimsScreen, (NewClaimScreen
  replaced by) ClaimConfirmationScreen]` — a single `pop()` correctly
  reveals `ClaimsScreen` underneath. Used by Task 7 (`NewClaimScreen`
  navigates to it via `Navigator.pushReplacement`).

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_app/screens/claims/claim_confirmation_screen.dart';

void main() {
  testWidgets('shows the submitted claim summary and pops back to the previous screen on tap', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ClaimConfirmationScreen(
                      category: 'Dental',
                      amount: 200.0,
                      reference: 'CLM-1005',
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

    expect(find.text('Claim submitted'), findsOneWidget);
    expect(find.text('Dental'), findsOneWidget);
    expect(find.text('RM 200.00'), findsOneWidget);
    expect(find.text('CLM-1005'), findsOneWidget);

    await tester.tap(find.text('Back to Claims'));
    await tester.pumpAndSettle();

    expect(find.text('open'), findsOneWidget);
    expect(find.text('Claim submitted'), findsNothing);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd hrms_app && flutter test test/claim_confirmation_screen_test.dart`
Expected: FAIL — `claim_confirmation_screen.dart` doesn't exist yet.

- [ ] **Step 3: Write minimal implementation**

```dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency.dart';

class ClaimConfirmationScreen extends StatelessWidget {
  final String category;
  final double amount;
  final String reference;

  const ClaimConfirmationScreen({
    super.key,
    required this.category,
    required this.amount,
    required this.reference,
  });

  @override
  Widget build(BuildContext context) {
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
                      'Claim submitted',
                      style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Your claim has been sent to Marcus Lee, then Finance for reimbursement.',
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
                          _SummaryRow(label: 'Type', value: category),
                          const Divider(height: 24, color: Color(0xFFF1F5F9)),
                          _SummaryRow(label: 'Amount', value: 'RM ${formatCurrency(amount)}'),
                          const Divider(height: 24, color: Color(0xFFF1F5F9)),
                          _SummaryRow(label: 'Reference', value: reference, valueColor: AppColors.primary),
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
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text('Back to Claims', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
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

Run: `cd hrms_app && flutter test test/claim_confirmation_screen_test.dart`
Expected: PASS (1 test)

- [ ] **Step 5: Commit**

```bash
git add hrms_app/lib/screens/claims/claim_confirmation_screen.dart hrms_app/test/claim_confirmation_screen_test.dart
git commit -m "feat: add ClaimConfirmationScreen"
```

---

### Task 6: ClaimDetailScreen

**Files:**
- Create: `hrms_app/lib/screens/claims/claim_detail_screen.dart`
- Test: `hrms_app/test/claim_detail_screen_test.dart`

**Interfaces:**
- Consumes: `Claim`, `Approver` models (Task 2, Phase 5), `formatCurrency`
  (Task 1).
- Produces: `ClaimDetailScreen({required Claim claim})`. Used by Task 8
  (`ClaimsScreen` navigates to it via `Navigator.push` when a claim row
  is tapped).

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_app/models/approver.dart';
import 'package:hrms_app/models/claim.dart';
import 'package:hrms_app/screens/claims/claim_detail_screen.dart';
import 'package:hrms_app/theme/app_theme.dart';

const _claim = Claim(
  id: 'CLM-0468',
  category: 'Outpatient',
  dateLabel: 'Jun 28',
  amount: 220.0,
  status: 'Pending',
  statusColor: AppColors.warning,
  statusBg: AppColors.warningTint,
  description: 'GP visit for flu symptoms.',
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

void main() {
  testWidgets('shows claim amount, category, status, description, and approvers', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ClaimDetailScreen(claim: _claim)),
    );

    expect(find.text('RM 220.00'), findsOneWidget);
    expect(find.text('Outpatient · CLM-0468'), findsOneWidget);
    expect(find.text('Pending'), findsWidgets);
    expect(find.text('GP visit for flu symptoms.'), findsOneWidget);
    expect(find.text('Marcus Lee'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd hrms_app && flutter test test/claim_detail_screen_test.dart`
Expected: FAIL — `claim_detail_screen.dart` doesn't exist yet.

- [ ] **Step 3: Write minimal implementation**

```dart
import 'package:flutter/material.dart';
import '../../models/approver.dart';
import '../../models/claim.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency.dart';

class ClaimDetailScreen extends StatelessWidget {
  final Claim claim;

  const ClaimDetailScreen({super.key, required this.claim});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text(
          'Claim details',
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
                              'RM ${formatCurrency(claim.amount)}',
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${claim.category} · ${claim.id}',
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: claim.statusBg, borderRadius: BorderRadius.circular(999)),
                        child: Text(
                          claim.status,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: claim.statusColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Date', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      Text(claim.dateLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(claim.description, style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.5)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Approval progress', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Column(
                children: [
                  for (var i = 0; i < claim.approvers.length; i++)
                    _ApproverRow(
                      approver: claim.approvers[i],
                      showConnector: i < claim.approvers.length - 1,
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
              child: Text(approver.initials, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: approver.color)),
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
                    Text(approver.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: approver.badgeBg, borderRadius: BorderRadius.circular(999)),
                      child: Text(approver.status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: approver.badgeColor)),
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

- [ ] **Step 4: Run test to verify it passes**

Run: `cd hrms_app && flutter test test/claim_detail_screen_test.dart`
Expected: PASS (1 test)

- [ ] **Step 5: Commit**

```bash
git add hrms_app/lib/screens/claims/claim_detail_screen.dart hrms_app/test/claim_detail_screen_test.dart
git commit -m "feat: add ClaimDetailScreen"
```

---

### Task 7: NewClaimScreen

**Files:**
- Create: `hrms_app/lib/screens/claims/new_claim_screen.dart`
- Test: `hrms_app/test/new_claim_screen_test.dart`

**Interfaces:**
- Consumes: `AppState.claimEntitlements`, `AppState.claimProjects`,
  `AppState.pendingClaimApprovers`, `AppState.submitClaim()` (Task 3),
  `ClaimEntitlement` model (Task 2), `formatCurrency` (Task 1),
  `ClaimConfirmationScreen` (Task 5).
- Produces: `NewClaimScreen` (no constructor params). Used by Task 8
  (`ClaimsScreen`'s "New claim" button navigates to it via `Navigator.
  push`).

- [ ] **Step 1: Write the failing tests**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hrms_app/screens/claims/new_claim_screen.dart';
import 'package:hrms_app/state/app_state.dart';

void main() {
  testWidgets('submit is disabled until type, amount, and description are provided', (tester) async {
    final appState = AppState();
    final before = appState.claims.length;

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: const MaterialApp(home: NewClaimScreen()),
      ),
    );

    final submitFinder = find.widgetWithText(ElevatedButton, 'Submit claim');
    expect(tester.widget<ElevatedButton>(submitFinder).onPressed, isNull);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Dental'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, '120');
    await tester.pump();
    await tester.enterText(find.byType(TextField).last, 'Cleaning');
    await tester.pump();

    expect(tester.widget<ElevatedButton>(submitFinder).onPressed, isNotNull);

    await tester.tap(submitFinder);
    await tester.pumpAndSettle();

    expect(find.text('Claim submitted'), findsOneWidget);
    expect(appState.claims.length, before + 1);
    expect(appState.claims.first.category, 'Dental');
    expect(appState.claims.first.amount, 120.0);
  });

  testWidgets('selecting Travel requires a project before submit is enabled', (tester) async {
    final appState = AppState();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: const MaterialApp(home: NewClaimScreen()),
      ),
    );

    await tester.tap(find.widgetWithText(ChoiceChip, 'Travel'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, '300');
    await tester.pump();
    await tester.enterText(find.byType(TextField).last, 'Client visit');
    await tester.pump();

    final submitFinder = find.widgetWithText(ElevatedButton, 'Submit claim');
    expect(tester.widget<ElevatedButton>(submitFinder).onPressed, isNull);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Project Atlas'));
    await tester.pump();

    expect(tester.widget<ElevatedButton>(submitFinder).onPressed, isNotNull);
  });

  testWidgets('an amount over the remaining limit shows a warning but stays submittable', (tester) async {
    final appState = AppState();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: const MaterialApp(home: NewClaimScreen()),
      ),
    );

    await tester.tap(find.widgetWithText(ChoiceChip, 'Specs'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, '500');
    await tester.pump();

    expect(find.textContaining('over your remaining limit'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'New glasses');
    await tester.pump();

    final submitFinder = find.widgetWithText(ElevatedButton, 'Submit claim');
    expect(tester.widget<ElevatedButton>(submitFinder).onPressed, isNotNull);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd hrms_app && flutter test test/new_claim_screen_test.dart`
Expected: FAIL — `new_claim_screen.dart` doesn't exist yet.

- [ ] **Step 3: Write minimal implementation**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/claim_entitlement.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency.dart';
import 'claim_confirmation_screen.dart';

class NewClaimScreen extends StatefulWidget {
  const NewClaimScreen({super.key});

  @override
  State<NewClaimScreen> createState() => _NewClaimScreenState();
}

class _NewClaimScreenState extends State<NewClaimScreen> {
  ClaimEntitlement? _selectedType;
  String? _selectedProject;
  double? _amount;
  String _description = '';
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _needsProject => _selectedType?.type == 'Travel';

  bool get _canSubmit =>
      _selectedType != null &&
      _amount != null &&
      _amount! > 0 &&
      _description.trim().isNotEmpty &&
      (!_needsProject || _selectedProject != null);

  double? get _excess {
    final type = _selectedType;
    final amount = _amount;
    if (type == null || amount == null || type.cap == null) return null;
    final overage = (type.used + amount) - type.cap!;
    return overage > 0 ? overage : null;
  }

  void _selectType(ClaimEntitlement type) {
    setState(() {
      _selectedType = type;
      if (type.type != 'Travel') _selectedProject = null;
    });
  }

  void _submit() {
    if (!_canSubmit) return;
    final appState = context.read<AppState>();
    final category = _selectedType!.type;
    final amount = _amount!;
    appState.submitClaim(category: category, amount: amount, description: _description.trim());
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ClaimConfirmationScreen(
          category: category,
          amount: amount,
          reference: appState.claims.first.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final entitlements = appState.claimEntitlements;
    final projects = appState.claimProjects;
    final approvers = appState.pendingClaimApprovers;
    final excess = _excess;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text('New claim', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          const Text('Claim type', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final e in entitlements)
                ChoiceChip(
                  label: Text(e.type),
                  selected: _selectedType == e,
                  onSelected: (_) => _selectType(e),
                  selectedColor: AppColors.primaryTint,
                  labelStyle: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: _selectedType == e ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          if (_selectedType != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: BoxDecoration(color: AppColors.primaryTint, borderRadius: BorderRadius.circular(11)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedType!.cap == null
                        ? '${_selectedType!.type} · No cap'
                        : '${_selectedType!.type} · RM ${formatCurrency(_selectedType!.remaining!)} left',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  Text(_selectedType!.subLabel, style: const TextStyle(fontSize: 10.5, color: Color(0xFF475569), fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          const Text('Amount', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(11)),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Text('RM', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textMuted)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (v) => setState(() => _amount = double.tryParse(v)),
                    decoration: const InputDecoration(border: InputBorder.none, hintText: '0.00'),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          if (excess != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.warningTint,
                border: Border.all(color: const Color(0xFFFDE68A)),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text(
                'RM ${formatCurrency(excess)} over your remaining limit. You can still submit — only RM ${formatCurrency(_amount! - excess)} will be reimbursed.',
                style: const TextStyle(fontSize: 10.5, color: Color(0xFF92400E), height: 1.55),
              ),
            ),
          ],
          if (_needsProject) ...[
            const SizedBox(height: 14),
            const Text('Project', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final p in projects)
                  ChoiceChip(
                    label: Text(p),
                    selected: _selectedProject == p,
                    onSelected: (_) => setState(() => _selectedProject = p),
                    selectedColor: AppColors.primaryTint,
                    labelStyle: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: _selectedProject == p ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          const Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'Description ', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                TextSpan(text: '*', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.danger)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            onChanged: (v) => setState(() => _description = v),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'What was this expense for?',
              filled: true,
              fillColor: AppColors.cardBackground,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: AppColors.border)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Approval flow', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                children: [
                  for (final a in approvers)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(a.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          Text(a.role, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _canSubmit ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: const Color(0xFFCBD5E1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Submit claim', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd hrms_app && flutter test test/new_claim_screen_test.dart`
Expected: PASS (3 tests)

- [ ] **Step 5: Commit**

```bash
git add hrms_app/lib/screens/claims/new_claim_screen.dart hrms_app/test/new_claim_screen_test.dart
git commit -m "feat: add NewClaimScreen"
```

---

### Task 8: ClaimsScreen

**Files:**
- Create: `hrms_app/lib/screens/claims/claims_screen.dart`
- Test: `hrms_app/test/claims_screen_test.dart`

**Interfaces:**
- Consumes: `AppState.claims`, `AppState.pendingClaimsTotal`, `AppState.
  pendingClaimsCount`, `AppState.approvedClaimsYtdTotal`, `AppState.
  approvedClaimsYtdCap` (Task 3), `formatCurrency` (Task 1),
  `ClaimEntitlementsScreen` (Task 4), `ClaimDetailScreen` (Task 6),
  `NewClaimScreen` (Task 7).
- Produces: `ClaimsScreen` (no constructor params). Used by Task 9
  (Home's `QuickActionsRow` "Claims" tile navigates to it via
  `Navigator.push`).

- [ ] **Step 1: Write the failing tests**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hrms_app/screens/claims/claims_screen.dart';
import 'package:hrms_app/state/app_state.dart';

void main() {
  testWidgets('shows pending/approved summary tiles and the recent claims list', (tester) async {
    final appState = AppState();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: const MaterialApp(home: ClaimsScreen()),
      ),
    );

    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Approved YTD'), findsOneWidget);
    expect(find.text('Claim entitlements'), findsOneWidget);
    expect(find.text('Recent claims'), findsOneWidget);
    expect(find.text('Outpatient'), findsWidgets);
  });

  testWidgets('tapping a claim opens its detail screen', (tester) async {
    final appState = AppState();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: const MaterialApp(home: ClaimsScreen()),
      ),
    );

    await tester.tap(find.text('Jun 28 · CLM-0468'));
    await tester.pumpAndSettle();

    expect(find.text('Claim details'), findsOneWidget);
  });

  testWidgets('tapping Claim entitlements opens the entitlements screen', (tester) async {
    final appState = AppState();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: const MaterialApp(home: ClaimsScreen()),
      ),
    );

    await tester.tap(find.text('Claim entitlements'));
    await tester.pumpAndSettle();

    expect(find.text("Your claim limits and what's left."), findsOneWidget);
  });

  testWidgets('tapping New claim opens the new claim form', (tester) async {
    final appState = AppState();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: const MaterialApp(home: ClaimsScreen()),
      ),
    );

    await tester.tap(find.text('New claim'));
    await tester.pumpAndSettle();

    expect(find.text('Claim type'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd hrms_app && flutter test test/claims_screen_test.dart`
Expected: FAIL — `claims_screen.dart` doesn't exist yet.

- [ ] **Step 3: Write minimal implementation**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency.dart';
import 'claim_detail_screen.dart';
import 'claim_entitlements_screen.dart';
import 'new_claim_screen.dart';

class ClaimsScreen extends StatelessWidget {
  const ClaimsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Claims', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NewClaimScreen()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                ),
                child: const Text('New claim', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                  decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pending', style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                      Text('RM ${formatCurrency(appState.pendingClaimsTotal)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                      Text('${appState.pendingClaimsCount} claims', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    border: Border.all(color: const Color(0xFFEEF2F6)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Approved YTD', style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                      Text('RM ${formatCurrency(appState.approvedClaimsYtdTotal)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary)),
                      Text('of RM ${formatCurrency(appState.approvedClaimsYtdCap)} cap', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          InkWell(
            borderRadius: BorderRadius.circular(11),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ClaimEntitlementsScreen()),
            ),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 10, bottom: 18),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                border: Border.all(color: const Color(0xFFEEF2F6)),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Claim entitlements', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        const Text('Outpatient · Dental · Specs limits', style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 15, color: Color(0xFFCBD5E1)),
                ],
              ),
            ),
          ),
          const Text('Recent claims', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          for (final claim in appState.claims)
            Card(
              margin: const EdgeInsets.only(bottom: 7),
              child: InkWell(
                borderRadius: BorderRadius.circular(11),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ClaimDetailScreen(claim: claim)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(claim.category, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                            Text('${claim.dateLabel} · ${claim.id}', style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('RM ${formatCurrency(claim.amount)}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(color: claim.statusBg, borderRadius: BorderRadius.circular(999)),
                            child: Text(claim.status, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: claim.statusColor)),
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
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd hrms_app && flutter test test/claims_screen_test.dart`
Expected: PASS (4 tests)

- [ ] **Step 5: Commit**

```bash
git add hrms_app/lib/screens/claims/claims_screen.dart hrms_app/test/claims_screen_test.dart
git commit -m "feat: add ClaimsScreen"
```

---

### Task 9: Wire the "Claims" quick action on Home

**Files:**
- Modify: `hrms_app/lib/widgets/quick_actions_row.dart`
- Modify: `hrms_app/lib/screens/home/home_screen.dart`
- Modify: `hrms_app/test/home_screen_test.dart`

**Interfaces:**
- Consumes: `ClaimsScreen` (Task 8).
- Produces: `QuickActionsRow`'s constructor changes from `const
  QuickActionsRow({super.key})` to `const QuickActionsRow({super.key,
  required VoidCallback onClaimsTap})` — a breaking signature change.
  This is the file's only call site: `hrms_app/lib/screens/home/
  home_screen.dart`, which this task also updates. No other file
  constructs `QuickActionsRow` (`Attendance`, `Leave`, `Payslip` tiles
  stay visual-only, matching the file's existing "display-only for now"
  doc comment — only `Claims` gets wired this phase).

- [ ] **Step 1: Write the failing test**

Add to `hrms_app/test/home_screen_test.dart` (append inside `main()`,
after the existing `testWidgets`):

```dart
  testWidgets('tapping the Claims quick action opens the Claims screen', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const MaterialApp(home: Scaffold(body: HomeScreen())),
      ),
    );

    await tester.tap(find.text('Claims'));
    await tester.pumpAndSettle();

    expect(find.text('Recent claims'), findsOneWidget);
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd hrms_app && flutter test test/home_screen_test.dart`
Expected: FAIL — tapping "Claims" currently does nothing (no callback
wired), so `find.text('Recent claims')` finds no widget. (This will also
fail to compile until Step 3, since `HomeScreen` doesn't yet pass a
required `onClaimsTap` — write the test first anyway per TDD, then
proceed to make it compile and pass together in Step 3.)

- [ ] **Step 3: Write the minimal implementation**

Replace the full contents of
`hrms_app/lib/widgets/quick_actions_row.dart`:

```dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class _QuickAction {
  final IconData icon;
  final String label;

  const _QuickAction(this.icon, this.label);
}

/// Row of four icon shortcuts shown on Home: Attendance, Leave, Claims,
/// Payslip. Only Claims is wired to navigation so far (Phase 6);
/// Attendance/Leave/Payslip remain display-only until a later phase
/// gives them somewhere real to go.
class QuickActionsRow extends StatelessWidget {
  final VoidCallback onClaimsTap;

  const QuickActionsRow({super.key, required this.onClaimsTap});

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
      children: _actions.map((action) {
        final tile = Column(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
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
        );
        if (action.label == 'Claims') {
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onClaimsTap,
            child: tile,
          );
        }
        return tile;
      }).toList(),
    );
  }
}
```

Update `hrms_app/lib/screens/home/home_screen.dart`: add an import and
pass the new required callback. Add near the top with the other imports:

```dart
import '../claims/claims_screen.dart';
```

Replace:

```dart
          const QuickActionsRow(),
```

with:

```dart
          QuickActionsRow(
            onClaimsTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ClaimsScreen()),
            ),
          ),
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd hrms_app && flutter test test/home_screen_test.dart`
Expected: PASS (2 tests)

- [ ] **Step 5: Commit**

```bash
git add hrms_app/lib/widgets/quick_actions_row.dart hrms_app/lib/screens/home/home_screen.dart hrms_app/test/home_screen_test.dart
git commit -m "feat: wire the Home tab's Claims quick action"
```

---

### Task 10: End-to-end claim submission flow test + full suite/build verification

**Files:**
- Test: `hrms_app/test/claim_submission_flow_test.dart`

This is the integration test tying the whole feature together: from
Home's "Claims" quick action, through the Claims screen, into the new
claim form, through submission, confirmation, and back to Claims where
the new claim now appears in the recent-claims list.

**Interfaces:**
- Consumes: `HomeScreen` (Task 9) and everything it now transitively
  wires up.

- [ ] **Step 1: Write the test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hrms_app/screens/home/home_screen.dart';
import 'package:hrms_app/state/app_state.dart';

void main() {
  testWidgets('full flow: submit a claim from Home and see it in Claims', (tester) async {
    final appState = AppState();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: const MaterialApp(home: Scaffold(body: HomeScreen())),
      ),
    );

    await tester.tap(find.text('Claims'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('New claim'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Outpatient'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, '85');
    await tester.pump();
    await tester.enterText(find.byType(TextField).last, 'Pharmacy purchase');
    await tester.pump();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Submit claim'));
    await tester.pumpAndSettle();

    expect(find.text('Claim submitted'), findsOneWidget);

    await tester.tap(find.text('Back to Claims'));
    await tester.pumpAndSettle();

    expect(find.text('Recent claims'), findsOneWidget);
    expect(appState.claims.first.category, 'Outpatient');
    expect(appState.claims.first.amount, 85.0);
    expect(appState.claims.first.description, 'Pharmacy purchase');
    expect(appState.claims.first.status, 'Pending');
  });
}
```

- [ ] **Step 2: Run test to verify it passes**

Run: `cd hrms_app && flutter test test/claim_submission_flow_test.dart`
Expected: PASS (1 test). If a lazy-`ListView`-build issue prevents a
widget from being tapped/found (a `TextField` or button not yet built
because it's off-screen) — this has happened in earlier phases with
`ListView`-based forms — fix it in the test file only, the same way
Phase 5 did: use `tester.dragUntilVisible(finder, scrollable, offset)`
to scroll the target into view before interacting with it, or grow
`tester.view.physicalSize` for the duration of the test with
`addTearDown` to reset it. Do not change any `lib/` file to work around
a test-only viewport limitation — diagnose first (is the widget actually
missing, or just off-screen?) and explain the fix in the commit message
if one is needed.

- [ ] **Step 3: Run the entire test suite**

Run: `cd hrms_app && flutter test`
Expected: PASS — every test file, old and new, green.

- [ ] **Step 4: Verify the web build still compiles**

Run: `cd hrms_app && flutter build web`
Expected: Build succeeds with no errors (this is the project's Android-
build-blocked verification path — see Global Constraints).

- [ ] **Step 5: Commit**

```bash
git add hrms_app/test/claim_submission_flow_test.dart
git commit -m "test: add end-to-end claim submission flow test"
```

---

## After all tasks: whole-branch review

Once every task above is committed, do a final whole-branch review pass
(per `superpowers:subagent-driven-development`) covering:
- Every new/changed file compiles and all `flutter test` suites pass.
- The "dumb widget" convention held: `lib/widgets/quick_actions_row.dart`
  takes only constructor params/callbacks, no direct `Navigator` calls
  inside the widget itself (the callback is invoked by the widget, but
  the actual `Navigator.push` call lives in `home_screen.dart`, not in
  `quick_actions_row.dart`).
- `ClaimConfirmationScreen`'s single-`pop()` "Back to Claims" behavior
  is correct given Claims is a pushed screen, not a tab (re-verify this
  explicitly — it's the one place this phase's navigation pattern
  differs from Phase 5's, and worth double-checking end to end).
- No stray `print()`/debug statements, no TODOs.
- `git branch --show-current` is still `main`, `git remote -v` still
  only points at `https://github.com/nurlynnda/HRMS.git` — no
  unauthorized branch/remote changes across all 10 tasks' subagent runs.
- Then, per the established push policy, **ask the user before pushing**.
