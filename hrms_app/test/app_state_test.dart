import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_app/state/app_state.dart';

void main() {
  test('clockOut() sets clockedIn to false and records a clock-out time', () {
    final appState = AppState();
    expect(appState.todayAttendance.clockedIn, isTrue);

    appState.clockOut();

    expect(appState.todayAttendance.clockedIn, isFalse);
    expect(appState.todayAttendance.clockOutTime, isNotNull);
    expect(appState.clockStatus.clockedIn, isFalse);
  });

  test('clockIn() sets clockedIn to true and clears the clock-out time', () {
    final appState = AppState();
    appState.clockOut();

    appState.clockIn();

    expect(appState.todayAttendance.clockedIn, isTrue);
    expect(appState.todayAttendance.clockOutTime, isNull);
    expect(appState.clockStatus.clockedIn, isTrue);
  });

  test('notifyListeners fires when clocking in or out', () {
    final appState = AppState();
    var notified = false;
    appState.addListener(() => notified = true);

    appState.clockOut();

    expect(notified, isTrue);
  });
}
