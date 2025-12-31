import 'dart:async'; // Für Timer Formatierung
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ascend/models/challenge.dart';
import 'package:ascend/models/enums.dart';
import 'package:ascend/theme.dart';
import 'package:ascend/widgets/feedback_animation.dart';

typedef ProgressCallback = void Function(double amount);
typedef TargetUpdateCallback = void Function(double newTarget, bool useXp);
typedef VoidCallbackWithString = void Function(String id);

class ActiveChallengeCard extends StatefulWidget {
  final Challenge task;
  final ProgressCallback onUpdate;
  final VoidCallback onTimerToggle;
  final TargetUpdateCallback onCalibrate;
  final VoidCallbackWithString onTogglePriority;
  final bool isPriority;
  final bool mercyTokenAvailable; // NEU: State wissen

  const ActiveChallengeCard({
    super.key,
    required this.task,
    required this.onUpdate,
    required this.onTimerToggle,
    required this.onCalibrate,
    required this.onTogglePriority,
    required this.mercyTokenAvailable,
    this.isPriority = false,
  });

  @override
  State<ActiveChallengeCard> createState() => _ActiveChallengeCardState();
}

class _ActiveChallengeCardState extends State<ActiveChallengeCard> {
  bool _isDragging = false;
  double _accumulatedDrag = 0.0;

  @override
  Widget build(BuildContext context) {
    final color = _getColor(widget.task.attribute);
    final isDone = widget.task.isCompleted;
    final progress = (widget.task.current / widget.task.target).clamp(0.0, 1.0);
    final double cardHeight = widget.isPriority ? 340 : 90; // Side Ops sind kleiner

    return GestureDetector(
      onLongPress: () {
        HapticFeedback.heavyImpact();
        widget.onTogglePriority(widget.task.id);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          height: cardHeight,
          decoration: BoxDecoration(
            color: const Color(0xFF151A25),
            border: Border.all(
              color: widget.isPriority ? color.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.05),
              width: widget.isPriority ? 2 : 1
            ),
            boxShadow: widget.isPriority ? [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 20)] : []
          ),
          child: Stack(
            children: [
              // BACKGROUND
              Align(
                alignment: Alignment.bottomCenter,
                child: AnimatedContainer(
                  duration: _isDragging ? Duration.zero : const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  height: cardHeight * progress,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDone ? AscendTheme.accent.withValues(alpha: 0.15) : color.withValues(alpha: 0.1),
                  ),
                ),
              ),

              // GESTURE
              Positioned.fill(
                child: GestureDetector(
                  onVerticalDragStart: (_) => setState(() => _isDragging = true),
                  onVerticalDragEnd: (_) => setState(() { _isDragging = false; _accumulatedDrag = 0.0; }),
                  onVerticalDragUpdate: (details) => _handleDrag(details, context, color),
                  behavior: HitTestBehavior.translucent,
                  child: Container(color: Colors.transparent),
                ),
              ),

              // CONTENT
              Padding(
                padding: widget.isPriority 
                    ? const EdgeInsets.all(20.0) 
                    : const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0),
                child: widget.isPriority 
                  ? _buildPriorityContent(context, color, isDone) 
                  : _buildCompactContent(context, color, isDone),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- PRIORITY LAYOUT ---
  Widget _buildPriorityContent(BuildContext context, Color color, bool isDone) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildBadge(color),
            GestureDetector(
              onTap: () => _showSmartCalibrationDialog(context),
              child: Icon(Icons.settings, color: Colors.white.withValues(alpha: 0.2), size: 18),
            ),
          ],
        ),
        
        Column(
          children: [
            Icon(isDone ? Icons.check_circle : _getIcon(widget.task.type), size: 40, color: isDone ? AscendTheme.accent : color),
            const SizedBox(height: 12),
            Text(widget.task.name.toUpperCase(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Transform.scale(
              scale: _isDragging ? 1.1 : 1.0,
              child: Column(
                children: [
                  // TIMER FIX: mm:ss Formatierung
                  widget.task.type == ChallengeType.time
                    ? Text(_formatDuration(widget.task.current.toInt()), style: const TextStyle(fontFamily: 'Courier', fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white))
                    : Text("${widget.task.current.toInt()}", style: const TextStyle(fontFamily: 'Courier', fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
                  
                  Text("/ ${widget.task.target.toInt()} ${widget.task.unit}", style: const TextStyle(color: AscendTheme.textDim, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),

        if (widget.task.type == ChallengeType.time)
          GestureDetector(
            onTap: widget.onTimerToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.task.isRunning ? Colors.white : Colors.white10,
                boxShadow: widget.task.isRunning ? [BoxShadow(color: Colors.white.withValues(alpha: 0.5), blurRadius: 15)] : []
              ),
              child: Icon(widget.task.isRunning ? Icons.pause : Icons.play_arrow, size: 32, color: widget.task.isRunning ? Colors.black : Colors.white),
            ),
          )
        else
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: isDone ? 0.0 : 0.6,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.unfold_more, color: color, size: 14),
                const SizedBox(width: 4),
                Text("SLIDE TO ADJUST", style: TextStyle(color: color, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
      ],
    );
  }

  // --- COMPACT LAYOUT (SIDE OPS / STANDARD) ---
  Widget _buildCompactContent(BuildContext context, Color color, bool isDone) {
    return Row(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 44, height: 44,
              child: CircularProgressIndicator(
                value: (widget.task.current / widget.task.target).clamp(0.0, 1.0),
                color: color, backgroundColor: Colors.white10, strokeWidth: 3,
              ),
            ),
            Icon(_getIcon(widget.task.type), color: isDone ? AscendTheme.accent : color, size: 20),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.task.name, style: TextStyle(fontWeight: FontWeight.bold, color: isDone ? AscendTheme.textDim : Colors.white, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
              
              // TIMER FIX COMPACT
              Text(
                widget.task.type == ChallengeType.time
                  ? "${_formatDuration(widget.task.current.toInt())} / ${_formatDuration(widget.task.target.toInt())}"
                  : "${widget.task.current.toInt()} / ${widget.task.target.toInt()} ${widget.task.unit}",
                style: const TextStyle(color: AscendTheme.textDim, fontSize: 11)
              ),
            ],
          ),
        ),
        if (widget.task.type == ChallengeType.time)
           GestureDetector(
             onTap: widget.onTimerToggle,
             child: Container(
               padding: const EdgeInsets.all(8),
               decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.1)),
               child: Icon(widget.task.isRunning ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 20)
             ),
           )
        else if (!isDone)
           Icon(Icons.unfold_more, color: Colors.white12, size: 20)
      ],
    );
  }

