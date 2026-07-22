# Phase 8: Login Screen, Entry Gate, and Visual Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Login screen, wire it as the app's real entry gate (the app opens
on Login and only shows the tab shell once "signed in"), wire the existing
"Log out" button in the Profile tab to actually sign the user back out, and do
a small visual-polish pass (consolidate a repeated inline color into the shared
theme).

**Architecture:** `AppState` gains an `isLoggedIn` flag plus `logIn()`/`logOut()`
methods, following the exact mutate-then-`notifyListeners()` pattern already
used by `clockIn()`/`clockOut()`/`submitLeaveRequest()`/`submitClaim()`.
`HrmsApp`'s `home:` becomes a `Consumer<AppState>` that shows `LoginScreen`
when logged out and `MainTabShell` when logged in — the Flutter-idiomatic
equivalent of the mockup's `position:absolute;inset:0` login overlay (swap
the whole screen rather than stacking, matching how every other full-screen
overlay in this app already works via `Navigator.push`). `LoginScreen` reuses
the existing `FaceCheckInOverlay` widget (generalized with optional
title/subtitle) for its "Sign in with Face ID" button, exactly as the design
spec calls for ("shared by clock-in and login").

**Tech Stack:** Flutter, Provider (`ChangeNotifier`), existing `AppTheme`/
`AppColors` design tokens. No new packages.

## Global Constraints

- Face check-in/sign-in stays **SIMULATED**, not real, in this phase. The
  `local_auth` package still can't be verified here: Android builds remain
  blocked by the unrelated `java.io.IOException: Unable to establish
  loopback connection` environment bug (unchanged since Phase 3), and
  `local_auth` doesn't support web. **Do not add the `local_auth`
  dependency.** `FaceCheckInOverlay`'s existing timed `Future.delayed`
  simulation (scanning → verifying → success, always succeeds) is reused
  as-is, just with generalized title/subtitle text so Login can use it too.
- Verification: `flutter analyze` clean, `flutter test` all passing (no
  Android emulator available — Chrome/web build + widget tests are the
  verification path, same as every prior phase).
- Currency/copy/colors: reuse existing `AppColors` tokens
  (`lib/theme/app_theme.dart`) — don't invent new inline hex colors where a
  token already exists or is being added in this plan.
- Follow the existing "dumb widget" convention: files under `lib/widgets/`
  take data via constructor params/callbacks only, no `Navigator` calls to
  screens they don't own. `FaceCheckInOverlay` already returns a `bool` via
  `Navigator.pop()` — keep that contract unchanged.

---

## Task 1: `AppState` auth state (`isLoggedIn`, `logIn()`, `logOut()`)

**Files:**
- Modify: `hrms_app/lib/state/app_state.dart`
- Test: `hrms_app/test/app_state_test.dart`

**Interfaces:**
- Produces: `AppState.isLoggedIn` (`bool`, starts `false`), `AppState.logIn()`
  (sets `isLoggedIn = true`, calls `notifyListeners()`), `AppState.logOut()`
  (sets `isLoggedIn = false`, calls `notifyListeners()`). Later tasks
  (LoginScreen, the app entry gate, ProfileScreen's Log out button) all call
  these.

- [ ] **Step 1: Write the failing tests**

Add to the end of `hrms_app/test/app_state_test.dart` (inside the existing
`void main() { ... }`, after the last `test(...)` block):

```dart
  test('isLoggedIn starts false', () {
    final appState = AppState();
    expect(appState.isLoggedIn, isFalse);
  });

  test('logIn() sets isLoggedIn to true and notifies', () {
    final appState = AppState();
    var notified = false;
    appState.addListener(() => notified = true);

    appState.logIn();

    expect(appState.isLoggedIn, isTrue);
    expect(notified, isTrue);
  });

  test('logOut() sets isLoggedIn to false and notifies', () {
    final appState = AppState();
    appState.logIn();
    var notified = false;
    appState.addListener(() => notified = true);

    appState.logOut();

    expect(appState.isLoggedIn, isFalse);
    expect(notified, isTrue);
  });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd hrms_app && flutter test test/app_state_test.dart`
Expected: FAIL — `The getter 'isLoggedIn' isn't defined for the type 'AppState'`
(and similarly for `logIn`/`logOut`).

- [ ] **Step 3: Implement `isLoggedIn`/`logIn()`/`logOut()`**

In `hrms_app/lib/state/app_state.dart`, add a field+getter right after the
`employee` getter (after line 26, `Employee get employee => FakeData.employee;`):

```dart
  Employee get employee => FakeData.employee;

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;
```

Then add the two methods at the very end of the class, right after
`submitClaim(...)`'s closing brace (after line 143, before the class's final
`}` on line 144):

