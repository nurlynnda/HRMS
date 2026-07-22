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

    // Step through the simulated flow's timers to complete the widget
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
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

    // Step through the simulated flow's timers to complete the widget
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
  });
}
