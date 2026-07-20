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
    // The default 800x600 test surface is too short for this screen's
    // ListView (month calendar + date summary + reason field + approval
    // flow + submit button): a ListView only builds the children that fit
    // within its viewport, so anything below the fold (like the submit
    // button) would never be built into the widget tree and finders for it
    // would fail. Growing the surface lets everything build without
    // scrolling, matching the same short-viewport issue hit by the Task 4
    // calendar widget test (fixed there with SingleChildScrollView).
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
