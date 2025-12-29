import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ascend/theme.dart';
import 'package:ascend/models/challenge.dart';
import 'package:ascend/models/enums.dart';
import 'package:ascend/providers/game_state_provider.dart';
import 'package:ascend/widgets/confetti_overlay.dart';

// --- ENUMS ---
enum TabCategory { all, body, mind, grind }

// --- MAIN SCREEN ---
class DailyLogScreen extends ConsumerStatefulWidget {
  const DailyLogScreen({super.key});

  @override
  ConsumerState<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends ConsumerState<DailyLogScreen> {
  final ConfettiController _confettiController = ConfettiController();
  late PageController _pageController;
  Timer? _timer;
  
  TabCategory _selectedTab = TabCategory.all;
  bool _isCardView = true; 
  final Set<String> _expandedIds = {}; // Für ListView Details

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _pageController.dispose();
    _timer?.cancel(); // WICHTIG: Timer aufräumen
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final allChallenges = gameState.activeChallenges;
    
    // 1. FILTER LOGIK
    final filtered = allChallenges.where((c) {
      switch (_selectedTab) {
        case TabCategory.all: return true;
        case TabCategory.body: 
          return c.attribute == ChallengeAttribute.strength || c.attribute == ChallengeAttribute.agility;
        case TabCategory.mind: 
          return c.attribute == ChallengeAttribute.intelligence;
        case TabCategory.grind: 
          return c.attribute == ChallengeAttribute.discipline;
      }
    }).toList();

    // 2. SORTIERUNG: Laufende -> Offene -> Fertige
    filtered.sort((a, b) {
      if (a.isRunning != b.isRunning) return a.isRunning ? -1 : 1;
      if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
      return 0;
    });

    final pendingCount = filtered.where((c) => !c.isCompleted).length;
    final totalDailyProgress = allChallenges.isEmpty 
        ? 0.0 
        : allChallenges.where((c) => c.isCompleted).length / allChallenges.length;

    return Scaffold(
      backgroundColor: const Color(0xFF050505), // Deep Black Background
      body: ConfettiOverlay(
        controller: _confettiController,
        child: SafeArea(
          child: Column(
            children: [
              // HEADER SECTION
              _buildDailyHeader(totalDailyProgress, pendingCount),
              
              const SizedBox(height: 20),

              // TAB NAVIGATION
              _buildTabs(),

              const SizedBox(height: 16),

              // VIEW TOGGLE & INFO
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isCardView ? "SWIPE TO LOG" : "LIST OVERVIEW",
                      style: const TextStyle(
                        color: AscendTheme.textDim, 
                        fontSize: 10, 
                        letterSpacing: 2.0, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isCardView ? Icons.list_alt : Icons.view_carousel, 
                        color: AscendTheme.secondary, 
                        size: 22
                      ),
                      onPressed: () { 
                        setState(() => _isCardView = !_isCardView);
                        HapticFeedback.selectionClick();
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    )
                  ],
                ),
              ),

              // MAIN CONTENT AREA
              Expanded(
                child: filtered.isEmpty 
                  ? _buildEmptyState()
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _isCardView 
                        ? _buildCarouselView(filtered) 
                        : _buildListView(filtered),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- HEADER WIDGETS ---

  Widget _buildDailyHeader(double progress, int pending) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("TODAY'S MISSION", style: TextStyle(color: AscendTheme.textDim, fontSize: 10, letterSpacing: 2.0, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(pending == 0 ? "ALL CLEAR" : "$pending TASKS LEFT", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
            ],
          ),
          // Progress Ring
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 50, height: 50,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation(AscendTheme.primary),
                ),
              ),
              Text("${(progress * 100).toInt()}%", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          _tabBtn(TabCategory.all, "ALL"),
          const SizedBox(width: 8),
          _tabBtn(TabCategory.body, "BODY", Colors.pinkAccent),
          const SizedBox(width: 8),
          _tabBtn(TabCategory.mind, "MIND", Colors.cyanAccent),
          const SizedBox(width: 8),
          _tabBtn(TabCategory.grind, "GRIND", Colors.greenAccent),
        ],
      ),
    );
  }