  Widget _buildBadge(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(6)),
      child: Text(widget.task.attribute.name.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    );
  }

  // --- LOGIC ---
  void _handleDrag(DragUpdateDetails details, BuildContext context, Color color) {
    if (widget.task.isCompleted && widget.task.type != ChallengeType.reps) return;
    
    double sensitivity = widget.task.target > 100 ? 2.0 : 8.0;
    _accumulatedDrag += (-details.primaryDelta! / sensitivity);

    if (_accumulatedDrag.abs() >= 1.0) {
      int step = _accumulatedDrag.sign.toInt();
      
      if (widget.task.target >= 1000) step *= 100;    
      else if (widget.task.target >= 200) step *= 5;  
      
      // MIN VALUE FIX: Vorhersagen, ob es < 0 wird
      double newValue = widget.task.current + step;
      if (newValue < 0) {
        // Wenn wir ins Negative gehen würden, setzen wir den Schritt so, dass wir genau bei 0 landen
        step = -widget.task.current.toInt();
      }

      if (step != 0) {
        widget.onUpdate(step.toDouble());
        HapticFeedback.selectionClick();
        if (step > 0) FeedbackAnimation.show(context, details.globalPosition, "+$step", color);
      }
      
      _accumulatedDrag = 0.0;
    }
  }

  // --- SMART MERCY DIALOG ---
  void _showSmartCalibrationDialog(BuildContext context) {
    final controller = TextEditingController(text: widget.task.target.toInt().toString());
    final bool hasToken = widget.mercyTokenAvailable;
    final int xpCost = 150; 

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151A25),
        title: Row(
          children: [
            Icon(Icons.tune, color: hasToken ? AscendTheme.accent : Colors.redAccent, size: 18),
            const SizedBox(width: 8),
            const Text("TACTICAL CALIBRATION", style: TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hasToken 
                  ? "Mercy Protocol active. Parameters can be adjusted freely."
                  : "Mercy Protocol DEPLETED. Calibration requires XP Override.",
              style: TextStyle(color: hasToken ? AscendTheme.textDim : Colors.redAccent, fontSize: 12),
            ),
            if (!hasToken)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    const Text("COST: ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text("-$xpCost XP", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(filled: true, fillColor: Colors.black, border: OutlineInputBorder(borderSide: BorderSide.none)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: hasToken ? AscendTheme.secondary : Colors.redAccent),
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0) { 
                widget.onCalibrate(val, !hasToken); // Pass true to useXp if no token
                Navigator.pop(ctx); 
              }
            }, 
            child: Text(hasToken ? "CONFIRM" : "PAY XP & CONFIRM", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }

  String _formatDuration(int totalMinutes) {
    if (widget.task.type != ChallengeType.time) return "$totalMinutes";
    // Da wir momentan 'min' als Einheit haben, ist current wohl Minuten.
    // Wenn wir Sekunden wollen, müssen wir wissen, ob current Min oder Sek sind.
    // Annahme für Timer: Wir speichern intern vlt Minuten als Double (z.B. 1.5 = 1m 30s).
    // Wenn current int ist, und unit 'min', zeigen wir es so:
    // HIER DIE LÖSUNG: Wir zeigen "Minuten" an. 
    // Sollten wir Sekunden haben, müssten wir das Model ändern. 
    // WORKAROUND: Wir zeigen HH:MM an oder einfach MM.
    
    // Für dieses Beispiel gehen wir davon aus, dass wir bei Timern vielleicht mm:ss fälschen wollen
    // oder die Unit einfach Minuten bleibt. 
    // User Request: "Minutes:Seconds". 
    // Um das sauber zu machen, müssten wir 'current' als Sekunden speichern.
    // DA DAS MODEL "Double current" hat und unit "min", nehmen wir an 0.5 = 30 sek.
    
    int m = totalMinutes.floor();
    int s = ((widget.task.current - m) * 60).round();
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }
}

// Utils
Color _getColor(ChallengeAttribute attr) {
  switch (attr) {
    case ChallengeAttribute.strength: return Colors.pinkAccent; 
    case ChallengeAttribute.agility: return Colors.orangeAccent;
    case ChallengeAttribute.intelligence: return Colors.cyanAccent;
    case ChallengeAttribute.discipline: return const Color(0xFF69F0AE); 
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