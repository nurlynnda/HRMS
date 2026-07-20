import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hrms_app/screens/profile/personal_info_screen.dart';
import 'package:hrms_app/state/app_state.dart';

void main() {
  testWidgets('shows employee identity and grouped personal info sections', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const MaterialApp(home: PersonalInfoScreen()),
      ),
    );

    expect(find.text('Sarah Chen'), findsOneWidget);
    expect(find.text('Basic details'), findsOneWidget);
    expect(find.text('Contact'), findsOneWidget);
    expect(find.text('Emergency contact'), findsOneWidget);
    expect(find.text('Employment'), findsOneWidget);
    expect(find.text('Statutory'), findsOneWidget);
    expect(find.text('sarah.chen@company.com'), findsOneWidget);
  });

  testWidgets('tapping Edit shows a not-available message', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const MaterialApp(home: PersonalInfoScreen()),
      ),
    );

    await tester.tap(find.text('Edit'));
    await tester.pump();

    expect(
      find.text('Editing is not available in this preview'),
      findsOneWidget,
    );
  });
}