  Widget _tabBtn(TabCategory cat, String label, [Color activeColor = Colors.white]) {
    final bool isActive = _selectedTab == cat;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedTab = cat);
        HapticFeedback.lightImpact();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? activeColor.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? activeColor.withValues(alpha: 0.5) : Colors.transparent
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? activeColor : AscendTheme.textDim,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0
          ),
        ),
      ),
    );
  }

  // --- CAROUSEL VIEW ---

  Widget _buildCarouselView(List<Challenge> challenges) {
    return PageView.builder(
      controller: _pageController,
      itemCount: challenges.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final task = challenges[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: ActiveChallengeCard(
            task: task,
            onUpdate: (amt) => _logProgress(task, amt),
            onTimerToggle: () => _toggleTimer(task),
          ),
        );
      },
    );
  }

  // --- LIST VIEW ---

  Widget _buildListView(List<Challenge> challenges) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      itemCount: challenges.length,
      itemBuilder: (ctx, i) {
        final task = challenges[i];
        final isExpanded = _expandedIds.contains(task.id);
        final color = _getColor(task.attribute);
        
        // Smarte Berechnung für den Quick-Button Amount
        double quickAmount = 1;
        if (task.target >= 1000) quickAmount = 250; 
        else if (task.target >= 100) quickAmount = 25; 
        else if (task.target >= 30) quickAmount = 5;
        
        final unitLabel = task.unit.length > 4 ? "" : task.unit.toUpperCase();

        return GestureDetector(
          onTap: () => setState(() {
            isExpanded ? _expandedIds.remove(task.id) : _expandedIds.add(task.id);
            HapticFeedback.selectionClick();
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1522),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: task.isCompleted ? AscendTheme.accent.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.05)
              ),
            ),
            child: Column(
              children: [
                // MAIN ROW
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: task.isCompleted ? AscendTheme.accent.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        task.isCompleted ? Icons.check : _getIcon(task.type), 
                        color: task.isCompleted ? AscendTheme.accent : color, 
                        size: 16
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(task.name, style: TextStyle(fontWeight: FontWeight.bold, color: task.isCompleted ? AscendTheme.textDim : Colors.white, fontSize: 14)),
                          const SizedBox(height: 4),
                          if (!isExpanded && !task.isCompleted)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: task.current / task.target,
                                backgroundColor: Colors.white10,
                                valueColor: AlwaysStoppedAnimation(color.withValues(alpha: 0.5)),
                                minHeight: 2,
                              ),
                            )
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (!isExpanded)
                      task.type == ChallengeType.time 
                        ? Icon(task.isRunning ? Icons.pause_circle : Icons.play_circle, color: task.isRunning ? Colors.white : Colors.white24)
                        : Text(
                            "${task.current.toInt()}/${task.target.toInt()}", 
                            style: TextStyle(color: AscendTheme.textDim, fontFamily: 'Courier', fontWeight: FontWeight.bold, fontSize: 12)
                          ),
                  ],
                ),
                
                // EXPANDED DETAILS
                if (isExpanded) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text("PROGRESS", style: TextStyle(fontSize: 9, color: AscendTheme.textDim, letterSpacing: 1.0)),
                      const Spacer(),
                      Text("${(task.current / task.target * 100).toInt()}%", style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (task.current / task.target).clamp(0.0, 1.0),
                      backgroundColor: Colors.black,
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!task.isCompleted)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (task.type == ChallengeType.time)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: task.isRunning ? Colors.white12 : color.withValues(alpha: 0.2),
                              foregroundColor: task.isRunning ? Colors.white : color,
                            ),
                            icon: Icon(task.isRunning ? Icons.pause : Icons.play_arrow),
                            label: Text(task.isRunning ? "PAUSE" : "START TIMER"),
                            onPressed: () => _toggleTimer(task),
                          )
                        else ...[
                          TextButton(
                            onPressed: () => _logProgress(task, 1),
                            child: const Text("+1", style: TextStyle(color: Colors.white38)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: color.withValues(alpha: 0.15),
                              foregroundColor: color,
                              side: BorderSide(color: color.withValues(alpha: 0.3)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                            ),
                            onPressed: () => _logProgress(task, quickAmount),
                            child: Text("+${quickAmount.toInt()} $unitLabel", style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ]
                      ],
                    )
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: AscendTheme.accent.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          const Text("NO CHALLENGES FOUND", style: TextStyle(color: AscendTheme.textDim, letterSpacing: 2.0)),
        ],
      ),
    );
  }

  // --- LOGIC HELPER ---

  void _logProgress(Challenge task, double amount) {
    if (task.isCompleted) return;

    ref.read(gameProvider.notifier).updateProgress(task.id, amount);
    
    // FeedbackCheck direkt (etwas optimistisch für UI Responsiveness)
    if (task.current + amount >= task.target) {
      _confettiController.play();
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  // FIXED: Timer Logic
  void _toggleTimer(Challenge task) {
    HapticFeedback.selectionClick();
    
    // 1. Wenn er bereits läuft -> Stoppen
    if (task.isRunning) {
      ref.read(gameProvider.notifier).toggleTimer(task.id, false);
      _timer?.cancel();
    } 
    // 2. Wenn er gestartet wird -> Ticker starten
    else {
      // Vorherigen Timer sicherheitshalber stoppen (Single Focus)
      _timer?.cancel();
      
      // Im Provider Status setzen (damit UI updated)
      ref.read(gameProvider.notifier).toggleTimer(task.id, true);
      
      // Lokalen Ticker starten, der den Fortschritt updated
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        // Frischen State holen, um zu prüfen ob er noch laufen soll
        final currentTask = ref.read(gameProvider).activeChallenges
            .firstWhere((c) => c.id == task.id, orElse: () => task);
            
        if (!currentTask.isRunning || currentTask.isCompleted) {
          t.cancel();
          // Falls completed durch Zeitablauf -> Timer im State stoppen
          if (currentTask.isCompleted && currentTask.isRunning) {
             ref.read(gameProvider.notifier).toggleTimer(task.id, false);
             _confettiController.play();
             HapticFeedback.heavyImpact();
          }
          return;
        }
        
        // Fortschritt addieren (1 Sekunde = 1/60 Minute)
        // Annahme: Unit ist 'min'. Wenn Unit 'hours' ist, anpassen.
        ref.read(gameProvider.notifier).updateProgress(task.id, 1/60);
      });
    }
  }
}

