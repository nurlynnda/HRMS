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
