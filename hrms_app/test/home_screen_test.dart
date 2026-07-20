import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hrms_app/screens/home/home_screen.dart';
import 'package:hrms_app/state/app_state.dart';

void main() {
  testWidgets('HomeScreen shows dashboard content from AppState', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const MaterialApp(home: Scaffold(body: HomeScreen())),
      ),
    );

    expect(find.text('Sarah Chen'), findsOneWidget);
    expect(find.text('Clocked in'), findsOneWidget);
    expect(find.text('Leave balance'), findsOneWidget);
    expect(find.text('Announcements'), findsOneWidget);
    expect(find.text('This week'), findsOneWidget);
  });
}
