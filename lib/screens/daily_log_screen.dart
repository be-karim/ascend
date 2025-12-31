import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ascend/theme.dart';
import 'package:ascend/models/challenge.dart';
import 'package:ascend/models/enums.dart';
import 'package:ascend/providers/game_state_provider.dart';
import 'package:ascend/widgets/confetti_overlay.dart';
import 'package:ascend/widgets/challenge_card.dart';
import 'package:ascend/widgets/feedback_animation.dart';

enum TabCategory { all, body, mind, grind }

class DailyLogScreen extends ConsumerStatefulWidget {
  const DailyLogScreen({super.key});

  @override
  ConsumerState<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends ConsumerState<DailyLogScreen> {
  final ConfettiController _confettiController = ConfettiController();
  TabCategory _selectedTab = TabCategory.all;
  String _searchQuery = "";
  
  // Set für Aufgaben, die "fertig" sind, aber noch kurz angezeigt werden (Grace Period)
  final Set<String> _recentlyCompleted = {};

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final allChallenges = gameState.activeChallenges;

    // 1. FILTERN (Suche + Tab)
    final filtered = allChallenges.where((c) {
      if (_searchQuery.isNotEmpty) {
        return c.name.toLowerCase().contains(_searchQuery.toLowerCase());
      }
      switch (_selectedTab) {
        case TabCategory.all: return true;
        case TabCategory.body: return c.attribute == ChallengeAttribute.strength || c.attribute == ChallengeAttribute.agility;
        case TabCategory.mind: return c.attribute == ChallengeAttribute.intelligence;
        case TabCategory.grind: return c.attribute == ChallengeAttribute.discipline;
      }
    }).toList();

    // 2. KATEGORISIERUNG
    // Wir zeigen "Completed" tasks NICHT in den Hauptlisten an (außer Grace Period)
    final activeTasks = filtered.where((c) => !c.isCompleted || _recentlyCompleted.contains(c.id)).toList();
    final completedTasks = filtered.where((c) => c.isCompleted && !_recentlyCompleted.contains(c.id)).toList();

    // Sortierung
    activeTasks.sort((a, b) => a.isPriority != b.isPriority ? (a.isPriority ? -1 : 1) : 0);

    // Splitten
    final priorities = activeTasks.where((c) => c.isPriority).toList();
    
    // Side Ops: Hydration & Boolean (Checkbox) Tasks
    final sideOps = activeTasks.where((c) => !c.isPriority && (c.type == ChallengeType.hydration || c.type == ChallengeType.boolean)).toList();
    
    // Standard Ops: Der Rest (Reps/Time, die keine Prio sind)
    final standardOps = activeTasks.where((c) => !c.isPriority && c.type != ChallengeType.hydration && c.type != ChallengeType.boolean).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: FeedbackAnimation(
        child: ConfettiOverlay(
          controller: _confettiController,
          child: SafeArea(
            child: Column(
              children: [
                _buildDailyHeader(allChallenges),
                const SizedBox(height: 10),
                _buildSearchBar(),
                const SizedBox(height: 16),
                _buildTabs(),
                const SizedBox(height: 10),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    children: [
                      // SEKTION 1: PRIORITY TARGETS
                      if (priorities.isNotEmpty) ...[
                        _buildSectionHeader("PRIORITY TARGETS", Icons.star, AscendTheme.accent),
                        ...priorities.map((c) => _buildCard(c, true, gameState.stats.mercyTokenAvailable)),
                        const SizedBox(height: 20),
                        const Divider(color: Colors.white10),
                        const SizedBox(height: 20),
                      ],

                      // SEKTION 2: STANDARD OPERATIONS (Backlog)
                      if (standardOps.isNotEmpty) ...[
                        _buildSectionHeader("STANDARD OPERATIONS", Icons.list_alt, Colors.white70),
                        ...standardOps.map((c) => _buildCard(c, false, gameState.stats.mercyTokenAvailable)),
                        const SizedBox(height: 20),
                      ],

                      // SEKTION 3: SIDE OPS (Quick Tasks)
                      if (sideOps.isNotEmpty) ...[
                        _buildSectionHeader("SIDE OPS", Icons.bolt, Colors.cyanAccent),
                        // Side Ops als Grid oder kompakte Liste
                        ...sideOps.map((c) => _buildCard(c, false, gameState.stats.mercyTokenAvailable)),
                      ],

                      // SEKTION 4: MISSION DEBRIEF (Completed)
                      if (completedTasks.isNotEmpty) ...[
                        const SizedBox(height: 30),
                        Center(child: Text("MISSION DEBRIEF", style: TextStyle(color: Colors.white.withValues(alpha: 0.3), letterSpacing: 2.0, fontSize: 10, fontWeight: FontWeight.bold))),
                        const SizedBox(height: 10),
                        ...completedTasks.map((c) => Opacity(opacity: 0.5, child: _buildCard(c, false, false))),
                      ],

                      const SizedBox(height: 80), 
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(color: color, fontSize: 10, letterSpacing: 2.0, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCard(Challenge task, bool isPriority, bool mercyAvailable) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ActiveChallengeCard(
        task: task,
        isPriority: isPriority,
        mercyTokenAvailable: mercyAvailable,
        onUpdate: (amount) => _logProgress(task, amount),
        onTimerToggle: () {
          HapticFeedback.mediumImpact();
          ref.read(gameProvider.notifier).toggleTimer(task.id, !task.isRunning);
        },
        onCalibrate: (val, useXp) {
          ref.read(gameProvider.notifier).updateChallengeTarget(task.id, val, useXp: useXp);
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text(useXp ? "CALIBRATION COMPLETE (-XP)" : "CALIBRATION COMPLETE (MERCY)"), duration: const Duration(milliseconds: 800))
          );
        },
        onTogglePriority: (id) => _handlePriorityToggle(id, isPriority),
      ),
    );
  }

  // LOGIC: MAX 3 PRIORITY
  void _handlePriorityToggle(String id, bool currentlyPriority) {
    final notifier = ref.read(gameProvider.notifier);
    
    // Wenn wir es entfernen wollen: Immer okay
    if (currentlyPriority) {
      notifier.togglePriority(id);
      HapticFeedback.mediumImpact();
      return;
    }

    // Wenn wir es hinzufügen wollen: Check Limit
    final currentPriorities = ref.read(gameProvider).activeChallenges.where((c) => c.isPriority).length;
    
    if (currentPriorities >= 3) {
      // LIMIT REACHED
      HapticFeedback.vibrate();
      _showPriorityLimitDialog(id);
    } else {
      // OKAY
      notifier.togglePriority(id);
      HapticFeedback.heavyImpact();
    }
  }

  void _showPriorityLimitDialog(String newChallengeId) {
    // Finde die älteste Priority Task (vereinfacht: die erste in der Liste)
    final oldPrio = ref.read(gameProvider).activeChallenges.firstWhere((c) => c.isPriority);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151A25),
        title: const Text("FOCUS SATURATION", style: TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold)),
        content: Text("Maximum of 3 Priority Targets allowed.\n\nSwap '${oldPrio.name}' with new target?", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AscendTheme.accent),
            onPressed: () {
              ref.read(gameProvider.notifier).togglePriority(oldPrio.id); // Alte raus
              ref.read(gameProvider.notifier).togglePriority(newChallengeId); // Neue rein
              Navigator.pop(ctx);
            }, 
            child: const Text("SWAP TARGETS", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }

  void _logProgress(Challenge task, double amount) {
    // 1. Progress im State updaten
    ref.read(gameProvider.notifier).updateProgress(task.id, amount);
    
    // 2. Check Completion für UI Delay
    // Da wir den State noch nicht neu geholt haben, rechnen wir manuell
    double newCurrent = task.current + amount;
    bool isNowDone = newCurrent >= task.target;

    if (isNowDone && !task.isCompleted) { // Nur wenn es GERADE fertig wurde
      _confettiController.play();
      HapticFeedback.heavyImpact();
      
      // Zur "Recently Completed" Liste hinzufügen, damit es noch kurz sichtbar bleibt
      setState(() => _recentlyCompleted.add(task.id));
      
      // Nach 2.5 Sekunden aus der "Recently" Liste entfernen -> UI verschiebt es nach unten
      Future.delayed(const Duration(milliseconds: 2500), () {
        if(mounted) setState(() => _recentlyCompleted.remove(task.id));
      });
    }
  }

  Widget _buildDailyHeader(List<Challenge> challenges) {
     final completed = challenges.where((c) => c.isCompleted).length;
     double progress = challenges.isEmpty ? 0 : completed / challenges.length;
     return Padding(
       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
       child: Row(
         mainAxisAlignment: MainAxisAlignment.spaceBetween,
         children: [
           Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
             const Text("DAILY STATUS", style: TextStyle(color: AscendTheme.textDim, fontSize: 10, letterSpacing: 2.0, fontWeight: FontWeight.bold)),
             Text("$completed / ${challenges.length} OPS DONE", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
           ]),
           CircularProgressIndicator(value: progress, color: AscendTheme.primary, backgroundColor: Colors.white10),
         ],
       ),
     );
  }

  // ... (Restliche Methoden wie _buildSearchBar, _buildTabs bleiben gleich) ...
  Widget _buildSearchBar() => Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: TextField(style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: "SEARCH OPERATIONS...", filled: true, fillColor: const Color(0xFF0F1522), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)), onChanged: (val) => setState(() => _searchQuery = val)));
  
  Widget _buildTabs() => SizedBox(height: 36, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20), children: [_tabBtn(TabCategory.all, "ALL"), _tabBtn(TabCategory.body, "BODY", Colors.pinkAccent), _tabBtn(TabCategory.mind, "MIND", Colors.cyanAccent), _tabBtn(TabCategory.grind, "GRIND", const Color(0xFF69F0AE))]));
  
  Widget _tabBtn(TabCategory cat, String label, [Color c = Colors.white]) => GestureDetector(onTap: () => setState(() => _selectedTab = cat), child: Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 16), alignment: Alignment.center, decoration: BoxDecoration(color: _selectedTab == cat ? c.withOpacity(0.2) : Colors.white10, borderRadius: BorderRadius.circular(20), border: Border.all(color: _selectedTab == cat ? c : Colors.transparent)), child: Text(label, style: TextStyle(color: _selectedTab == cat ? c : Colors.white38, fontSize: 10, fontWeight: FontWeight.bold))));
}