```dart
  /// Signs the user in. Mirrors clockIn()/clockOut(): mutate internal
  /// state, notify.
  void logIn() {
    _isLoggedIn = true;
    notifyListeners();
  }

  /// Signs the user out. Mirrors logIn().
  void logOut() {
    _isLoggedIn = false;
    notifyListeners();
  }
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd hrms_app && flutter test test/app_state_test.dart`
Expected: PASS (all tests, including the 3 new ones).

- [ ] **Step 5: Commit**

```bash
git add hrms_app/lib/state/app_state.dart hrms_app/test/app_state_test.dart
git commit -m "feat: add AppState.isLoggedIn/logIn()/logOut()"
```

---

## Task 2: Generalize `FaceCheckInOverlay` for reuse by Login

**Files:**
- Modify: `hrms_app/lib/widgets/face_check_in_overlay.dart`
- Test: `hrms_app/test/face_check_in_overlay_test.dart` (new)

**Interfaces:**
- Consumes: nothing new.
- Produces: `FaceCheckInOverlay({required bool clockingIn, String? title,
  String? subtitle})`. When `title`/`subtitle` are omitted, behavior is
  byte-for-byte identical to before (`'Face Check-in'`/`'Face Check-out'` and
  `'Verify your identity to clock in'`/`'...clock out'`). `LoginScreen`
  (Task 3) passes explicit `title`/`subtitle` overrides. Still returns
  `bool` via `Navigator.pop()` on completion/cancel — unchanged contract.

- [ ] **Step 1: Write the failing test**

Create `hrms_app/test/face_check_in_overlay_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_app/widgets/face_check_in_overlay.dart';

void main() {
  testWidgets('defaults to clock-in title/subtitle when clockingIn is true', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: FaceCheckInOverlay(clockingIn: true)),
    );

    expect(find.text('Face Check-in'), findsOneWidget);
    expect(find.text('Verify your identity to clock in'), findsOneWidget);
  });

  testWidgets('uses the given title/subtitle when provided', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FaceCheckInOverlay(
          clockingIn: true,
          title: 'Face ID Sign In',
          subtitle: 'Verify your identity to sign in',
        ),
      ),
    );

    expect(find.text('Face ID Sign In'), findsOneWidget);
    expect(find.text('Verify your identity to sign in'), findsOneWidget);
    expect(find.text('Face Check-in'), findsNothing);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd hrms_app && flutter test test/face_check_in_overlay_test.dart`
Expected: FAIL to compile — `No named parameter with the name 'title'`
(the second test's constructor call doesn't match the current widget).

- [ ] **Step 3: Add optional `title`/`subtitle` overrides**

In `hrms_app/lib/widgets/face_check_in_overlay.dart`, change the class
fields/constructor (replacing the current `final bool clockingIn;` +
constructor block):

```dart
class FaceCheckInOverlay extends StatefulWidget {
  final bool clockingIn;
  final String? title;
  final String? subtitle;

  const FaceCheckInOverlay({
    super.key,
    required this.clockingIn,
    this.title,
    this.subtitle,
  });
```

Then in `_FaceCheckInOverlayState.build()`, replace this line:

```dart
    final verb = widget.clockingIn ? 'in' : 'out';
```

with:

```dart
    final verb = widget.clockingIn ? 'in' : 'out';
    final title = widget.title ?? 'Face Check-$verb';
    final subtitle = widget.subtitle ?? 'Verify your identity to clock $verb';
```

And update the two `Text` widgets right below that currently read
`'Face Check-$verb'` and `'Verify your identity to clock $verb'` to use the
new local variables instead:

```dart
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd hrms_app && flutter test test/face_check_in_overlay_test.dart`
Expected: PASS (both tests).

- [ ] **Step 5: Run the full suite to check for regressions**

