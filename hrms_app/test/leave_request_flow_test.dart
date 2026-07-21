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

    // The reason field and submit button sit below the calendar; the form's
    // ListView only builds the widgets currently within (or dragged into)
    // the viewport, so scroll them into view before interacting.
    await tester.dragUntilVisible(
      find.byType(TextField),
      find.byType(ListView),
      const Offset(0, -200),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Moving apartment');
    await tester.pump();

    await tester.dragUntilVisible(
      find.widgetWithText(ElevatedButton, 'Submit request'),
      find.byType(ListView),
      const Offset(0, -200),
    );
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
