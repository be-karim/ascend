import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ascend/screens/home_screen.dart';
import 'package:ascend/screens/daily_log_screen.dart';
import 'package:ascend/screens/mission_control_screen.dart';
import 'package:ascend/screens/stats_screen.dart';
import 'package:ascend/theme.dart';

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const DailyLogScreen(),
    const MissionControlScreen(),
    const StatsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Global Grid Background for cohesiveness
          Positioned.fill(
            child: Opacity(
              opacity: 0.03,
              child: CustomPaint(painter: GridPainter()),
            ),
          ),
          SafeArea(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
          color: AscendTheme.background.withValues(alpha: 0.95),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.transparent,
          selectedItemColor: AscendTheme.secondary,
          unselectedItemColor: AscendTheme.textDim,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.0),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 10),
          elevation: 0,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'HUD',
            ),
            // THE HIGHLIGHTED EXECUTE TAB
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AscendTheme.textDim.withValues(alpha: 0.5), width: 1),
                ),
                child: const Icon(Icons.my_location), // "Target" icon
              ),
              activeIcon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AscendTheme.secondary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: AscendTheme.secondary, width: 2),
                  boxShadow: [
                    BoxShadow(color: AscendTheme.secondary.withValues(alpha: 0.5), blurRadius: 8)
                  ]
                ),
                child: const Icon(Icons.my_location, color: AscendTheme.secondary),
              ),
              label: 'EXECUTE',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: 'PLAN',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'PROFILE',
            ),
          ],
        ),
      ),
    );
  }
}

// Reusing the GridPainter from Onboarding for consistent design language
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AscendTheme.secondary.withValues(alpha: 0.1)
      ..strokeWidth = 1;

    const double gridSize = 40;

    for (double i = 0; i < size.width; i += gridSize) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += gridSize) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}