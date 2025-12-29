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
import 'package:ascend/screens/mission_control_screen.dart';

class DailyLogScreen extends ConsumerStatefulWidget {
  const DailyLogScreen({super.key});

  @override
  ConsumerState<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends ConsumerState<DailyLogScreen> {
  final ConfettiController _confettiController = ConfettiController();
  Timer? _timer;

  @override
  void dispose() {
    _confettiController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _openMissionControl() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const MissionControlScreen()));
  }

  void _updateProgress(Challenge challenge, double amount) {
    bool wasComplete = challenge.isCompleted;
    
    // Call Riverpod Notifier
    ref.read(gameProvider.notifier).updateProgress(challenge.id, amount);
    
    HapticFeedback.lightImpact();
    
    // Check if it became completed *after* the update
    // Ideally we assume the provider update is sync for local state, 
    // but better to check the fresh state or calculate locally
    final newProgress = (challenge.current + amount);
    if (!wasComplete && newProgress >= challenge.target) {
      _confettiController.play();
      HapticFeedback.heavyImpact();
    }
  }

  void _toggleTimer(Challenge challenge) {
    HapticFeedback.selectionClick();
    
    // Note: In a real app, timer state should probably be in the Provider too
    // But for 60fps UI updates, local state handling the Ticker is often smoother
    if (challenge.isRunning) {
      // Stop
      ref.read(gameProvider.notifier).toggleTimer(challenge.id, false);
      _timer?.cancel();
    } else {
      // Start
      ref.read(gameProvider.notifier).toggleTimer(challenge.id, true);
      _timer?.cancel();
      
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        // Read fresh state to check if still running/completed
        final freshChallenge = ref.read(gameProvider).activeChallenges.firstWhere((c) => c.id == challenge.id, orElse: () => challenge);
        
        if (!freshChallenge.isRunning) {
          t.cancel();
          return;
        }
        
        // Add 1/60th of a unit (assuming unit is minutes) - or 1 second if unit is seconds
        // Adjust based on your logic. Usually 1 min = 1.0 unit. So 1 sec = 1/60.
        ref.read(gameProvider.notifier).updateProgress(freshChallenge.id, 1/60);
        
        if (freshChallenge.current >= freshChallenge.target) {
          ref.read(gameProvider.notifier).toggleTimer(freshChallenge.id, false);
          t.cancel();
          _confettiController.play();
          HapticFeedback.heavyImpact();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final challenges = gameState.activeChallenges;

    // Split lists
    final pending = challenges.where((c) => !c.isCompleted).toList();
    final completed = challenges.where((c) => c.isCompleted).toList();
    
    // Sort pending: Running first
    pending.sort((a, b) => (a.isRunning == b.isRunning) ? 0 : (a.isRunning ? -1 : 1));

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openMissionControl,
        backgroundColor: AscendTheme.primary,
        icon: const Icon(Icons.add_task, color: Colors.white),
        label: const Text("PLAN MISSION", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: ConfettiOverlay(
        controller: _confettiController,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "DAILY LOG",
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2.0),
                      ),
                      Text(
                        "${DateTime.now().month}/${DateTime.now().day}",
                        style: const TextStyle(color: AscendTheme.textDim, fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                  const SizedBox(height: 30),
                  
                  // SECTION 1: PENDING
                  if (pending.isNotEmpty) ...[
                    const Text("CURRENT OBJECTIVES", style: TextStyle(color: AscendTheme.textDim, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ...pending.map((c) => ChallengeCard(
                      task: c, 
                      onUpdate: _updateProgress, 
                      onDelete: (id) => ref.read(gameProvider.notifier).removeChallenge(id), 
                      onToggleTimer: _toggleTimer,
                      onEditTarget: (c, val) { 
                         ref.read(gameProvider.notifier).updateChallengeTarget(c.id, val);
                      }
                    )),
                  ],

                  if (pending.isEmpty && completed.isEmpty)
                    _buildEmptyState(),

                  // VISUAL SEPARATOR: MOMENTUM
                  if (completed.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildMomentumDivider(completed.length),
                    const SizedBox(height: 20),
                    
                    // SECTION 2: COMPLETED
                    const Text("MISSION LOG", style: TextStyle(color: AscendTheme.textDim, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ...completed.map((c) => Opacity(
                      opacity: 0.6, 
                      child: ChallengeCard(
                        task: c, 
                        onUpdate: _updateProgress, 
                        onDelete: (id) => ref.read(gameProvider.notifier).removeChallenge(id), 
                        onToggleTimer: _toggleTimer,
                        onEditTarget: (c, val) {
                           ref.read(gameProvider.notifier).updateChallengeTarget(c.id, val);
                        }
                      ),
                    )),
                  ],
                    
                  const SizedBox(height: 80), // Space for FAB
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.nightlight_round, size: 48, color: AscendTheme.textDim.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text("NO ACTIVE PROTOCOLS", style: TextStyle(color: AscendTheme.textDim, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Initialize a new mission below.", style: TextStyle(color: AscendTheme.textDim, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildMomentumDivider(int completedCount) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AscendTheme.accent.withValues(alpha: 0.05), Colors.transparent, AscendTheme.accent.withValues(alpha: 0.05)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.symmetric(horizontal: BorderSide(color: AscendTheme.accent.withValues(alpha: 0.2))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bolt, color: AscendTheme.accent, size: 16),
          const SizedBox(width: 8),
          Text(
            "$completedCount TASKS COMPLETED - MOMENTUM ACTIVE",
            style: const TextStyle(color: AscendTheme.accent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2.0),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.bolt, color: AscendTheme.accent, size: 16),
        ],
      ),
    );
  }
}