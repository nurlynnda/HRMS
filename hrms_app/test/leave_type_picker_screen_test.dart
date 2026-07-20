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
