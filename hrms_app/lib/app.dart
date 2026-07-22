import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'screens/login/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/attendance/attendance_screen.dart';
import 'screens/leave/leave_screen.dart';
import 'screens/profile/profile_screen.dart';

class HrmsApp extends StatelessWidget {
  const HrmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'HRMS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.themeData,
        home: Consumer<AppState>(
          builder: (context, appState, child) =>
              appState.isLoggedIn ? const MainTabShell() : const LoginScreen(),
        ),
      ),
    );
  }
}

class MainTabShell extends StatefulWidget {
  const MainTabShell({super.key});

  @override
  State<MainTabShell> createState() => _MainTabShellState();
}

class _MainTabShellState extends State<MainTabShell> {
  int _selectedIndex = 0;

  void _onTabTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(onNavigateToTab: _onTabTapped),
      const AttendanceScreen(),
      const LeaveScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _selectedIndex, children: screens),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time_outlined),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note_outlined),
            label: 'Leave',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Me',
          ),
        ],
      ),
    );
  }
}
