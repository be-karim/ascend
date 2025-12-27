import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ascend/theme.dart';
import 'package:ascend/models/models.dart';
import 'package:ascend/state/app_state.dart';
import 'package:ascend/widgets/confetti_overlay.dart';
import 'package:ascend/widgets/challenge_card.dart'; // Import new widget

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  final AppState appState = AppState();
  final ConfettiController _confettiController = ConfettiController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    appState.addListener(_onStateChange);
  }

  @override
  void dispose() {
    appState.removeListener(_onStateChange);
    _confettiController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _onStateChange() {
    setState(() {});
  }

  // --- LOGIC ---

  void _addChallenge(String name, double target, ChallengeType type, ChallengeAttribute attribute, {String? unitOverride}) {
    String unit = unitOverride ?? 'reps';
    if (unitOverride == null) {
      if (type == ChallengeType.time) unit = 'min';
      if (type == ChallengeType.hydration) unit = 'ml';
    }

    appState.addChallenge(Challenge(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      current: 0,
      target: target,
      unit: unit,
      type: type,
      attribute: attribute,
    ));
    HapticFeedback.mediumImpact();
  }

  void _addStack(RoutineStack stack) {
    HapticFeedback.heavyImpact();
    // Delay slightly for effect
    for (var template in stack.tasks) {
      // Clone the template to a new challenge instance
      _addChallenge(template.name, template.target, template.type, template.attribute, unitOverride: template.unit);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("ROUTINE LOADED: ${stack.title}"),
        backgroundColor: AscendTheme.secondary,
        behavior: SnackBarBehavior.floating,
      )
    );
  }

  void _deleteChallenge(String id) {
    appState.removeChallenge(id);
    HapticFeedback.selectionClick();
  }

  void _editChallengeTarget(Challenge challenge, double newTarget) {
    setState(() {
      // In a real app we might want to update this in AppState cleaner
      // But for now, direct mutation on the reference works because of listeners
      // Actually appState.challenges is a list of objects. 
      // We should probably add a method in AppState to be safe, but this works for MVP.
      // Ideally: appState.updateTarget(challenge.id, newTarget);
      // We will just do a forced notify.
      // Since Dart objects are references, 'challenge' is the one in the list.
      // But 'target' is final in our model? 
      // Wait, in previous code Challenge.target was final. We need to check models.dart.
      // If it's final, we replace the object.
      
      // Let's assume we replace the challenge with a new one with updated target
      appState.removeChallenge(challenge.id);
      appState.addChallenge(Challenge(
        id: challenge.id,
        name: challenge.name,
        current: challenge.current,
        target: newTarget,
        unit: challenge.unit,
        type: challenge.type,
        attribute: challenge.attribute,
        isRunning: challenge.isRunning
      ));
    });
  }

  void _updateProgress(Challenge challenge, double amount) {
    bool wasCompleted = challenge.isCompleted;
    appState.updateChallengeProgress(challenge, amount);
    HapticFeedback.lightImpact();

    if (!wasCompleted && challenge.isCompleted) {
      _confettiController.play();
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("PROTOCOL COMPLETED: ${challenge.name}"),
          backgroundColor: AscendTheme.accent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _toggleTimer(Challenge challenge) {
    HapticFeedback.selectionClick();
    if (challenge.isRunning) {
      setState(() {
        challenge.isRunning = false;
      });
      _timer?.cancel();
    } else {
      for (var c in appState.challenges) {
        c.isRunning = false;
      }
      _timer?.cancel();

      setState(() {
        challenge.isRunning = true;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!challenge.isRunning) {
          timer.cancel();
          return;
        }
        double increment = 1 / 60.0;
        bool wasCompleted = challenge.isCompleted;
        appState.updateChallengeProgress(challenge, increment);

        if (!wasCompleted && challenge.current >= challenge.target) {
            challenge.current = challenge.target;
            challenge.isRunning = false;
            timer.cancel();
            appState.updateChallengeProgress(challenge, 50); 
            _confettiController.play();
            HapticFeedback.heavyImpact();
        }
      });
    }
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    final sortedChallenges = List<Challenge>.from(appState.challenges);
    sortedChallenges.sort((a, b) {
      if (a.isRunning != b.isRunning) return a.isRunning ? -1 : 1;
      if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
      return 0;
    });

    return Scaffold(
      body: ConfettiOverlay(
        controller: _confettiController,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        "PLANNER",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                      InkWell(
                        onTap: () => _showAddModal(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AscendTheme.primary.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: AscendTheme.primary)
                          ),
                          child: const Icon(Icons.add, color: AscendTheme.primary),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // ROUTINE STACKS
                  const Text("DEPLOY ROUTINE STACK", style: TextStyle(color: AscendTheme.textDim, fontSize: 10, letterSpacing: 2.0, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildRoutineStacksList(),
                  const SizedBox(height: 30),

                  // ACTIVE LIST
                  const Text(
                    "ACTIVE PROTOCOLS",
                    style: TextStyle(
                      color: AscendTheme.textDim,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (sortedChallenges.isEmpty)
                     const Padding(
                       padding: EdgeInsets.only(top: 50),
                       child: Center(
                         child: Text("NO ACTIVE PROTOCOLS", style: TextStyle(color: AscendTheme.textDim, letterSpacing: 1.5)),
                       ),
                     )
                  else
                    ...sortedChallenges.map((c) => ChallengeCard(
                      task: c,
                      onUpdate: _updateProgress,
                      onDelete: _deleteChallenge,
                      onToggleTimer: _toggleTimer,
                      onEditTarget: _editChallengeTarget,
                    )),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutineStacksList() {
    // Define Stacks here (In real app, move to AppState or Const)
    final stacks = [
      RoutineStack(
        title: "Morning Spartan",
        icon: Icons.wb_sunny,
        tasks: [
          Challenge(id: 't1', name: "Hydration", current: 0, target: 500, unit: "ml", type: ChallengeType.hydration, attribute: ChallengeAttribute.discipline),
          Challenge(id: 't2', name: "Cold Shower", current: 0, target: 1, unit: "rep", type: ChallengeType.reps, attribute: ChallengeAttribute.discipline),
          Challenge(id: 't3', name: "Push Ups", current: 0, target: 30, unit: "reps", type: ChallengeType.reps, attribute: ChallengeAttribute.strength),
        ]
      ),
      RoutineStack(
        title: "Runner's High",
        icon: Icons.directions_run,
        tasks: [
          Challenge(id: 't4', name: "Running", current: 0, target: 5, unit: "km", type: ChallengeType.reps, attribute: ChallengeAttribute.agility),
          Challenge(id: 't5', name: "Stretching", current: 0, target: 10, unit: "min", type: ChallengeType.time, attribute: ChallengeAttribute.agility),
        ]
      ),
      RoutineStack(
        title: "Monk Mode",
        icon: Icons.self_improvement,
        tasks: [
          Challenge(id: 't6', name: "Deep Work", current: 0, target: 90, unit: "min", type: ChallengeType.time, attribute: ChallengeAttribute.intelligence),
          Challenge(id: 't7', name: "Meditation", current: 0, target: 20, unit: "min", type: ChallengeType.time, attribute: ChallengeAttribute.discipline),
        ]
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: stacks.map((stack) => _buildStackCard(stack)).toList(),
      ),
    );
  }

  Widget _buildStackCard(RoutineStack stack) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () => _addStack(stack),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 140,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AscendTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(stack.icon, color: AscendTheme.secondary, size: 24),
              const SizedBox(height: 12),
              Text(stack.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Text("${stack.tasks.length} Tasks", style: const TextStyle(color: AscendTheme.textDim, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, 
      isScrollControlled: true,
      builder: (context) => _AddChallengeSheet(onAdd: _addChallenge),
    );
  }
}

class _AddChallengeSheet extends StatefulWidget {
  final Function(String, double, ChallengeType, ChallengeAttribute) onAdd;
  const _AddChallengeSheet({required this.onAdd});

  @override
  State<_AddChallengeSheet> createState() => _AddChallengeSheetState();
}

class _AddChallengeSheetState extends State<_AddChallengeSheet> {
  ChallengeType _selectedType = ChallengeType.reps;
  ChallengeAttribute _selectedAttribute = ChallengeAttribute.strength;
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _targetCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // ... (Keeping the Add Sheet Logic same as before for brevity, but it's included in the file)
    return Container(
      decoration: BoxDecoration(
        color: AscendTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      padding: EdgeInsets.only(
        top: 24, left: 24, right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("NEW PROTOCOL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 18)),
          const SizedBox(height: 24),
          
          const Text("TRACKING TYPE", style: TextStyle(color: AscendTheme.textDim, fontSize: 12, letterSpacing: 1.0)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildTypeBtn("REPS", ChallengeType.reps)),
              const SizedBox(width: 8),
              Expanded(child: _buildTypeBtn("TIME", ChallengeType.time)),
              const SizedBox(width: 8),
              Expanded(child: _buildTypeBtn("FLUID", ChallengeType.hydration)),
            ],
          ),
          const SizedBox(height: 16),

          const Text("TARGET ATTRIBUTE", style: TextStyle(color: AscendTheme.textDim, fontSize: 12, letterSpacing: 1.0)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildAttributeBtn("STR", ChallengeAttribute.strength, AscendTheme.primary)),
              const SizedBox(width: 8),
              Expanded(child: _buildAttributeBtn("AGI", ChallengeAttribute.agility, AscendTheme.secondary)),
              const SizedBox(width: 8),
              Expanded(child: _buildAttributeBtn("INT", ChallengeAttribute.intelligence, Colors.white)),
              const SizedBox(width: 8),
              Expanded(child: _buildAttributeBtn("DIS", ChallengeAttribute.discipline, AscendTheme.accent)),
            ],
          ),
          const SizedBox(height: 16),

          const Text("TASK NAME", style: TextStyle(color: AscendTheme.textDim, fontSize: 12, letterSpacing: 1.0)),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: AscendTheme.background,
              hintText: "e.g. Push Ups",
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("TARGET", style: TextStyle(color: AscendTheme.textDim, fontSize: 12, letterSpacing: 1.0)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _targetCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AscendTheme.background,
                        hintText: "100",
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                )
              ),
              const SizedBox(width: 16),
              Expanded(
                 child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("UNIT", style: TextStyle(color: AscendTheme.textDim, fontSize: 12, letterSpacing: 1.0)),
                    const SizedBox(height: 8),
                    Container(
                      height: 50,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AscendTheme.background.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Text(_getUnit(), style: const TextStyle(color: AscendTheme.textDim, fontWeight: FontWeight.bold)),
                    )
                  ],
                 )
              )
            ],
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(color: AscendTheme.textDim, fontWeight: FontWeight.bold))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AscendTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("INITIALIZE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getUnit() {
    if (_selectedType == ChallengeType.reps) return 'reps';
    if (_selectedType == ChallengeType.time) return 'min';
    return 'ml';
  }

  void _submit() {
    if (_nameCtrl.text.isEmpty || _targetCtrl.text.isEmpty) return;
    double? target = double.tryParse(_targetCtrl.text);
    if (target == null) return;

    widget.onAdd(_nameCtrl.text, target, _selectedType, _selectedAttribute);
    Navigator.pop(context);
  }

  Widget _buildTypeBtn(String label, ChallengeType type) {
    bool isSelected = _selectedType == type;
    Color color = AscendTheme.textDim;
    Color borderColor = Colors.white.withValues(alpha: 0.1);
    Color bg = AscendTheme.background;

    if (isSelected) {
      color = AscendTheme.secondary;
      borderColor = AscendTheme.secondary;
      bg = AscendTheme.secondary.withValues(alpha: 0.1);
    }

    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: borderColor)),
        child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }

  Widget _buildAttributeBtn(String label, ChallengeAttribute attr, Color color) {
    bool isSelected = _selectedAttribute == attr;
    return GestureDetector(
      onTap: () => setState(() => _selectedAttribute = attr),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? color : Colors.white.withValues(alpha: 0.2)),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.black : color.withValues(alpha: 0.5), fontWeight: FontWeight.bold, fontSize: 10)),
      ),
    );
  }
}