Run: `cd hrms_app && flutter test`
Expected: PASS, no regressions (Attendance's existing `FaceCheckInOverlay`
usage doesn't pass `title`/`subtitle`, so its behavior is unchanged).

- [ ] **Step 6: Commit**

```bash
git add hrms_app/lib/widgets/face_check_in_overlay.dart hrms_app/test/face_check_in_overlay_test.dart
git commit -m "feat: allow FaceCheckInOverlay title/subtitle overrides for reuse in Login"
```

---

## Task 3: `LoginScreen`

**Files:**
- Create: `hrms_app/lib/screens/login/login_screen.dart`
- Test: `hrms_app/test/login_screen_test.dart` (new)

**Interfaces:**
- Consumes: `AppState.isLoggedIn`/`logIn()` (Task 1),
  `FaceCheckInOverlay({required clockingIn, title, subtitle})` (Task 2).
- Produces: `LoginScreen` (no constructor params beyond `key`) — a
  `StatefulWidget` with a `Scaffold` body. Later Task 4 pushes this into
  `HrmsApp`'s `home:` gate.

- [ ] **Step 1: Write the failing tests**

Create `hrms_app/test/login_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hrms_app/screens/login/login_screen.dart';
import 'package:hrms_app/state/app_state.dart';

void main() {
  Widget wrap(AppState appState) => ChangeNotifierProvider.value(
        value: appState,
        child: const MaterialApp(home: LoginScreen()),
      );

  testWidgets('shows the welcome header, form fields, and buttons', (tester) async {
    await tester.pumpWidget(wrap(AppState()));

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in to your employee account.'), findsOneWidget);
    expect(find.text('Work email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Sign in with Face ID'), findsOneWidget);
    expect(find.text('Need help? Contact your HR admin'), findsOneWidget);
  });

  testWidgets('Sign in button is disabled until both fields are filled', (tester) async {
    await tester.pumpWidget(wrap(AppState()));

    ElevatedButton signInButton() =>
        tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Sign in'));

    expect(signInButton().onPressed, isNull);

    await tester.enterText(find.byKey(const Key('loginEmailField')), 'sarah.chen@company.com');
    await tester.pump();
    expect(signInButton().onPressed, isNull);

    await tester.enterText(find.byKey(const Key('loginPasswordField')), 'password');
    await tester.pump();
    expect(signInButton().onPressed, isNotNull);
  });

  testWidgets('tapping Sign in logs the user in', (tester) async {
    final appState = AppState();
    await tester.pumpWidget(wrap(appState));

    await tester.enterText(find.byKey(const Key('loginEmailField')), 'sarah.chen@company.com');
    await tester.enterText(find.byKey(const Key('loginPasswordField')), 'password');
    await tester.pump();

    expect(appState.isLoggedIn, isFalse);
    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(appState.isLoggedIn, isTrue);
  });

  testWidgets('tapping Show/Hide toggles password obscuring', (tester) async {
    await tester.pumpWidget(wrap(AppState()));

    TextField passwordField() =>
        tester.widget<TextField>(find.byKey(const Key('loginPasswordField')));

    expect(passwordField().obscureText, isTrue);
    expect(find.text('Show'), findsOneWidget);

    await tester.tap(find.text('Show'));
    await tester.pump();

    expect(passwordField().obscureText, isFalse);
    expect(find.text('Hide'), findsOneWidget);
  });

  testWidgets('tapping Forgot password shows a not-available message', (tester) async {
    await tester.pumpWidget(wrap(AppState()));

    await tester.tap(find.text('Forgot password?'));
    await tester.pump();

    expect(find.text("Password reset isn't available in this preview"), findsOneWidget);
  });

  testWidgets('tapping Sign in with Face ID completes the flow and logs the user in', (tester) async {
    final appState = AppState();
    await tester.pumpWidget(wrap(appState));

    expect(appState.isLoggedIn, isFalse);
    await tester.tap(find.text('Sign in with Face ID'));
    await tester.pump();

    expect(find.text('Face ID Sign In'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(appState.isLoggedIn, isTrue);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd hrms_app && flutter test test/login_screen_test.dart`
Expected: FAIL to compile — `Target of URI doesn't exist:
'package:hrms_app/screens/login/login_screen.dart'`.

- [ ] **Step 3: Implement `LoginScreen`**

Create `hrms_app/lib/screens/login/login_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/face_check_in_overlay.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _emailController.text.trim().isNotEmpty &&
      _passwordController.text.trim().isNotEmpty;

  void _handleSignIn() {
    context.read<AppState>().logIn();
  }

  Future<void> _handleFaceIdSignIn() async {
    final verified = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const FaceCheckInOverlay(
          clockingIn: true,
          title: 'Face ID Sign In',
          subtitle: 'Verify your identity to sign in',
        ),
        fullscreenDialog: true,
      ),
    );
    if (verified == true && mounted) {
      context.read<AppState>().logIn();
    }
  }

  void _handleForgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Password reset isn't available in this preview"),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hintText) => InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(26, 24, 26, 34),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'HR',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
              ),
              const SizedBox(height: 26),
              const Text(
                'Welcome back',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Sign in to your employee account.',
                style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 30),
              const Text(
                'Work email',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('loginEmailField'),
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _fieldDecoration('you@company.com'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Password',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      _obscurePassword ? 'Show' : 'Hide',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('loginPasswordField'),
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: _fieldDecoration('Enter your password'),
                onChanged: (_) => setState(() {}),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _handleForgotPassword,
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _canSubmit ? _handleSignIn : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: const Color(0xFFCBD5E1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: const Text(
                    'Sign in',
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  const Expanded(child: Divider(color: Color(0xFFEEF2F6))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'or',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: Color(0xFFEEF2F6))),
                ],
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _handleFaceIdSignIn,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  icon: const Icon(
                    Icons.face_retouching_natural,
                    size: 19,
                    color: AppColors.primary,
                  ),
                  label: const Text(
                    'Sign in with Face ID',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'Need help? Contact your HR admin',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd hrms_app && flutter test test/login_screen_test.dart`
Expected: PASS (all 6 tests).

- [ ] **Step 5: Format and analyze**

Run: `cd hrms_app && dart format lib/screens/login/login_screen.dart test/login_screen_test.dart && flutter analyze lib/screens/login/login_screen.dart`
Expected: files formatted, no analyzer issues.

- [ ] **Step 6: Commit**

```bash
git add hrms_app/lib/screens/login/login_screen.dart hrms_app/test/login_screen_test.dart
git commit -m "feat: add LoginScreen"
```

---

## Task 4: Wire Login as the app's entry gate

**Files:**
- Modify: `hrms_app/lib/app.dart`
- Modify: `hrms_app/test/app_test.dart`
- Test: `hrms_app/test/login_flow_test.dart` (new)

**Interfaces:**
- Consumes: `AppState.isLoggedIn` (Task 1), `LoginScreen` (Task 3),
  `MainTabShell` (existing, unchanged).
- Produces: `HrmsApp` now starts on `LoginScreen` and switches to
  `MainTabShell` once `AppState.isLoggedIn` is `true`. This changes the
  starting point for every existing test that pumps `HrmsApp` directly, so
  `app_test.dart` needs a login step added to each test.

- [ ] **Step 1: Write the failing test (new email/password login flow)**

Create `hrms_app/test/login_flow_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_app/app.dart';

void main() {
  testWidgets('signing in with email and password reaches the Home tab', (tester) async {
    await tester.pumpWidget(const HrmsApp());

    expect(find.text('Welcome back'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('loginEmailField')), 'sarah.chen@company.com');
    await tester.enterText(find.byKey(const Key('loginPasswordField')), 'password');
    await tester.pump();

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsNothing);
    expect(find.text('Sarah Chen'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd hrms_app && flutter test test/login_flow_test.dart`
Expected: FAIL — `find.text('Welcome back')` finds 0 widgets, because
`HrmsApp` currently opens directly on `MainTabShell` (Home tab), not Login.

- [ ] **Step 3: Wire the entry gate in `app.dart`**

In `hrms_app/lib/app.dart`, add the import (after the existing `theme/app_theme.dart`
import):

```dart
import 'theme/app_theme.dart';
import 'screens/login/login_screen.dart';
```

Then replace the `home: const MainTabShell(),` line inside `HrmsApp.build()`
with:

```dart
        home: Consumer<AppState>(
          builder: (context, appState, child) =>
              appState.isLoggedIn ? const MainTabShell() : const LoginScreen(),
        ),
```

The rest of `app.dart` (`MainTabShell` and its state class) is unchanged.

- [ ] **Step 4: Run the new test to verify it passes**

Run: `cd hrms_app && flutter test test/login_flow_test.dart`
Expected: PASS.

- [ ] **Step 5: Update `app_test.dart` to log in before each existing assertion**

Replace the full contents of `hrms_app/test/app_test.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_app/app.dart';

/// Finds an icon within the BottomNavigationBar specifically. Some icons
/// (e.g. attendance/leave) are reused by Home's quick-action shortcuts, so a
/// bare `find.byIcon` can match more than one widget once real dashboard
/// content is on screen.
Finder findNavIcon(IconData icon) => find.descendant(
      of: find.byType(BottomNavigationBar),
      matching: find.byIcon(icon),
    );

/// HrmsApp now gates on AppState.isLoggedIn (Phase 8), so every test starts
/// on LoginScreen. Sign in via the Face ID shortcut (fewer steps than
/// filling in the email/password fields) to reach the tab shell.
Future<void> logIn(WidgetTester tester) async {
  await tester.tap(find.text('Sign in with Face ID'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 900));
  await tester.pump(const Duration(milliseconds: 700));
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pumpAndSettle();
}

void main() {
  group('HrmsApp Navigation Tests', () {
    testWidgets('HrmsApp loads with Home tab selected by default', (WidgetTester tester) async {
      await tester.pumpWidget(const HrmsApp());
      await logIn(tester);

      // Verify Home tab is selected (index 0) by checking IndexedStack.index
      expect(
        tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
        equals(0),
      );
      // Verify BottomNavigationBar also shows Home as current
      expect(
        tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar)).currentIndex,
        equals(0),
      );
    });

    testWidgets('Tapping Attendance tab switches to Attendance screen', (WidgetTester tester) async {
      await tester.pumpWidget(const HrmsApp());
      await logIn(tester);

      // Find and tap the Attendance bottom nav item
      await tester.tap(findNavIcon(Icons.access_time_outlined));
      await tester.pumpAndSettle();

      // Verify Attendance tab is now selected (index 1) by checking IndexedStack.index
      expect(
        tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
        equals(1),
      );
      // Verify BottomNavigationBar also shows Attendance as current
      expect(
        tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar)).currentIndex,
        equals(1),
      );
    });

    testWidgets('Tapping Leave tab switches to Leave screen', (WidgetTester tester) async {
      await tester.pumpWidget(const HrmsApp());
      await logIn(tester);

      // Find and tap the Leave bottom nav item
      await tester.tap(findNavIcon(Icons.event_note_outlined));
      await tester.pumpAndSettle();

      // Verify Leave tab is now selected (index 2) by checking IndexedStack.index
      expect(
        tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
        equals(2),
      );
      // Verify BottomNavigationBar also shows Leave as current
      expect(
        tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar)).currentIndex,
        equals(2),
      );
    });

    testWidgets('Tapping Me tab switches to Profile screen', (WidgetTester tester) async {
      await tester.pumpWidget(const HrmsApp());
      await logIn(tester);

      // Find and tap the Me (Profile) bottom nav item
      await tester.tap(findNavIcon(Icons.person_outline));
      await tester.pumpAndSettle();

      // Verify Me tab is now selected (index 3) by checking IndexedStack.index
      expect(
        tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
        equals(3),
      );
      // Verify BottomNavigationBar also shows Me as current
      expect(
        tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar)).currentIndex,
        equals(3),
      );
    });

    testWidgets('Navigation between multiple tabs works without errors', (WidgetTester tester) async {
      await tester.pumpWidget(const HrmsApp());
      await logIn(tester);

      // Verify initial Home tab (index 0)
      expect(
        tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
        equals(0),
      );

      // Navigate to Attendance (index 1)
      await tester.tap(findNavIcon(Icons.access_time_outlined));
      await tester.pumpAndSettle();
      expect(
        tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
        equals(1),
      );

      // Navigate back to Home (index 0)
      await tester.tap(findNavIcon(Icons.home_outlined));
      await tester.pumpAndSettle();
      expect(
        tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
        equals(0),
      );

      // Navigate to Leave (index 2)
      await tester.tap(findNavIcon(Icons.event_note_outlined));
      await tester.pumpAndSettle();
      expect(
        tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
        equals(2),
      );

      // Navigate to Me/Profile (index 3)
      await tester.tap(findNavIcon(Icons.person_outline));
      await tester.pumpAndSettle();
      expect(
        tester.widget<IndexedStack>(find.byType(IndexedStack)).index,
        equals(3),
      );
    });
  });
}
```

- [ ] **Step 6: Run the full suite**

Run: `cd hrms_app && flutter test`
Expected: PASS — all tests including `app_test.dart` (now logging in first)
and the new `login_flow_test.dart`.

- [ ] **Step 7: Format and analyze**

Run: `cd hrms_app && dart format lib/app.dart test/app_test.dart test/login_flow_test.dart && flutter analyze lib/app.dart`
Expected: files formatted, no analyzer issues.

- [ ] **Step 8: Commit**

```bash
git add hrms_app/lib/app.dart hrms_app/test/app_test.dart hrms_app/test/login_flow_test.dart
git commit -m "feat: wire LoginScreen as the app's entry gate"
```

---

## Task 5: Wire Profile's "Log out" button to real `logOut()`

**Files:**
- Modify: `hrms_app/lib/screens/profile/profile_screen.dart`
- Modify: `hrms_app/test/profile_screen_test.dart`

**Interfaces:**
- Consumes: `AppState.logOut()` (Task 1).
- Produces: nothing new — this only changes what the existing "Log out"
  button does. When reached through the real app (`HrmsApp`), tapping it now
  flips `AppState.isLoggedIn` to `false`, which the Task 4 gate picks up and
  swaps back to `LoginScreen`.

- [ ] **Step 1: Update the failing test**

In `hrms_app/test/profile_screen_test.dart`, replace this whole test block
(currently the last test in the file, `'tapping Log out shows a
not-available message'`):

```dart
  testWidgets('tapping Log out shows a not-available message', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const MaterialApp(home: Scaffold(body: ProfileScreen())),
      ),
    );

    await tester.tap(find.text('Log out'));
    await tester.pump();

    expect(
      find.text('Logging out is not available in this preview'),
      findsOneWidget,
    );
  });
```

with:

```dart
  testWidgets('tapping Log out logs the user out', (tester) async {
    final appState = AppState();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: const MaterialApp(home: Scaffold(body: ProfileScreen())),
      ),
    );

    appState.logIn();
    expect(appState.isLoggedIn, isTrue);

    await tester.tap(find.text('Log out'));
    await tester.pump();

    expect(appState.isLoggedIn, isFalse);
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd hrms_app && flutter test test/profile_screen_test.dart`
Expected: FAIL — `appState.isLoggedIn` is still `true` after the tap,
because the button currently just shows a `SnackBar` and doesn't call
`logOut()`.

- [ ] **Step 3: Wire the button to `AppState.logOut()`**

In `hrms_app/lib/screens/profile/profile_screen.dart`, find the "Log out"
`OutlinedButton.icon` and replace its `onPressed`:

```dart
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Logging out is not available in this preview'),
                ),
              ),
```

with:

```dart
              onPressed: () => context.read<AppState>().logOut(),
```

(`ProfileScreen` already imports `package:provider/provider.dart` and
`../../state/app_state.dart`, so no new imports are needed.)

- [ ] **Step 4: Run test to verify it passes**

Run: `cd hrms_app && flutter test test/profile_screen_test.dart`
Expected: PASS (all tests in the file).

- [ ] **Step 5: Run the full suite**

Run: `cd hrms_app && flutter test`
Expected: PASS, no regressions.

- [ ] **Step 6: Commit**

```bash
git add hrms_app/lib/screens/profile/profile_screen.dart hrms_app/test/profile_screen_test.dart
git commit -m "feat: wire Profile's Log out button to AppState.logOut()"
```

---

## Task 6: Visual polish — consolidate the repeated dark-card color

**Files:**
- Modify: `hrms_app/lib/theme/app_theme.dart`
- Modify: `hrms_app/lib/screens/claims/claims_screen.dart`
- Modify: `hrms_app/lib/screens/payslip/payslip_detail_screen.dart`
- Modify: `hrms_app/lib/screens/payslip/payslip_screen.dart`

**Interfaces:**
- Produces: `AppColors.darkCard` (`Color(0xFF0F172A)`), reused wherever the
  hardcoded hex was inline before. No visual change — same color value,
  just named once instead of repeated 4 times. (Flagged as a backlog item
  by Phase 7's final review; doing it now as this phase's visual-polish
  pass.)

- [ ] **Step 1: Write the failing test**

Add to `hrms_app/test/app_theme_test.dart`. First check whether this file
exists:

Run: `cd hrms_app && test -f test/app_theme_test.dart && echo exists || echo missing`

If it prints `missing`, create `hrms_app/test/app_theme_test.dart` with:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_app/theme/app_theme.dart';

void main() {
  test('AppColors.darkCard matches the dark summary-card color used across screens', () {
    expect(AppColors.darkCard.toARGB32(), equals(0xFF0F172A));
  });
}
```

If it prints `exists`, add the same `test(...)` block inside that file's
existing `void main() { ... }` instead of creating a new file.

- [ ] **Step 2: Run test to verify it fails**

Run: `cd hrms_app && flutter test test/app_theme_test.dart`
Expected: FAIL — `The getter 'darkCard' isn't defined for the type
'AppColors'`.

- [ ] **Step 3: Add the color token**

In `hrms_app/lib/theme/app_theme.dart`, add a new constant to `AppColors`
right after `static const ringTrack = Color(0xFFEEF2F6);`:

```dart
  static const ringTrack = Color(0xFFEEF2F6);
  static const darkCard = Color(0xFF0F172A);
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd hrms_app && flutter test test/app_theme_test.dart`
Expected: PASS.

- [ ] **Step 5: Replace the 4 inline usages**

In `hrms_app/lib/screens/claims/claims_screen.dart`, replace:

```dart
                  decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12)),
