import 'package:flutter/material.dart';
import 'package:ascend/models/models.dart';
import 'package:ascend/theme.dart';

import 'package:ascend/state/app_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AppState appState = AppState();

  @override
  void initState() {
    super.initState();
    appState.addListener(_onStateChange);
  }

  @override
  void dispose() {
    appState.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroSection(),
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
                    _buildPriorityTask(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    // Uses AppState player
    double progress = appState.player.currentXp / appState.player.maxXp;
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
                    color: Colors.white, // Required for mask
                  ),
                ),
              ),
              const Text(
                "SYSTEM ONLINE",
                style: TextStyle(
                  color: AscendTheme.textDim,
                  fontSize: 10,
                  letterSpacing: 2.0,
                ),
              )
            ],
          ),
          
          // XP Bar and Profile
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(text: "LVL ", style: TextStyle(color: AscendTheme.secondary, fontSize: 10, letterSpacing: 1.0, fontWeight: FontWeight.bold)),
                        TextSpan(text: "${appState.player.globalLevel}", style: const TextStyle(color: AscendTheme.secondary, fontSize: 10, fontWeight: FontWeight.bold)),
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

  Widget _buildHeroSection() {
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
              // Avatar Holo
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
                  "${appState.player.globalLevel}",
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
                  Expanded(child: _buildInfoCard("STREAK", "${appState.player.streak}", AscendTheme.accent)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildInfoCard("XP TODAY", "${appState.player.currentXp}", AscendTheme.primary)),
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

  Widget _buildPriorityTask() {
    final task = appState.priorityTarget;

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
    
    // Determine color
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
}
