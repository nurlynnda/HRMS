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

  testWidgets('shows the welcome header, form fields, and buttons', (
    tester,
  ) async {
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

  testWidgets('Sign in button is disabled until both fields are filled', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(AppState()));

    ElevatedButton signInButton() => tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Sign in'),
    );

    expect(signInButton().onPressed, isNull);

    await tester.enterText(
      find.byKey(const Key('loginEmailField')),
      'sarah.chen@company.com',
    );
    await tester.pump();
    expect(signInButton().onPressed, isNull);

    await tester.enterText(
      find.byKey(const Key('loginPasswordField')),
      'password',
    );
    await tester.pump();
    expect(signInButton().onPressed, isNotNull);
  });

  testWidgets('tapping Sign in logs the user in', (tester) async {
    final appState = AppState();
    await tester.pumpWidget(wrap(appState));

    await tester.enterText(
      find.byKey(const Key('loginEmailField')),
      'sarah.chen@company.com',
    );
    await tester.enterText(
      find.byKey(const Key('loginPasswordField')),
      'password',
    );
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

  testWidgets('tapping Forgot password shows a not-available message', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(AppState()));

    await tester.tap(find.text('Forgot password?'));
    await tester.pump();

    expect(
      find.text("Password reset isn't available in this preview"),
      findsOneWidget,
    );
  });

  testWidgets(
    'tapping Sign in with Face ID completes the flow and logs the user in',
    (tester) async {
      final appState = AppState();
      await tester.pumpWidget(wrap(appState));

      expect(appState.isLoggedIn, isFalse);
      await tester.tap(find.text('Sign in with Face ID'));
      await tester.pumpAndSettle();

      expect(find.text('Face ID Sign In'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 900));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(appState.isLoggedIn, isTrue);
    },
  );
}