// ==========================================
// 🎨 ACTIVE CHALLENGE CARD (The Main Component)
// ==========================================

class ActiveChallengeCard extends StatelessWidget {
  final Challenge task;
  final Function(double) onUpdate;
  final VoidCallback onTimerToggle;

  const ActiveChallengeCard({super.key, required this.task, required this.onUpdate, required this.onTimerToggle});

  @override
  Widget build(BuildContext context) {
    final color = _getColor(task.attribute);
    final isDone = task.isCompleted;
    final progress = (task.current / task.target).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF151A25),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
        ),
        child: Stack(
          children: [
            // 1. ANIMATED BACKGROUND FILL
            Align(
              alignment: Alignment.bottomCenter,
              child: LayoutBuilder(
                builder: (ctx, constraints) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    height: constraints.maxHeight * progress,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDone ? AscendTheme.accent.withValues(alpha: 0.2) : color.withValues(alpha: 0.15),
                    ),
                  );
                },
              ),
            ),

            // 2. CONTENT
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Header
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1))
                            ),
                            child: Text(
                              task.attribute.name.toUpperCase(),
                              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                            ),
                          ),
                          if (task.type == ChallengeType.time)
                             Icon(Icons.timer_outlined, color: AscendTheme.textDim, size: 16),
                        ],
                      ),
                      const SizedBox(height: 32),
                      // Main Icon
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone ? AscendTheme.accent : color.withValues(alpha: 0.1),
                          boxShadow: [
                            BoxShadow(color: color.withValues(alpha: isDone ? 0.6 : 0.0), blurRadius: 40, spreadRadius: -5)
                          ]
                        ),
                        child: Icon(_getIcon(task.type), size: 40, color: isDone ? Colors.black : color),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        task.name.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, height: 1.2),
                      ),
                    ],
                  ),

                  // PROGRESS TEXT
                  Column(
                    children: [
                      Text(
                        "${task.current.toStringAsFixed(task.type == ChallengeType.time ? 0 : 0)} / ${task.target.toInt()}",
                        style: const TextStyle(fontFamily: 'Courier', fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        task.unit.toUpperCase(),
                        style: const TextStyle(color: AscendTheme.textDim, fontSize: 12, letterSpacing: 2.0),
                      ),
                    ],
                  ),

                  // 3. SMART CONTROLS
                  SizedBox(
                    height: 80,
                    child: isDone 
                      ? _buildCompletedState() 
                      : _buildSmartControls(context, color),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: AscendTheme.accent.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AscendTheme.accent)
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check, color: AscendTheme.accent, size: 18),
            SizedBox(width: 8),
            Text("MISSION COMPLETE", style: TextStyle(color: AscendTheme.accent, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartControls(BuildContext context, Color color) {
    if (task.type == ChallengeType.time) {
      return Center(
        child: GestureDetector(
          onTap: onTimerToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 72, height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: task.isRunning ? Colors.white : color.withValues(alpha: 0.2),
              border: Border.all(color: task.isRunning ? Colors.white : color, width: 2),
              boxShadow: task.isRunning ? [BoxShadow(color: Colors.white.withValues(alpha: 0.3), blurRadius: 20)] : []
            ),
            child: Icon(
              task.isRunning ? Icons.pause : Icons.play_arrow, 
              size: 32, 
              color: task.isRunning ? Colors.black : Colors.white
            ),
          ),
        ),
      );
    } 
    
    if (task.type == ChallengeType.boolean) {
      return Center(
        child: SizedBox(
          width: 200,
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color.withValues(alpha: 0.2),
              foregroundColor: color,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: color)),
            ),
            onPressed: () => onUpdate(1),
            child: const Text("MARK DONE", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      );
    }

    bool isHighValue = task.target >= 100;
    
    if (isHighValue) {
       double step = task.target / 10;
       if (step > 100) step = (step / 50).round() * 50.0;
       
       return Row(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
           _ControlBtn(label: "+${step.toInt()}", onTap: () => onUpdate(step), color: Colors.white12),
           const SizedBox(width: 16),
           _ControlBtn(label: "+${(step * 2).toInt()}", onTap: () => onUpdate(step * 2), color: color.withValues(alpha: 0.2), highlight: true),
         ],
       );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
           IconButton(
             onPressed: () => onUpdate(-1),
             icon: const Icon(Icons.remove, color: Colors.white54),
             style: IconButton.styleFrom(backgroundColor: Colors.white10, padding: const EdgeInsets.all(12)),
           ),
           const SizedBox(width: 24),
           _ControlBtn(
             label: "LOG +1", 
             onTap: () => onUpdate(1), 
             color: color.withValues(alpha: 0.2), 
             highlight: true, 
             width: 120
           ),
           const SizedBox(width: 24),
           IconButton(
             onPressed: () => onUpdate(1),
             icon: const Icon(Icons.add, color: Colors.white54),
             style: IconButton.styleFrom(backgroundColor: Colors.white10, padding: const EdgeInsets.all(12)),
           ),
        ],
      );
    }
  }
}

class _ControlBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool highlight;
  final double width;

  const _ControlBtn({required this.label, required this.onTap, required this.color, this.highlight = false, this.width = 80});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onTap();
        HapticFeedback.lightImpact();
      },
      child: Container(
        width: width,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: highlight ? Border.all(color: Colors.white30) : null,
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}

// --- UTILS ---

Color _getColor(ChallengeAttribute attr) {
  switch (attr) {
    case ChallengeAttribute.strength: return Colors.pinkAccent; 
    case ChallengeAttribute.agility: return Colors.orangeAccent;
    case ChallengeAttribute.intelligence: return Colors.cyanAccent;
    case ChallengeAttribute.discipline: return const Color(0xFF69F0AE); // Green
  }
}

IconData _getIcon(ChallengeType type) {
  switch (type) {
    case ChallengeType.reps: return Icons.fitness_center;
    case ChallengeType.time: return Icons.timer_outlined;
    case ChallengeType.hydration: return Icons.water_drop_outlined;
    case ChallengeType.boolean: return Icons.check_box_outlined;
  }
}