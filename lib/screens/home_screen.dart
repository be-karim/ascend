import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ascend/models/challenge.dart';
import 'package:ascend/models/enums.dart';
import 'package:ascend/providers/game_state_provider.dart';
import 'package:ascend/theme.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final player = gameState.stats;
    final activeChallenges = gameState.activeChallenges;

    return Scaffold(
      backgroundColor: Colors.transparent, // Background handled by MainScaffold
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            // Header with Avatar & Rings
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "ASCEND_OS v1.0",
                        style: TextStyle(color: AscendTheme.textDim, fontSize: 10, letterSpacing: 2.0),
                      ),
                      const SizedBox(height: 8),
                      // Typewriter Effect Widget (Simple implementation)
                      _TypewriterText(
                        text: "WELCOME BACK, OPERATOR.",
                        style: const TextStyle(
                          color: Colors.white, 
                          fontWeight: FontWeight.bold, 
                          fontSize: 18, 
                          letterSpacing: 1.0,
                          fontFamily: 'Courier',
                        ),
                      ),
                    ],
                  ),
                ),
                _buildAvatarRing(player.globalLevel, player.currentXp, player.maxXp),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Hero Section (Summary Cards)
            _buildHeroStats(player.streak, activeChallenges),
            
            const SizedBox(height: 30),
            
            const Text(
               "PRIORITY TARGET",
               style: TextStyle(color: AscendTheme.textDim, fontSize: 10, letterSpacing: 2.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildPriorityTask(activeChallenges),
            
            const SizedBox(height: 30),
            Center(
              child: Opacity(
                opacity: 0.5,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.hub, color: AscendTheme.textDim, size: 12),
                    const SizedBox(width: 8),
                    Text(
                      "FULL DAILY LOG AVAILABLE IN EXECUTE TAB",
                      style: TextStyle(color: AscendTheme.textDim.withOpacity(0.95), fontSize: 12, letterSpacing: 3.0),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.hub, color: AscendTheme.textDim, size: 12),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarRing(int level, int current, int max) {
    double progress = max > 0 ? current / max : 0.0;
    
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer Glow
        Container(
          width: 70, height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: AscendTheme.secondary.withValues(alpha: 0.2), blurRadius: 20)],
          ),
        ),
        // Progress Painter
        SizedBox(
          width: 64, height: 64,
          child: CircularProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            strokeWidth: 3,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            color: AscendTheme.secondary,
          ),
        ),
        // Inner Avatar
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            color: AscendTheme.surface,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 24),
        ),
        // Level Badge
        Positioned(
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AscendTheme.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AscendTheme.secondary),
            ),
            child: Text(
              "LVL $level",
              style: const TextStyle(color: AscendTheme.secondary, fontSize: 8, fontWeight: FontWeight.w900),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildHeroStats(int streak, List<Challenge> challenges) {
    final completed = challenges.where((c) => c.isCompleted).length;
    final total = challenges.length;
    
    return Row(
      children: [
        Expanded(child: _buildInfoCard("STREAK", "$streak", Icons.local_fire_department, AscendTheme.primary)),
        const SizedBox(width: 12),
        Expanded(child: _buildInfoCard("PROGRESS", "$completed/$total", Icons.check_circle, AscendTheme.accent)),
      ],
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AscendTheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(color: AscendTheme.textDim, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            ],
          ),
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
           color: AscendTheme.surface.withValues(alpha: 0.3),
           borderRadius: BorderRadius.circular(8),
           border: Border.all(color: Colors.white.withValues(alpha: 0.05), style: BorderStyle.solid),
         ),
         child: const Row(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             Icon(Icons.check, color: AscendTheme.textDim, size: 16),
             SizedBox(width: 8),
             Text("ALL TARGETS ELIMINATED", style: TextStyle(color: AscendTheme.textDim, fontFamily: 'Courier', fontSize: 12)),
           ],
         ),
      );
    }
    
    Color activeColor = _getAttributeColor(task.attribute);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [activeColor.withValues(alpha: 0.1), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: activeColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(task.name, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: activeColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                child: Text(task.attribute.name.toUpperCase().substring(0,3), style: TextStyle(color: activeColor, fontSize: 10, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: task.progress,
              backgroundColor: Colors.black,
              color: activeColor,
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "${(task.progress * 100).toInt()}% COMPLETE", 
              style: TextStyle(color: activeColor, fontSize: 10, fontFamily: 'Courier', fontWeight: FontWeight.bold)
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDailyTracker(List<Challenge> challenges) {
    if (challenges.isEmpty) {
      return const Text("No active logs.", style: TextStyle(color: AscendTheme.textDim));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: challenges.map((task) {
        Color baseColor = _getAttributeColor(task.attribute);
        return Container(
          margin: const EdgeInsets.only(bottom: 8.0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4), 
            border: Border(left: BorderSide(color: task.isCompleted ? baseColor : Colors.transparent, width: 2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                task.name.toUpperCase(), 
                style: TextStyle(
                  color: task.isCompleted ? AscendTheme.textDim : Colors.white, 
                  fontSize: 12, 
                  fontFamily: 'Courier',
                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                )
              ),
              Text(
                task.isCompleted ? "[DONE]" : "${(task.progress * 100).toInt()}%", 
                style: TextStyle(color: task.isCompleted ? baseColor : AscendTheme.textDim, fontSize: 10, fontFamily: 'Courier')
              ),
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

// Simple Typewriter Animation Widget
class _TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  const _TypewriterText({required this.text, required this.style});

  @override
  State<_TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<_TypewriterText> {
  String _displayedText = "";
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  void _startTyping() async {
    while (_currentIndex < widget.text.length) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
      setState(() {
        _displayedText += widget.text[_currentIndex];
        _currentIndex++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayedText + (_currentIndex < widget.text.length ? "_" : ""),
      style: widget.style,
    );
  }
}