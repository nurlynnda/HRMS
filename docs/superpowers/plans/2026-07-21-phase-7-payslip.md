# Phase 7: Payslip (list, detail) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let a user open their payslip history from two places — the "Payslip"
quick action on Home, and "Payslips" on the Profile tab — see the latest
payslip's net pay at a glance, and drill into any past payslip's full
earnings/deductions breakdown. Matches item 7 of the design spec's phased
build order (`docs/superpowers/specs/2026-07-20-hrms-mobile-frontend-design.md`).

**Architecture:** Same feature-folder + Provider pattern as Phases 1-6.
Payslip is not a bottom-nav tab — it's a read-only, historical-record
feature with two entry points that both push the same `PayslipScreen`:
Home's `QuickActionsRow` "Payslip" tile (already present but non-interactive,
built in Phase 2) and Profile's "Payslips" menu item (currently a
Phase-5 `ComingSoonScreen` placeholder). Unlike Leave/Claims, this phase
has no submission flow — payslips are fixed historical fake data, so
`AppState` only grows one new read-only getter, no mutating method.

**Tech Stack:** Flutter (Dart), Provider for state, `flutter_test` for
widget/unit tests. No new packages. Reuses `formatCurrency` from Phase 6
(`hrms_app/lib/utils/currency.dart`) — no new formatter needed.

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
  justify the complexity yet, same spirit as Phase 5/6's file-upload
  deferrals): no real PDF generation or download — the "Download PDF"
  button shows a SnackBar ("Downloading isn't available in this
  preview"), matching the established pattern from Phase 5's Edit button
  and Log out button. No month/year picker or filtering — the payslip
  history is a fixed, most-recent-first list of fake data. Documents and
  Settings on the Profile tab remain the Phase 5 placeholder "coming
  soon" screens — only Payslips gets wired to a real screen this phase.
- Payslip has **two** entry points this phase (unlike Leave/Claims, which
  had one each): Home's `QuickActionsRow` "Payslip" tile, and Profile's
  "Payslips" menu item. Both push the same `PayslipScreen`.
- Every subagent dispatch must include the git-safety instructions (no
  branch/remote changes, no `git push`) and the controller must verify
  `git branch --show-current && git remote -v` after each task.
- **Push policy:** ask the user for explicit confirmation before every
  `git push`, including force-pushes (flag the force-push risk
  explicitly when it applies).

---

### Task 1: Payslip + PayslipLineItem models and fake data

**Files:**
- Create: `hrms_app/lib/models/payslip_line_item.dart`
- Create: `hrms_app/lib/models/payslip.dart`
- Modify: `hrms_app/lib/data/fake_data.dart`

**Interfaces:**
- Consumes: nothing new.
- Produces: `PayslipLineItem` class with fields `label` (`String`),
  `amount` (`double`), both `final`, const constructor. `Payslip` class
  with fields `id, month, period, payDate, status` (all `String`) and
  `earnings, deductions` (both `List<PayslipLineItem>`), plus computed
  getters `double get grossPay` (sum of `earnings` amounts), `double get
  totalDeductions` (sum of `deductions` amounts), and `double get netPay`
  (`grossPay - totalDeductions`) — computed live from the line items so
  the three numbers can never drift out of sync with each other.
  `FakeData.payslips`: a `List<Payslip>` with 5 entries, **most recent
  first** (June 2026 down to February 2026) — later tasks rely on
  `.first` being the latest payslip. These are plain data classes — no
  dedicated unit test, same as `Claim`/`ClaimEntitlement` from Phase 6;
  exercised by screen widget tests in later tasks.

- [ ] **Step 1: Create the PayslipLineItem model**

```dart
/// One line of a payslip's earnings or deductions breakdown, e.g.
/// "Basic salary" / 6000.00. The same shape is reused for both earnings
/// and deductions — whether a line is added or subtracted is a
/// UI-rendering decision (deductions render with a leading "−" and red
/// text), not something this model encodes.
class PayslipLineItem {
  final String label;
  final double amount;

  const PayslipLineItem({required this.label, required this.amount});
}
```

Save as `hrms_app/lib/models/payslip_line_item.dart`.

- [ ] **Step 2: Create the Payslip model**

```dart
import 'payslip_line_item.dart';

class Payslip {
  final String id;
  final String month;
  final String period;
  final String payDate;
  final String status;
  final List<PayslipLineItem> earnings;
  final List<PayslipLineItem> deductions;

  const Payslip({
    required this.id,
    required this.month,
    required this.period,
    required this.payDate,
    required this.status,
    required this.earnings,
    required this.deductions,
  });

  double get grossPay => earnings.fold(0.0, (sum, e) => sum + e.amount);
  double get totalDeductions => deductions.fold(0.0, (sum, d) => sum + d.amount);
  double get netPay => grossPay - totalDeductions;
}
```

Save as `hrms_app/lib/models/payslip.dart`.

- [ ] **Step 3: Update fake_data.dart**

In `hrms_app/lib/data/fake_data.dart`, add imports near the top with the
other model imports:

```dart
import '../models/payslip.dart';
import '../models/payslip_line_item.dart';
```

Add, anywhere after the class's other top-level constants (e.g. right
before `claimEntitlements`, or after `claims` — placement doesn't matter,
it's a sibling top-level constant):

```dart
  static const _standardEarnings = [
    PayslipLineItem(label: 'Basic salary', amount: 6000.00),
    PayslipLineItem(label: 'Allowance', amount: 500.00),
  ];

  static const _standardDeductions = [
    PayslipLineItem(label: 'EPF', amount: 700.00),
    PayslipLineItem(label: 'SOCSO', amount: 40.00),
    PayslipLineItem(label: 'EIS', amount: 10.00),
    PayslipLineItem(label: 'PCB', amount: 300.00),
  ];

  /// Most recent first — later code relies on payslips.first being the
  /// latest payslip.
  static const payslips = [
    Payslip(
      id: 'PS-2026-06',
      month: 'June 2026',
      period: '1 – 30 Jun 2026',
      payDate: 'Jun 28',
      status: 'Paid',
      earnings: _standardEarnings,
      deductions: _standardDeductions,
    ),
    Payslip(
      id: 'PS-2026-05',
      month: 'May 2026',
      period: '1 – 31 May 2026',
      payDate: 'May 29',
      status: 'Paid',
      earnings: _standardEarnings,
      deductions: _standardDeductions,
    ),
    Payslip(
      id: 'PS-2026-04',
      month: 'April 2026',
      period: '1 – 30 Apr 2026',
      payDate: 'Apr 29',
      status: 'Paid',
      earnings: _standardEarnings,
      deductions: _standardDeductions,
    ),
    Payslip(
      id: 'PS-2026-03',
      month: 'March 2026',
      period: '1 – 31 Mar 2026',
      payDate: 'Mar 27',
      status: 'Paid',
      earnings: _standardEarnings,
      deductions: _standardDeductions,
    ),
    Payslip(
      id: 'PS-2026-02',
      month: 'February 2026',
      period: '1 – 28 Feb 2026',
      payDate: 'Feb 27',
      status: 'Paid',
      earnings: _standardEarnings,
      deductions: _standardDeductions,
    ),
  ];
```

- [ ] **Step 4: Run the full test suite to confirm nothing broke**

Run: `cd hrms_app && flutter test`
Expected: All existing tests still PASS (purely additive constants).

- [ ] **Step 5: Commit**

```bash
git add hrms_app/lib/models/payslip_line_item.dart hrms_app/lib/models/payslip.dart hrms_app/lib/data/fake_data.dart
git commit -m "feat: add Payslip/PayslipLineItem models and fake payslip data"
```

---

### Task 2: AppState.payslips getter

**Files:**
- Modify: `hrms_app/lib/state/app_state.dart`
- Modify: `hrms_app/test/app_state_test.dart`

**Interfaces:**
- Consumes: `FakeData.payslips` (Task 1).
- Produces: `AppState.payslips` (`List<Payslip>`, direct passthrough to
  `FakeData.payslips` — no mutation needed since this phase has no
  submission flow, unlike `myLeaveRequests`/`claims`). Later tasks (4, 5)
  read this getter.

- [ ] **Step 1: Write the failing test**

Add to `hrms_app/test/app_state_test.dart` (append inside the existing
`main()`, after the current tests):

```dart
  test('payslips exposes payslip history with the latest first', () {
    final appState = AppState();
    expect(appState.payslips, isNotEmpty);
    expect(appState.payslips.first.month, 'June 2026');
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd hrms_app && flutter test test/app_state_test.dart`
Expected: FAIL — `payslips` doesn't exist on `AppState` yet (compile
error), or `Payslip`/`FakeData.payslips` aren't imported.

