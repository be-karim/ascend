import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ascend/models/enums.dart';
import 'package:ascend/models/challenge.dart'; // For the active list
import 'package:ascend/providers/game_state_provider.dart';
import 'package:ascend/theme.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final player = gameState.stats;
    final activeChallenges = gameState.activeChallenges;

    // Calculate XP Progress
    double progress = player.currentXp / player.maxXp;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(player.globalLevel, progress),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroSection(player.globalLevel, player.streak, player.currentXp),
                    const SizedBox(height: 24),
                    const Text(
                       "PRIORITY TARGET",
                       style: TextStyle(
                         color: AscendTheme.textDim, 
                         fontSize: 12, 
                         letterSpacing: 2.0, 
                         fontWeight: FontWeight.bold
                       ),
                    ),
                    const SizedBox(height: 12),
                    _buildPriorityTask(activeChallenges),
                    const SizedBox(height: 30),
                    const Text(
                       "DAILY PROGRESS TRACKER",
                       style: TextStyle(
                         color: AscendTheme.textDim, 
                         fontSize: 12, 
                         letterSpacing: 2.0, 
                         fontWeight: FontWeight.bold
                       ),
                    ),
                    const SizedBox(height: 12),
                    _buildDailyTracker(activeChallenges),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int level, double progress) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AscendTheme.background.withValues(alpha: 0.8),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AscendTheme.primary, AscendTheme.secondary],
                ).createShader(bounds),
                child: const Text(
                  "ASCEND",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    color: Colors.white,
                  ),
                ),
              ),
              const Text(
                "SYSTEM ONLINE",
                style: TextStyle(color: AscendTheme.textDim, fontSize: 10, letterSpacing: 2.0),
              )
            ],
          ),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(text: "LVL ", style: TextStyle(color: AscendTheme.secondary, fontSize: 10, letterSpacing: 1.0, fontWeight: FontWeight.bold)),
                        TextSpan(text: "$level", style: const TextStyle(color: AscendTheme.secondary, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 100,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AscendTheme.primary, AscendTheme.secondary]),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(width: 12),
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AscendTheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildHeroSection(int level, int streak, int xp) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AscendTheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 10),
          )
        ]
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: AscendTheme.accent.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                "ACTIVE", 
                style: TextStyle(color: AscendTheme.accent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
              ),
            ),
          ),
          Column(
            children: [
              Container(
                width: 128, height: 128,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AscendTheme.secondary.withValues(alpha: 0.3), width: 2),
                  gradient: RadialGradient(
                    colors: [AscendTheme.secondary.withValues(alpha: 0.2), Colors.transparent],
                    stops: const [0.3, 1.0]
                  ),
                  boxShadow: [
                     BoxShadow(color: AscendTheme.secondary.withValues(alpha: 0.2), blurRadius: 20)
                  ]
                ),
                alignment: Alignment.center,
                child: Text(
                  "$level",
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: [
                      Shadow(color: AscendTheme.secondary.withValues(alpha: 0.8), blurRadius: 10)
                    ]
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text("Daily Objective", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              const SizedBox(height: 4),
              const Text("Consistency is key, Operator.", style: TextStyle(color: AscendTheme.textDim, fontSize: 14)),
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(child: _buildInfoCard("STREAK", "$streak", AscendTheme.accent)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildInfoCard("XP TODAY", "$xp", AscendTheme.primary)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildInfoCard("FOCUS", "STR", AscendTheme.secondary)),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: AscendTheme.textDim, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPriorityTask(List<Challenge> challenges) {
    final task = challenges.where((c) => !c.isCompleted).firstOrNull;

    if (task == null) {
      return Container(
         padding: const EdgeInsets.all(20),
         decoration: BoxDecoration(
           color: AscendTheme.surface,
           borderRadius: BorderRadius.circular(16),
           border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
         ),
         child: const Center(child: Text("NO PRIORITY TARGETS", style: TextStyle(color: AscendTheme.textDim))),
      );
    }
    
    Color activeColor = AscendTheme.primary;
    if (task.type == ChallengeType.hydration) activeColor = AscendTheme.secondary;
    if (task.type == ChallengeType.time) activeColor = AscendTheme.accent;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AscendTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: activeColor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(task.name, style: TextStyle(color: activeColor, fontSize: 16, fontWeight: FontWeight.bold)),
              Text("${(task.progress * 100).toInt()}%", style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w900, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            task.type == ChallengeType.time 
              ? "${task.current.toInt()} / ${task.target.toInt()} MIN" 
              : "${task.current.toInt()} / ${task.target.toInt()} ${task.unit.toUpperCase()}", 
            style: const TextStyle(color: AscendTheme.textDim, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: task.progress,
              backgroundColor: AscendTheme.background,
              color: activeColor,
              minHeight: 6,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDailyTracker(List<Challenge> challenges) {
    if (challenges.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text("No active data feeds.", style: TextStyle(color: AscendTheme.textDim)),
      );
    }

    return Column(
      children: challenges.map((task) {
        Color color = _getAttributeColor(task.attribute);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    task.name.toUpperCase(), 
                    style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)
                  ),
                  Text(
                    "${task.current.toInt()}/${task.target.toInt()} ${task.unit.toUpperCase()}", 
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                height: 12,
                decoration: BoxDecoration(
                  border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
                  color: Colors.black,
                ),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: task.progress.clamp(0.0, 1.0),
                  child: Container(color: color),
                ),
              )
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getAttributeColor(ChallengeAttribute attr) {
    switch (attr) {
      case ChallengeAttribute.strength: return AscendTheme.primary;
      case ChallengeAttribute.agility: return AscendTheme.secondary;
      case ChallengeAttribute.intelligence: return Colors.white;
      case ChallengeAttribute.discipline: return AscendTheme.accent;
    }
  }
}