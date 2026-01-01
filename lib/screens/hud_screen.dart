import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ascend/theme.dart';
import 'package:ascend/providers/game_state_provider.dart';
import 'package:ascend/providers/nav_provider.dart';
import 'package:ascend/models/enums.dart';
import 'package:ascend/models/template.dart';
import 'package:ascend/models/history.dart';
import 'package:ascend/models/challenge.dart'; // Wichtig für den Typ
import 'package:intl/intl.dart'; 

class HUDScreen extends ConsumerWidget {
  const HUDScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final stats = gameState.stats;
    final challenges = gameState.activeChallenges;
    final history = gameState.history;
    final library = gameState.library;

    // Daily Progress
    int completedCount = challenges.where((c) => c.isCompleted).length;
    int totalCount = challenges.length;
    double progress = totalCount == 0 ? 0.0 : completedCount / totalCount;

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HEADER ("ASCEND")
              _buildTopBar(),
              const SizedBox(height: 24),

              // 2. PROFILE & STREAK
              Row(
                children: [
                  Expanded(flex: 2, child: _buildProfileCard(stats)),
                  const SizedBox(width: 12),
                  Expanded(flex: 1, child: _buildStreakWidget(stats.streak)),
                ],
              ),
              const SizedBox(height: 16),

              // 3. DAILY STATUS
              _buildDailyBriefing(progress, completedCount, totalCount),
              const SizedBox(height: 24),

