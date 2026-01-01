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
  final Set<String> _recentlyCompleted = {};

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final allChallenges = gameState.activeChallenges;

    // Filter Logic
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

    // Kategorisierung
    final activeTasks = filtered.where((c) => !c.isCompleted || _recentlyCompleted.contains(c.id)).toList();
    final completedTasks = filtered.where((c) => c.isCompleted && !_recentlyCompleted.contains(c.id)).toList();

    // Sortierung
    activeTasks.sort((a, b) => a.isPriority != b.isPriority ? (a.isPriority ? -1 : 1) : 0);

    final priorities = activeTasks.where((c) => c.isPriority).toList();
    // Side Ops (Checkboxen/Wasser)
    final sideOps = activeTasks.where((c) => !c.isPriority && (c.type == ChallengeType.hydration || c.type == ChallengeType.boolean)).toList();
    // Standard Ops (Alles mit Slider/Timer, was nicht Prio ist)
    final standardOps = activeTasks.where((c) => !c.isPriority && c.type != ChallengeType.hydration && c.type != ChallengeType.boolean).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: FeedbackAnimation(
        child: ConfettiOverlay(
          controller: _confettiController,
          child: SafeArea(
            child: Column(
              children: [
                // HEADER MIT PROGRESS BAR
                _buildDailyHeader(allChallenges),
                const SizedBox(height: 10),
                
                // SEARCH BAR (NEU GESTYLT)
                _buildSearchBar(),
                const SizedBox(height: 16),
                
                _buildTabs(),
                const SizedBox(height: 10),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    children: [
                      // SEKTION 1: PRIORITY
                      if (priorities.isNotEmpty) ...[
                        _buildSectionHeader("PRIORITY TARGETS", Icons.star, AscendTheme.accent),
                        ...priorities.map((c) => _buildCard(c, true, gameState.stats.mercyTokenAvailable)),
                        const SizedBox(height: 20),
                        const Divider(color: Colors.white10),
                        const SizedBox(height: 20),
                      ],

                      // SEKTION 2: STANDARD OPERATIONS
                      if (standardOps.isNotEmpty) ...[
                        _buildSectionHeader("STANDARD OPERATIONS", Icons.list_alt, Colors.white70),
                        ...standardOps.map((c) => _buildCard(c, false, gameState.stats.mercyTokenAvailable)),
                        const SizedBox(height: 20),
                      ],

                      // SEKTION 3: SIDE OPS
                      if (sideOps.isNotEmpty) ...[
                        _buildSectionHeader("SIDE OPS", Icons.bolt, Colors.cyanAccent),
                        ...sideOps.map((c) => _buildCard(c, false, gameState.stats.mercyTokenAvailable)),
                      ],

                      // SEKTION 4: COMPLETED
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

  // --- WIDGETS ---

// ... imports ...

// In _DailyLogScreenState Klasse:

  Widget _buildDailyHeader(List<Challenge> challenges) {
     // 1. ECHTE GAMIFICATION BERECHNUNG
     // Wir zählen nicht nur "fertige", sondern summieren den %-Fortschritt jeder Aufgabe.
     double totalProgressSum = 0.0;
     int totalTasks = challenges.length;
     int completedCount = 0;

     for (var c in challenges) {
       if (c.isCompleted) completedCount++;
       // Addiere den prozentualen Fortschritt (max 1.0)
       totalProgressSum += (c.current / c.target).clamp(0.0, 1.0);
     }

     // Durchschnittlicher Fortschritt des Tages (0.0 bis 1.0)
     double overallProgress = totalTasks == 0 ? 0.0 : totalProgressSum / totalTasks;
     
     return Padding(
       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
       child: Container(
         padding: const EdgeInsets.all(16),
         decoration: BoxDecoration(
           color: const Color(0xFF151A25),
           borderRadius: BorderRadius.circular(16),
           border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
         ),
         child: Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
           children: [
             Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 const Text("DAILY STATUS", style: TextStyle(color: AscendTheme.textDim, fontSize: 10, letterSpacing: 2.0, fontWeight: FontWeight.bold)),
                 const SizedBox(height: 4),
                 // Zeigt weiterhin "Done Count", aber der Ring zeigt "Effort"
                 Text(
                   "$completedCount / $totalTasks OPS DONE", 
                   style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)
                 ),
               ],
             ),
             // PROGRESS CIRCLE
             Stack(
               alignment: Alignment.center,
               children: [
                 SizedBox(
                   width: 50, height: 50,
                   child: CircularProgressIndicator(
                     value: overallProgress, // <-- HIER IST DER FIX
                     color: AscendTheme.primary,
                     backgroundColor: Colors.white10,
                     strokeWidth: 5,
                     strokeCap: StrokeCap.round,
                   ),
                 ),
                 Text(
                   "${(overallProgress * 100).toInt()}%", 
                   style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
                 ),
               ],
             )
           ],
         ),
       ),
     );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        style: const TextStyle(color: Colors.white, fontSize: 14), // KLEINERE SCHRIFT
        cursorColor: AscendTheme.secondary,
        decoration: InputDecoration(
          hintText: "SEARCH OPERATIONS...",
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 12, letterSpacing: 1.0),
          prefixIcon: const Icon(Icons.search, color: AscendTheme.textDim, size: 20), // ICON
          filled: true,
          fillColor: const Color(0xFF0F1522),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), 
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), 
            borderSide: const BorderSide(color: AscendTheme.secondary, width: 1)
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          isDense: true,
        ),
        onChanged: (val) => setState(() => _searchQuery = val),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(color: color, fontSize: 10, letterSpacing: 2.0, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // Karten Builder
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

  // --- LOGIC ---
  void _handlePriorityToggle(String id, bool currentlyPriority) {
    final notifier = ref.read(gameProvider.notifier);
    if (currentlyPriority) {
      notifier.togglePriority(id);
      HapticFeedback.mediumImpact();
      return;
    }
    final currentPriorities = ref.read(gameProvider).activeChallenges.where((c) => c.isPriority).length;
    if (currentPriorities >= 3) {
      HapticFeedback.vibrate();
      _showPriorityLimitDialog(id);
    } else {
      notifier.togglePriority(id);
      HapticFeedback.heavyImpact();
    }
  }

  void _showPriorityLimitDialog(String newChallengeId) {
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
              ref.read(gameProvider.notifier).togglePriority(oldPrio.id);
              ref.read(gameProvider.notifier).togglePriority(newChallengeId);
              Navigator.pop(ctx);
            }, 
            child: const Text("SWAP TARGETS", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }

  void _logProgress(Challenge task, double amount) {
    ref.read(gameProvider.notifier).updateProgress(task.id, amount);
    double newCurrent = task.current + amount;
    bool isNowDone = newCurrent >= task.target;
    if (isNowDone && !task.isCompleted) {
      _confettiController.play();
      HapticFeedback.heavyImpact();
      setState(() => _recentlyCompleted.add(task.id));
      Future.delayed(const Duration(milliseconds: 2500), () {
        if(mounted) setState(() => _recentlyCompleted.remove(task.id));
      });
    }
  }

  Widget _buildTabs() => SizedBox(height: 36, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20), children: [_tabBtn(TabCategory.all, "ALL"), _tabBtn(TabCategory.body, "BODY", Colors.pinkAccent), _tabBtn(TabCategory.mind, "MIND", Colors.cyanAccent), _tabBtn(TabCategory.grind, "GRIND", const Color(0xFF69F0AE))]));
  
  Widget _tabBtn(TabCategory cat, String label, [Color c = Colors.white]) => GestureDetector(onTap: () => setState(() => _selectedTab = cat), child: Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 16), alignment: Alignment.center, decoration: BoxDecoration(color: _selectedTab == cat ? c.withOpacity(0.2) : Colors.white10, borderRadius: BorderRadius.circular(20), border: Border.all(color: _selectedTab == cat ? c : Colors.transparent)), child: Text(label, style: TextStyle(color: _selectedTab == cat ? c : Colors.white38, fontSize: 10, fontWeight: FontWeight.bold))));
}