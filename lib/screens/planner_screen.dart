import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ascend/theme.dart';
import 'package:ascend/models/models.dart';

import 'package:ascend/state/app_state.dart';

import 'package:ascend/widgets/confetti_overlay.dart';

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

  void _addChallenge(String name, double target, ChallengeType type, ChallengeAttribute attribute) {
    String unit = 'reps';
    if (type == ChallengeType.time) unit = 'min';
    if (type == ChallengeType.hydration) unit = 'ml';

    appState.addChallenge(Challenge(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      current: 0,
      target: target,
      unit: unit,
      type: type,
      attribute: attribute,
    ));
  }

  void _deleteChallenge(String id) {
    appState.removeChallenge(id);
  }

  void _updateProgress(Challenge challenge, double amount) {
    // Check if already completed to avoid re-triggering completion effects if handled
    bool wasCompleted = challenge.isCompleted;
    
    appState.updateChallengeProgress(challenge, amount);

    if (!wasCompleted && challenge.isCompleted) {
      _confettiController.play();
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
    if (challenge.isRunning) {
      // Stop
      setState(() {
        challenge.isRunning = false;
      });
      _timer?.cancel();
    } else {
      // Start
      // Stop others
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
        
        // Check check before update for trigger
        bool wasCompleted = challenge.isCompleted;
        appState.updateChallengeProgress(challenge, increment);

        if (!wasCompleted && challenge.current >= challenge.target) {
            challenge.current = challenge.target;
            challenge.isRunning = false;
            timer.cancel();
            appState.updateChallengeProgress(challenge, 50); // Bonus using global
            _confettiController.play();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("TIMER FINISHED: ${challenge.name}"),
                backgroundColor: AscendTheme.accent,
                behavior: SnackBarBehavior.floating,
              ),
            );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sort: Running, then Incomplete, then Complete
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
                   Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      "ACTIVE PROTOCOLS",
                      style: TextStyle(
                        color: AscendTheme.textDim,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                    InkWell(
                      onTap: () => _showAddModal(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add, color: AscendTheme.secondary),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                if (sortedChallenges.isEmpty)
                   const Padding(
                     padding: EdgeInsets.only(top: 50),
                     child: Center(
                       child: Text("NO ACTIVE PROTOCOLS", style: TextStyle(color: AscendTheme.textDim, letterSpacing: 1.5)),
                     ),
                   )
                else
                  ...sortedChallenges.map((c) => _buildChallengeCard(c)),
              ]),
            ),
          ),
        ],
      ),
    ), // Close ConfettiOverlay
    ); // Close Scaffold
  }

  Widget _buildChallengeCard(Challenge task) {
    Color activeColor = AscendTheme.primary;
    if (task.type == ChallengeType.hydration) activeColor = AscendTheme.secondary;
    if (task.type == ChallengeType.time) activeColor = AscendTheme.accent;
    if (task.isCompleted) activeColor = AscendTheme.accent;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AscendTheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: task.isRunning 
              ? AscendTheme.accent.withValues(alpha: 0.5) 
              : Colors.white.withValues(alpha: 0.08)
        ),
        boxShadow: task.isRunning ? [
           BoxShadow(
             color: AscendTheme.accent.withValues(alpha: 0.1),
             blurRadius: 15,
             spreadRadius: 2,
           )
        ] : [],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          task.name,
                          style: TextStyle(
                            color: activeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0, bottom: 2.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getAttributeColor(task.attribute).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: _getAttributeColor(task.attribute).withValues(alpha: 0.5), width: 0.5),
                            ),
                            child: Text(
                              task.attribute.name.substring(0, 3).toUpperCase(),
                              style: TextStyle(
                                fontSize: 8, 
                                fontWeight: FontWeight.bold, 
                                color: _getAttributeColor(task.attribute)
                              ),
                            ),
                          ),
                        ),
                        if (task.isRunning)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Container(
                              width: 8, height: 8, 
                              decoration: const BoxDecoration(
                                color: AscendTheme.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDisplayValue(task),
                      style: const TextStyle(
                        fontFamily: 'Roboto', // Should be Tech font ideally
                        color: AscendTheme.textDim,
                        fontSize: 12,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  "${(task.progress * 100).toInt()}%",
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: task.isCompleted ? AscendTheme.accent : Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: task.progress,
                minHeight: 6,
                backgroundColor: AscendTheme.background,
                color: activeColor,
              ),
            ),
            const SizedBox(height: 16),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!task.isCompleted) _buildControls(task),
                if (task.isCompleted) 
                   const Padding(
                     padding: EdgeInsets.symmetric(vertical: 4),
                     child: Text("DONE", style: TextStyle(color: AscendTheme.accent, fontWeight: FontWeight.bold, letterSpacing: 2)),
                   ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _deleteChallenge(task.id), 
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: Colors.red.withValues(alpha: 0.5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDisplayValue(Challenge task) {
     if (task.type == ChallengeType.time) {
       int m = task.current.floor();
       int s = ((task.current - m) * 60).floor();
       return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')} / ${task.target.toInt()} min";
     }
     return "${task.current.toInt()} / ${task.target.toInt()} ${task.unit}";
  }

  Widget _buildControls(Challenge task) {
    if (task.type == ChallengeType.time) {
      int m = task.current.floor();
      int s = ((task.current - m) * 60).floor();
      String timeStr = "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
      return Row(
        children: [
           Text(timeStr, style: const TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold, fontSize: 18)),
           const SizedBox(width: 16),
           GestureDetector(
             onTap: () => _toggleTimer(task),
             child: Container(
               width: 40, height: 40,
               decoration: BoxDecoration(
                 color: task.isRunning ? AscendTheme.accent : Colors.white.withValues(alpha: 0.1),
                 shape: BoxShape.circle,
               ),
               child: Icon(
                 task.isRunning ? Icons.pause : Icons.play_arrow,
                 color: task.isRunning ? Colors.black : Colors.white,
               ),
             ),
           )
        ],
      );
    } else if (task.type == ChallengeType.hydration) {
       return Row(
         children: [
            _buildQuickAddBtn(task, 250, Icons.water_drop),
            const SizedBox(width: 8),
            _buildQuickAddBtn(task, 500, Icons.water_drop),
         ],
       );
    } else {
      // Reps
      return Row(
        children: [
          _buildQuickAddBtn(task, 5, null, label: "+5"),
          const SizedBox(width: 8),
          _buildQuickAddBtn(task, 10, null, label: "+10"),
        ],
      );
    }
  }

  Widget _buildQuickAddBtn(Challenge task, double amount, IconData? icon, {String? label}) {
     return InkWell(
       onTap: () => _updateProgress(task, amount),
       borderRadius: BorderRadius.circular(8),
       child: Container(
         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
         decoration: BoxDecoration(
           color: Colors.white.withValues(alpha: 0.05),
           borderRadius: BorderRadius.circular(8),
           border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
         ),
         child: Row(
           children: [
              if (icon != null) Icon(icon, size: 14, color: task.type == ChallengeType.hydration ? AscendTheme.secondary : AscendTheme.textDim),
              if (icon != null) const SizedBox(width: 4),
              Text(
                label ?? amount.toInt().toString(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
           ],
         ),
       ),
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

  void _showAddModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // For glass effect inside
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
          const Text(
            "NEW PROTOCOL",
            style: TextStyle(
              color: Colors.white, 
              fontWeight: FontWeight.bold, 
              letterSpacing: 1.5,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 24),
          
          // Type Selector
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

          // Attribute Selector
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

          // Inputs
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
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
                      child: Text(
                        _getUnit(),
                        style: const TextStyle(color: AscendTheme.textDim, fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                 )
              )
            ],
          ),
          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("CANCEL", style: TextStyle(color: AscendTheme.textDim, fontWeight: FontWeight.bold)),
                ),
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
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
        ),
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
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : color.withValues(alpha: 0.5), 
            fontWeight: FontWeight.bold, 
            fontSize: 10
          ),
        ),
      ),
    );
  }
}