- [ ] **Step 3: Write the minimal implementation**

In `hrms_app/lib/state/app_state.dart`, add an import at the top (with
the existing model imports):

```dart
import '../models/payslip.dart';
```

Add, after the `attendanceHistoryStats` getter, before the `clockIn()`
method:

```dart
  List<Payslip> get payslips => FakeData.payslips;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd hrms_app && flutter test test/app_state_test.dart`
Expected: PASS (all tests in the file, including the new one)

- [ ] **Step 5: Commit**

```bash
git add hrms_app/lib/state/app_state.dart hrms_app/test/app_state_test.dart
git commit -m "feat: add AppState.payslips getter"
```

---

### Task 3: PayslipDetailScreen

**Files:**
- Create: `hrms_app/lib/screens/payslip/payslip_detail_screen.dart`
- Test: `hrms_app/test/payslip_detail_screen_test.dart`

**Interfaces:**
- Consumes: `Payslip`, `PayslipLineItem` models (Task 1), `formatCurrency`
  (already exists from Phase 6, at `hrms_app/lib/utils/currency.dart`).
- Produces: `PayslipDetailScreen({required Payslip payslip})`. Used by
  Task 4 (`PayslipScreen` navigates to it via `Navigator.push`).

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_app/models/payslip.dart';
import 'package:hrms_app/models/payslip_line_item.dart';
import 'package:hrms_app/screens/payslip/payslip_detail_screen.dart';