```

with:

```dart
                  decoration: BoxDecoration(color: AppColors.darkCard, borderRadius: BorderRadius.circular(12)),
```

In `hrms_app/lib/screens/payslip/payslip_detail_screen.dart`, replace both
occurrences:

```dart
                      color: const Color(0xFF0F172A),
```
(the one inside the NET PAY hero card's `BoxDecoration`) with:
```dart
                      color: AppColors.darkCard,
```

and:

```dart
                      backgroundColor: const Color(0xFF0F172A),
```
(the one inside the "Download PDF" `ElevatedButton.styleFrom`) with:
```dart
                      backgroundColor: AppColors.darkCard,
```

In `hrms_app/lib/screens/payslip/payslip_screen.dart`, replace:

```dart
            decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(14)),
```

with:

```dart
            decoration: BoxDecoration(color: AppColors.darkCard, borderRadius: BorderRadius.circular(14)),
```

- [ ] **Step 6: Run the full suite**

Run: `cd hrms_app && flutter test`
Expected: PASS, no regressions — this is a pure rename, same color value,
so every existing visual/text assertion is unaffected.

- [ ] **Step 7: Format and analyze**

Run: `cd hrms_app && dart format lib/theme/app_theme.dart lib/screens/claims/claims_screen.dart lib/screens/payslip/payslip_detail_screen.dart lib/screens/payslip/payslip_screen.dart test/app_theme_test.dart && flutter analyze lib`
Expected: files formatted, no analyzer issues project-wide.

- [ ] **Step 8: Commit**

```bash
git add hrms_app/lib/theme/app_theme.dart hrms_app/lib/screens/claims/claims_screen.dart hrms_app/lib/screens/payslip/payslip_detail_screen.dart hrms_app/lib/screens/payslip/payslip_screen.dart hrms_app/test/app_theme_test.dart
git commit -m "refactor: consolidate repeated dark-card color into AppColors.darkCard"
```

---

## Final verification (after all tasks)

- [ ] Run `cd hrms_app && flutter test` — full suite passes.
- [ ] Run `cd hrms_app && flutter analyze` — no issues.
- [ ] Manually compare `LoginScreen` against the mockup's `LOGIN OVERLAY`
  section (`HRMS Mobile App.dc.html` lines ~998-1027) via a `flutter build
  web` + browser preview, same verification approach used in every prior
  phase.
