import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ascend/theme.dart';
import 'package:ascend/screens/hud_screen.dart';
import 'package:ascend/screens/daily_log_screen.dart';
import 'package:ascend/screens/mission_control_screen.dart';
import 'package:ascend/screens/profile_screen.dart'; // NEU
import 'package:ascend/providers/nav_provider.dart';

class MainScaffold extends ConsumerWidget {
  const MainScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navIndexProvider);

    final List<Widget> screens = [
      const HUDScreen(),
      const DailyLogScreen(),
      const MissionControlScreen(),
      const ProfileScreen(), // UPDATE HIER
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white10, width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (index) {
            ref.read(navIndexProvider.notifier).setIndex(index);
          },
          backgroundColor: const Color(0xFF050505),
          indicatorColor: AscendTheme.primary.withValues(alpha: 0.2),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard, color: AscendTheme.primary),
              label: 'HUD',
            ),
            NavigationDestination(
              icon: Icon(Icons.list_alt_outlined),
              selectedIcon: Icon(Icons.list_alt, color: AscendTheme.primary),
              label: 'OPS',
            ),
            NavigationDestination(
              icon: Icon(Icons.hub_outlined),
              selectedIcon: Icon(Icons.hub, color: AscendTheme.primary),
              label: 'Library',
            ),
            // UPDATE LABEL
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: AscendTheme.primary),
              label: 'BARRACKS', 
            ),
          ],
        ),
      ),
    );
  }
}