const _payslip = Payslip(
  id: 'PS-2026-06',
  month: 'June 2026',
  period: '1 – 30 Jun 2026',
  payDate: 'Jun 28',
  status: 'Paid',
  earnings: [
    PayslipLineItem(label: 'Basic salary', amount: 6000.00),
    PayslipLineItem(label: 'Allowance', amount: 500.00),
  ],
  deductions: [
    PayslipLineItem(label: 'EPF', amount: 700.00),
    PayslipLineItem(label: 'SOCSO', amount: 40.00),
    PayslipLineItem(label: 'EIS', amount: 10.00),
    PayslipLineItem(label: 'PCB', amount: 300.00),
  ],
);

void main() {
  testWidgets('shows month title, net pay, earnings, deductions, and download button', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PayslipDetailScreen(payslip: _payslip)),
    );

    expect(find.text('June 2026'), findsOneWidget);
    expect(find.text('RM 5,450.00'), findsWidgets);
    expect(find.text('Basic salary'), findsOneWidget);
    expect(find.text('RM 6,500.00'), findsOneWidget);
    expect(find.text('EPF'), findsOneWidget);
    expect(find.text('− RM 1,050.00'), findsOneWidget);
    expect(find.text('Payslip PS-2026-06'), findsOneWidget);

    await tester.tap(find.text('Download PDF'));
    await tester.pump();

    expect(find.text("Downloading isn't available in this preview"), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd hrms_app && flutter test test/payslip_detail_screen_test.dart`
Expected: FAIL — `payslip_detail_screen.dart` doesn't exist yet.

- [ ] **Step 3: Write minimal implementation**

```dart
import 'package:flutter/material.dart';
import '../../models/payslip.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency.dart';

class PayslipDetailScreen extends StatelessWidget {
  final Payslip payslip;

  const PayslipDetailScreen({super.key, required this.payslip});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text(payslip.month, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NET PAY',
                  style: TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontWeight: FontWeight.w700, letterSpacing: 1.0),
                ),
                const SizedBox(height: 6),
                Text('RM ${formatCurrency(payslip.netPay)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 3),
                Text('${payslip.period} · Paid ${payslip.payDate}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text('Earnings', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13),
            decoration: BoxDecoration(color: AppColors.cardBackground, border: Border.all(color: const Color(0xFFEEF2F6)), borderRadius: BorderRadius.circular(11)),
            child: Column(
              children: [
                for (final e in payslip.earnings)
                  Container(
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.label, style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
                        Text('RM ${formatCurrency(e.amount)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Gross pay', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                      Text('RM ${formatCurrency(payslip.grossPay)}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text('Deductions', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13),
            decoration: BoxDecoration(color: AppColors.cardBackground, border: Border.all(color: const Color(0xFFEEF2F6)), borderRadius: BorderRadius.circular(11)),
            child: Column(
              children: [
                for (final d in payslip.deductions)
                  Container(
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(d.label, style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
                        Text('− RM ${formatCurrency(d.amount)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFB91C1C))),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total deductions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                      Text('− RM ${formatCurrency(payslip.totalDeductions)}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFFB91C1C))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(color: AppColors.primaryTint, borderRadius: BorderRadius.circular(11)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Net pay', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF065F46))),
                Text('RM ${formatCurrency(payslip.netPay)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF059669))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Downloading isn't available in this preview")),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.download_outlined, color: Colors.white, size: 18),
              label: const Text('Download PDF', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            'Payslip ${payslip.id}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd hrms_app && flutter test test/payslip_detail_screen_test.dart`
Expected: PASS (1 test)

- [ ] **Step 5: Commit**

```bash
git add hrms_app/lib/screens/payslip/payslip_detail_screen.dart hrms_app/test/payslip_detail_screen_test.dart
git commit -m "feat: add PayslipDetailScreen"
```

---

### Task 4: PayslipScreen

**Files:**
- Create: `hrms_app/lib/screens/payslip/payslip_screen.dart`
- Test: `hrms_app/test/payslip_screen_test.dart`

**Interfaces:**
- Consumes: `AppState.payslips` (Task 2), `formatCurrency` (existing,
  Phase 6), `PayslipDetailScreen` (Task 3).
- Produces: `PayslipScreen` (no constructor params). Used by Task 5
  (Home's `QuickActionsRow` "Payslip" tile) and Task 6 (Profile's
  "Payslips" menu item), both navigating to it via `Navigator.push`.

- [ ] **Step 1: Write the failing tests**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hrms_app/screens/payslip/payslip_screen.dart';
import 'package:hrms_app/state/app_state.dart';

void main() {
  testWidgets('shows the latest payslip summary and full history', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const MaterialApp(home: PayslipScreen()),
      ),
    );

    expect(find.text('Payslip history'), findsOneWidget);
    expect(find.text('View details'), findsOneWidget);
    expect(find.text('June 2026'), findsOneWidget);
    expect(find.text('May 2026'), findsOneWidget);
  });

  testWidgets('tapping View details opens the latest payslip detail screen', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const MaterialApp(home: PayslipScreen()),
      ),
    );

    await tester.tap(find.text('View details'));
    await tester.pumpAndSettle();

    expect(find.text('Payslip PS-2026-06'), findsOneWidget);
  });

  testWidgets('tapping a payslip row opens its own detail screen', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const MaterialApp(home: PayslipScreen()),
      ),
    );

    await tester.tap(find.text('May 2026'));
    await tester.pumpAndSettle();

    expect(find.text('Payslip PS-2026-05'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd hrms_app && flutter test test/payslip_screen_test.dart`
Expected: FAIL — `payslip_screen.dart` doesn't exist yet.

- [ ] **Step 3: Write minimal implementation**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency.dart';
import 'payslip_detail_screen.dart';

class PayslipScreen extends StatelessWidget {
  const PayslipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final payslips = context.watch<AppState>().payslips;
    final latest = payslips.first;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Payslip', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LATEST · ${latest.month.toUpperCase()}',
                  style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontWeight: FontWeight.w700, letterSpacing: 1.0),
                ),
                const SizedBox(height: 6),
                Text('RM ${formatCurrency(latest.netPay)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
                Text('Net pay · Paid ${latest.payDate}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => PayslipDetailScreen(payslip: latest)),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('View details', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text('Payslip history', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          for (final p in payslips)
            Card(
              margin: const EdgeInsets.only(bottom: 7),
              child: InkWell(
                borderRadius: BorderRadius.circular(11),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => PayslipDetailScreen(payslip: p)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.month, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                            Text('Paid ${p.payDate} · ${p.id}', style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('RM ${formatCurrency(p.netPay)}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.primaryTint, borderRadius: BorderRadius.circular(999)),
                            child: Text(p.status, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
                          ),
                        ],
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right, size: 15, color: Color(0xFFCBD5E1)),
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

Run: `cd hrms_app && flutter test test/payslip_screen_test.dart`
Expected: PASS (3 tests)

- [ ] **Step 5: Commit**

```bash
git add hrms_app/lib/screens/payslip/payslip_screen.dart hrms_app/test/payslip_screen_test.dart
git commit -m "feat: add PayslipScreen"
```

---

### Task 5: Wire the "Payslip" quick action on Home

**Files:**
- Modify: `hrms_app/lib/widgets/quick_actions_row.dart`
- Modify: `hrms_app/lib/screens/home/home_screen.dart`
- Modify: `hrms_app/test/home_screen_test.dart`

**Interfaces:**
- Consumes: `PayslipScreen` (Task 4).
- Produces: `QuickActionsRow`'s constructor gains a second required
  callback: `const QuickActionsRow({super.key, required VoidCallback
  onClaimsTap, required VoidCallback onPayslipTap})` — another breaking
  signature change to the same widget Phase 6 already changed once. The
  only call site is `hrms_app/lib/screens/home/home_screen.dart`, which
  this task also updates. Attendance/Leave tiles remain visual-only
  (still no callback for them — out of scope, same as Phase 6's note).

- [ ] **Step 1: Write the failing test**

Add to `hrms_app/test/home_screen_test.dart` (append inside `main()`,
after the existing `testWidgets`):

```dart
  testWidgets('tapping the Payslip quick action opens the Payslip screen', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const MaterialApp(home: Scaffold(body: HomeScreen())),
      ),
    );

    await tester.tap(find.text('Payslip'));
    await tester.pumpAndSettle();

    expect(find.text('Payslip history'), findsOneWidget);
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd hrms_app && flutter test test/home_screen_test.dart`
Expected: FAIL — tapping "Payslip" currently does nothing, and
`QuickActionsRow` doesn't yet accept an `onPayslipTap` param, so this
also won't compile until Step 3 (write the test first anyway per TDD,
same as Phase 6's Task 9 handled this).

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
/// Payslip. Claims and Payslip are wired to navigation (Phase 6, Phase
/// 7); Attendance/Leave remain display-only until a later phase gives
/// them somewhere real to go.
class QuickActionsRow extends StatelessWidget {
  final VoidCallback onClaimsTap;
  final VoidCallback onPayslipTap;

  const QuickActionsRow({super.key, required this.onClaimsTap, required this.onPayslipTap});

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
        if (action.label == 'Payslip') {
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onPayslipTap,
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
import '../payslip/payslip_screen.dart';
```

Replace:

```dart
          QuickActionsRow(
            onClaimsTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ClaimsScreen()),
            ),
          ),
```

with:

```dart
          QuickActionsRow(
            onClaimsTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ClaimsScreen()),
            ),
            onPayslipTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PayslipScreen()),
            ),
          ),
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd hrms_app && flutter test test/home_screen_test.dart`
Expected: PASS (3 tests)

- [ ] **Step 5: Commit**

```bash
git add hrms_app/lib/widgets/quick_actions_row.dart hrms_app/lib/screens/home/home_screen.dart hrms_app/test/home_screen_test.dart
git commit -m "feat: wire the Home tab's Payslip quick action"
```

---

### Task 6: Wire the "Payslips" menu item on Profile

**Files:**
- Modify: `hrms_app/lib/screens/profile/profile_screen.dart`
- Modify: `hrms_app/test/profile_screen_test.dart`

**Interfaces:**
- Consumes: `PayslipScreen` (Task 4).
- Produces: Profile's "Payslips" `_MenuTile` now navigates to the real
  `PayslipScreen` instead of `ComingSoonScreen(title: 'Payslips')`. This
  is the second of Payslip's two entry points (the first was Task 5).

- [ ] **Step 1: Write the failing test**

Add to `hrms_app/test/profile_screen_test.dart` (append inside `main()`,
after the existing `testWidgets`):

```dart
  testWidgets('tapping Payslips opens the payslip screen', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const MaterialApp(home: Scaffold(body: ProfileScreen())),
      ),
    );

    await tester.tap(find.text('Payslips'));
    await tester.pumpAndSettle();

    expect(find.text('Payslip history'), findsOneWidget);
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd hrms_app && flutter test test/profile_screen_test.dart`
Expected: FAIL — tapping "Payslips" currently opens the `ComingSoonScreen`
placeholder, which has no "Payslip history" text.

- [ ] **Step 3: Write the minimal implementation**

In `hrms_app/lib/screens/profile/profile_screen.dart`, add an import
near the top:

```dart
import '../payslip/payslip_screen.dart';
```

Replace the "Payslips" `_MenuTile`:

```dart
                _MenuTile(
                  icon: Icons.receipt_long_outlined,
                  iconBg: AppColors.warningTint,
                  iconColor: AppColors.warning,
                  label: 'Payslips',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ComingSoonScreen(title: 'Payslips'),
                    ),
                  ),
                ),
```

with:

```dart
                _MenuTile(
                  icon: Icons.receipt_long_outlined,
                  iconBg: AppColors.warningTint,
                  iconColor: AppColors.warning,
                  label: 'Payslips',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PayslipScreen()),
                  ),
                ),
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd hrms_app && flutter test test/profile_screen_test.dart`
Expected: PASS (5 tests)

- [ ] **Step 5: Commit**

```bash
git add hrms_app/lib/screens/profile/profile_screen.dart hrms_app/test/profile_screen_test.dart
git commit -m "feat: wire the Profile tab's Payslips menu item"
```

---

### Task 7: End-to-end payslip viewing flow test + full suite/build verification

**Files:**
- Test: `hrms_app/test/payslip_viewing_flow_test.dart`

This is the integration test tying the whole feature together: from
Home's "Payslip" quick action, through the payslip list, into the latest
payslip's full detail view.

**Interfaces:**
- Consumes: `HomeScreen` (Task 5) and everything it now transitively
  wires up.

- [ ] **Step 1: Write the test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hrms_app/screens/home/home_screen.dart';
import 'package:hrms_app/state/app_state.dart';

void main() {
  testWidgets('full flow: open Payslip from Home and view the latest payslip detail', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const MaterialApp(home: Scaffold(body: HomeScreen())),
      ),
    );

    await tester.tap(find.text('Payslip'));
    await tester.pumpAndSettle();

    expect(find.text('Payslip history'), findsOneWidget);
    expect(find.text('May 2026'), findsOneWidget);

    await tester.tap(find.text('View details'));
    await tester.pumpAndSettle();

    expect(find.text('June 2026'), findsOneWidget);
    expect(find.text('Payslip PS-2026-06'), findsOneWidget);
    expect(find.text('Earnings'), findsOneWidget);
    expect(find.text('Deductions'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it passes**

Run: `cd hrms_app && flutter test test/payslip_viewing_flow_test.dart`
Expected: PASS (1 test). If a lazy-`ListView`-build issue prevents a
widget from being tapped/found — this has happened in earlier phases
with `ListView`-based screens — fix it in the test file only, using the
same established fix already used repeatedly: grow `tester.view.
physicalSize` for the test with `addTearDown` resets, test-file-only.
Diagnose first — only apply if you actually hit that failure mode. Do
not change any `lib/` file to work around a test-only viewport
limitation.

- [ ] **Step 3: Run the entire test suite**

Run: `cd hrms_app && flutter test`
Expected: PASS — every test file, old and new, green.

- [ ] **Step 4: Verify the web build still compiles**

Run: `cd hrms_app && flutter build web`
Expected: Build succeeds with no errors (this is the project's Android-
build-blocked verification path — see Global Constraints).

- [ ] **Step 5: Commit**

```bash
git add hrms_app/test/payslip_viewing_flow_test.dart
git commit -m "test: add end-to-end payslip viewing flow test"
```

---

## After all tasks: whole-branch review

Once every task above is committed, do a final whole-branch review pass
(per `superpowers:subagent-driven-development`) covering:
- Every new/changed file compiles and all `flutter test` suites pass.
- The "dumb widget" convention held: `lib/widgets/quick_actions_row.dart`
  takes only constructor params/callbacks, no `Navigator` calls inside
  the widget itself — both `onClaimsTap` and `onPayslipTap` are invoked
  by the widget but the actual `Navigator.push` calls live in
  `home_screen.dart`, not in `quick_actions_row.dart`.
- Both entry points (Home quick action, Profile menu item) genuinely
  push the same `PayslipScreen` and behave identically.
- `Payslip.netPay`/`grossPay`/`totalDeductions` stay internally
  consistent everywhere they're displayed (dark summary card, history
  row, detail screen) since they're computed getters, not separately
  hardcoded numbers — re-verify this holds across all three render
  sites now that everything is integrated.
- No stray `print()`/debug statements, no TODOs.
- `git branch --show-current` is still `main`, `git remote -v` still
  only points at `https://github.com/nurlynnda/HRMS.git` — no
  unauthorized branch/remote changes across all 7 tasks' subagent runs.
- Then, per the established push policy, **ask the user before pushing**.