              // 4. ACTIVITY HEATMAP
              const Text("ACTIVITY RADAR (7 DAYS)", style: TextStyle(color: AscendTheme.textDim, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
              const SizedBox(height: 12),
              _buildActivityHeatmap(history, library),
              const SizedBox(height: 24),

              // 5. NEXT MISSION (Fixed)
              if (completedCount < totalCount) ...[
                const Text("NEXT OBJECTIVE", style: TextStyle(color: AscendTheme.textDim, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
                const SizedBox(height: 12),
                _buildNextMissionWidget(challenges, ref),
                const SizedBox(height: 24),
              ],

              // 6. COMMAND GRID
              const Text("COMMAND MODULES", style: TextStyle(color: AscendTheme.textDim, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
              const SizedBox(height: 12),
              _buildNavGrid(ref),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("ASCEND", style: TextStyle(color: Colors.white, fontSize: 24, fontFamily: 'Courier', fontWeight: FontWeight.w900, letterSpacing: 2.0)),
            Row(
              children: [
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: AscendTheme.accent, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                const Text("SYSTEM ONLINE", style: TextStyle(color: AscendTheme.accent, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        Icon(Icons.radar, color: Colors.white.withValues(alpha: 0.2)),
      ],
    );
  }

  Widget _buildProfileCard(dynamic stats) {
    int level = stats.globalLevel;
    String rank = _getRankName(level);
    double xpProgress = (stats.currentXp / stats.maxXp).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151A25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AscendTheme.primary),
                  color: AscendTheme.primary.withValues(alpha: 0.1),
                ),
                child: Center(child: Text("$level", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rank, style: const TextStyle(color: AscendTheme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                  const Text("COMMANDER", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(value: xpProgress, backgroundColor: Colors.white10, color: AscendTheme.primary, minHeight: 4),
          ),
          const SizedBox(height: 4),
          Text("${stats.currentXp.toInt()} / ${stats.maxXp.toInt()} XP", style: const TextStyle(color: Colors.white38, fontSize: 9)),
        ],
      ),
    );
  }

  Widget _buildStreakWidget(int streak) {
    return Container(
      height: 110,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [const Color(0xFF202530), AscendTheme.primary.withValues(alpha: 0.1)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AscendTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.local_fire_department, color: AscendTheme.primary, size: 24),
          const SizedBox(height: 4),
          Text("$streak", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
          const Text("DAY STREAK", style: TextStyle(color: AscendTheme.primary, fontSize: 8, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActivityHeatmap(List<HistoryEntry> history, List<ChallengeTemplate> library) {
    final now = DateTime.now();
    List<DateTime> last7Days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    
    Map<ChallengeAttribute, List<int>> heatData = {
      ChallengeAttribute.strength: List.filled(7, 0),
      ChallengeAttribute.intelligence: List.filled(7, 0),
      ChallengeAttribute.discipline: List.filled(7, 0),
    };

    for (int i = 0; i < 7; i++) {
      final date = last7Days[i];
      final entry = history.firstWhere(
        (h) => h.date.year == date.year && h.date.month == date.month && h.date.day == date.day,
        orElse: () => HistoryEntry(date: date, completedCount: 0, completedChallengeNames: []),
      );

      for (String name in entry.completedChallengeNames) {
        try {
          final template = library.firstWhere((t) => t.title == name);
          if (template.attribute == ChallengeAttribute.strength || template.attribute == ChallengeAttribute.agility) {
            heatData[ChallengeAttribute.strength]![i]++;
          } else if (template.attribute == ChallengeAttribute.intelligence) {
            heatData[ChallengeAttribute.intelligence]![i]++;
          } else {
            heatData[ChallengeAttribute.discipline]![i]++;
          }
        } catch (e) {
          // Ignore
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF151A25), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
      child: Column(
        children: [
          _buildHeatRow("BODY", heatData[ChallengeAttribute.strength]!, Colors.pinkAccent),
          const SizedBox(height: 8),
          _buildHeatRow("MIND", heatData[ChallengeAttribute.intelligence]!, Colors.cyanAccent),
          const SizedBox(height: 8),
          _buildHeatRow("GRIND", heatData[ChallengeAttribute.discipline]!, const Color(0xFF69F0AE)),
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 50),
              ...last7Days.map((d) => Expanded(child: Center(child: Text(DateFormat('E').format(d)[0], style: const TextStyle(color: Colors.white38, fontSize: 10))))),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildHeatRow(String label, List<int> data, Color color) {
    return Row(
      children: [
        SizedBox(width: 50, child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold))),
        ...data.map((count) {
          double opacity = count == 0 ? 0.1 : (count >= 3 ? 1.0 : 0.3 + (count * 0.2));
          return Expanded(
            child: Container(
              height: 20,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: opacity),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }),
      ],
    );
  }

  // --- HIER WAR DER FEHLER ---
  Widget _buildNextMissionWidget(List<Challenge> challenges, WidgetRef ref) {
    // FIX: Nutze .where().firstOrNull statt firstWhere(orElse: null)
    final next = challenges.where((c) => !c.isCompleted).firstOrNull;
    
    if (next == null) return const SizedBox(); 

    return GestureDetector(
      onTap: () => ref.read(navIndexProvider.notifier).setIndex(1), // Jump to Ops
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF202530),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AscendTheme.accent.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AscendTheme.accent.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.play_arrow, color: AscendTheme.accent, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("RESUME OPERATION", style: TextStyle(color: AscendTheme.accent, fontSize: 10, fontWeight: FontWeight.bold)),
                  Text(next.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyBriefing(double progress, int completed, int total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF151A25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("DAILY OPS STATUS", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              Text("${(progress * 100).toInt()}%", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: progress, backgroundColor: Colors.white10, color: AscendTheme.accent, minHeight: 8, borderRadius: BorderRadius.circular(4)),
          const SizedBox(height: 12),
          Text(
            total == 0 ? "NO ORDERS" : "$completed / $total OBJECTIVES CLEARED",
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildNavGrid(WidgetRef ref) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _TacticalButton(title: "FIELD OPS", subtitle: "EXECUTE", icon: Icons.list_alt, color: AscendTheme.primary, onTap: () => ref.read(navIndexProvider.notifier).setIndex(1)),
        _TacticalButton(title: "MISSION CONTROL", subtitle: "DATABASE", icon: Icons.hub, color: Colors.cyanAccent, onTap: () => ref.read(navIndexProvider.notifier).setIndex(2)),
        _TacticalButton(title: "BARRACKS", subtitle: "HISTORY", icon: Icons.bar_chart, color: Colors.orangeAccent, onTap: () => ref.read(navIndexProvider.notifier).setIndex(3)),
        _TacticalButton(title: "SYSTEM", subtitle: "CONFIG", icon: Icons.settings, color: Colors.grey, onTap: () {}),
      ],
    );
  }

  String _getRankName(int level) {
    if (level < 5) return "ROOKIE";
    if (level < 10) return "OPERATOR";
    if (level < 20) return "VETERAN";
    if (level < 50) return "ELITE";
    return "LEGEND";
  }
}

class _TacticalButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TacticalButton({required this.title, required this.subtitle, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1A1F2B),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 26),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}