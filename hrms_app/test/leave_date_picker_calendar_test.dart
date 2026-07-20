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
          body: SingleChildScrollView(
            child: StatefulBuilder(
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
          body: SingleChildScrollView(
            child: StatefulBuilder(
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
          body: SingleChildScrollView(
            child: StatefulBuilder(
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
          body: SingleChildScrollView(
            child: LeaveDatePickerCalendar(
              start: null,
              end: null,
              initialDate: DateTime(2030, 1, 1),
              onStartChanged: (_) {},
              onEndChanged: (_) {},
            ),
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
