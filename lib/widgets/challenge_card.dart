import 'dart:async';
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
  final bool mercyTokenAvailable;

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
  double _sliderValue = 0.0;
  bool _isSliding = false;
  
  // Timer State
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _sliderValue = widget.task.current;
    _checkTimerState();
  }

  @override
  void didUpdateWidget(ActiveChallengeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Timer Check
    if (oldWidget.task.isRunning != widget.task.isRunning) {
      _checkTimerState();
    }

    // Sync DB -> Slider (wenn nicht gerade geschoben wird)
    if (!_isSliding && oldWidget.task.current != widget.task.current) {
      if (!widget.task.isRunning) {
        setState(() => _sliderValue = widget.task.current);
      } else {
        // Soft Sync während Timer läuft
        if ((_sliderValue - widget.task.current).abs() > 0.1) {
           _sliderValue = widget.task.current;
        }
      }
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _checkTimerState() {
    _ticker?.cancel();
    if (widget.task.isRunning) {
      // Ticker startet: Jede Sekunde UI updaten & speichern
      _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() {
          // Einheit ist Minuten (1/60) oder Standard (1.0)
          double increment = widget.task.unit.toLowerCase().contains('min') ? (1 / 60) : 1.0;
          _sliderValue += increment;
          
          // Auto-Save in DB
          widget.onUpdate(increment);
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor(widget.task.attribute);
    final isDone = widget.task.isCompleted;
    
    // Welchen Wert zeigen wir an?
    final double displayValue = _isSliding ? _sliderValue : (_ticker != null ? _sliderValue : widget.task.current);
    final double progress = (displayValue / widget.task.target).clamp(0.0, 1.0);
    
    final double cardHeight = widget.isPriority ? 360 : 130; 

    return GestureDetector(
      onLongPress: () {
        HapticFeedback.heavyImpact();
        widget.onTogglePriority(widget.task.id);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
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
                child: FractionallySizedBox(
                  heightFactor: progress,
                  widthFactor: 1.0,
                  child: Container(color: isDone ? AscendTheme.accent.withValues(alpha: 0.15) : color.withValues(alpha: 0.15)),
                ),
              ),

              // CONTENT
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: widget.isPriority 
                  ? _PriorityLayout(
                      task: widget.task, 
                      color: color, 
                      isDone: isDone, 
                      displayValue: displayValue,
                      sliderValue: _sliderValue,
                      onSliderChange: _handleSliderChange,
                      onSliderEnd: _handleSliderEnd,
                      onToggleTimer: _handleTimerToggle,
                      onMarkDone: () => widget.onUpdate(1),
                      onCalibrate: () => _showSmartCalibrationDialog(context),
                    )
                  : _CompactLayout(
                      task: widget.task,
                      color: color,
                      isDone: isDone,
                      displayValue: displayValue,
                      sliderValue: _sliderValue,
                      onSliderChange: _handleSliderChange,
                      onSliderEnd: _handleSliderEnd,
                      onToggleTimer: _handleTimerToggle,
                      onMarkDone: () => widget.onUpdate(1),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- LOGIC ---

  void _handleTimerToggle() {
    HapticFeedback.mediumImpact();
    widget.onTimerToggle();
  }

  void _handleSliderChange(double val) {
    setState(() {
      _isSliding = true;
      _sliderValue = val;
    });
  }

  void _handleSliderEnd(double val) {
    setState(() => _isSliding = false);
    double delta = val - widget.task.current;
    
    if (delta.abs() > 0.001) { 
       widget.onUpdate(delta);
       
       // Visual Feedback
       Offset center = (context.findRenderObject() as RenderBox).localToGlobal(Offset.zero) + const Offset(150, 100); 
       String text = _formatFeedback(delta, widget.task.type);
       FeedbackAnimation.show(context, center, text, _getColor(widget.task.attribute));
    }
  }

  void _showSmartCalibrationDialog(BuildContext context) {
    final controller = TextEditingController(text: widget.task.target.toInt().toString());
    final bool hasToken = widget.mercyTokenAvailable;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151A25),
        title: const Text("TACTICAL CALIBRATION", style: TextStyle(color: Colors.white, fontSize: 14)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(hasToken ? "Mercy active. No XP cost." : "Mercy depleted. Cost: -150 XP.", style: TextStyle(color: hasToken ? AscendTheme.textDim : Colors.redAccent)),
            const SizedBox(height: 10),
            TextField(controller: controller, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center, decoration: const InputDecoration(filled: true, fillColor: Colors.black)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(color: Colors.white38))),
          TextButton(onPressed: () {
             final val = double.tryParse(controller.text);
             if (val != null) { widget.onCalibrate(val, !hasToken); Navigator.pop(ctx); }
          }, child: const Text("CONFIRM", style: TextStyle(color: AscendTheme.accent))),
        ],
      ),
    );
  }

  String _formatFeedback(double delta, ChallengeType type) {
    String sign = delta > 0 ? "+" : "";
    if (type == ChallengeType.time) {
      int sec = (delta * 60).toInt();
      return "$sign${sec}s";
    }
    return "$sign${delta.toInt()}";
  }
}

// --- LAYOUTS ---

class _PriorityLayout extends StatelessWidget {
  final Challenge task;
  final Color color;
  final bool isDone;
  final double displayValue;
  final double sliderValue;
  final Function(double) onSliderChange;
  final Function(double) onSliderEnd;
  final VoidCallback onToggleTimer;
  final VoidCallback onMarkDone;
  final VoidCallback onCalibrate;

  const _PriorityLayout({
    required this.task, required this.color, required this.isDone, required this.displayValue,
    required this.sliderValue, required this.onSliderChange, required this.onSliderEnd,
    required this.onToggleTimer, required this.onMarkDone, required this.onCalibrate
  });

  @override
  Widget build(BuildContext context) {
    final bool isTimer = task.type == ChallengeType.time;
    final bool isNumeric = task.type != ChallengeType.boolean;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _Badge(text: task.attribute.name.toUpperCase(), color: color),
            GestureDetector(onTap: onCalibrate, child: Icon(Icons.settings, color: Colors.white.withValues(alpha: 0.2), size: 18)),
          ],
        ),
        Column(
          children: [
            Icon(isDone ? Icons.check_circle : _getIcon(task.type), size: 40, color: isDone ? AscendTheme.accent : color),
            const SizedBox(height: 12),
            Text(task.name.toUpperCase(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            
            // PRIORITY VALUE DISPLAY
            _ValueDisplay(task: task, value: displayValue, isPriority: true),
          ],
        ),

        // CONTROLS
        if (isTimer)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: onToggleTimer,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: task.isRunning ? Colors.white : Colors.white10),
                  child: Icon(task.isRunning ? Icons.pause : Icons.play_arrow, size: 32, color: task.isRunning ? Colors.black : Colors.white),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(child: _SliderControl(color: color, value: sliderValue, max: task.target, onChange: onSliderChange, onEnd: onSliderEnd)),
            ],
          )
        else if (isNumeric)
           _SliderControl(color: color, value: sliderValue, max: task.target, onChange: onSliderChange, onEnd: onSliderEnd)
        else
           _BooleanControl(color: color, isDone: isDone, onAction: onMarkDone),
      ],
    );
  }
}

class _CompactLayout extends StatelessWidget {
  final Challenge task;
  final Color color;
  final bool isDone;
  final double displayValue;
  final double sliderValue;
  final Function(double) onSliderChange;
  final Function(double) onSliderEnd;
  final VoidCallback onToggleTimer;
  final VoidCallback onMarkDone;

  const _CompactLayout({
    required this.task, required this.color, required this.isDone, required this.displayValue,
    required this.sliderValue, required this.onSliderChange, required this.onSliderEnd,
    required this.onToggleTimer, required this.onMarkDone
  });

  @override
  Widget build(BuildContext context) {
    final bool isTimer = task.type == ChallengeType.time;
    final bool isNumeric = task.type != ChallengeType.boolean;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Stack(alignment: Alignment.center, children: [
              SizedBox(width: 44, height: 44, child: CircularProgressIndicator(value: (displayValue / task.target).clamp(0.0, 1.0), color: color, backgroundColor: Colors.white10, strokeWidth: 3)),
              Icon(_getIcon(task.type), color: isDone ? AscendTheme.accent : color, size: 20),
            ]),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(task.name, style: TextStyle(fontWeight: FontWeight.bold, color: isDone ? AscendTheme.textDim : Colors.white, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
              
              // COMPACT VALUE DISPLAY (Timer visible here!)
              _ValueDisplay(task: task, value: displayValue, isPriority: false),
              
            ])),
            if (isTimer)
              GestureDetector(onTap: onToggleTimer, child: Container(padding: const EdgeInsets.all(8), margin: const EdgeInsets.only(left: 8), decoration: BoxDecoration(shape: BoxShape.circle, color: task.isRunning ? Colors.white : Colors.white10), child: Icon(task.isRunning ? Icons.pause : Icons.play_arrow, color: task.isRunning ? Colors.black : Colors.white, size: 20))),
          ],
        ),
        const SizedBox(height: 12),
        if (isNumeric)
           SizedBox(height: 30, child: _SliderControl(color: color, value: sliderValue, max: task.target, onChange: onSliderChange, onEnd: onSliderEnd, compact: true)),
        if (!isNumeric)
            _BooleanControl(color: color, isDone: isDone, onAction: onMarkDone, compact: true),
      ],
    );
  }
}

// --- COMPONENTS ---

class _ValueDisplay extends StatelessWidget {
  final Challenge task;
  final double value;
  final bool isPriority;

  const _ValueDisplay({required this.task, required this.value, required this.isPriority});

  @override
  Widget build(BuildContext context) {
    // FORMATTING: Always MM:SS for timers
    String valStr = task.type == ChallengeType.time ? _formatTime(value) : "${value.toInt()}";
    String targetStr = task.type == ChallengeType.time ? _formatTime(task.target) : "${task.target.toInt()}";
    
    // Priority Layout (Big)
    if (isPriority) {
      return Column(children: [
        Text(valStr, style: const TextStyle(fontFamily: 'Courier', fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
        Text("/ $targetStr ${task.unit}", style: const TextStyle(color: AscendTheme.textDim, fontSize: 12, fontWeight: FontWeight.bold)),
      ]);
    }
    
    // Compact Layout (Small but visible)
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontFamily: 'Courier', fontSize: 12, color: AscendTheme.textDim), // Monospace für Timer
        children: [
          TextSpan(text: valStr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          TextSpan(text: " / $targetStr ${task.unit}"),
        ]
      ),
    );
  }

  // ROBUSTE ZEIT-FORMATIERUNG (HH:MM:SS oder MM:SS)
  String _formatTime(double valueInMinutes) {
    int totalSeconds = (valueInMinutes * 60).round();
    int h = totalSeconds ~/ 3600;
    int m = (totalSeconds % 3600) ~/ 60;
    int s = totalSeconds % 60;
    
    String mStr = m.toString().padLeft(2, '0');
    String sStr = s.toString().padLeft(2, '0');
    
    if (h > 0) return "$h:$mStr:$sStr";
    return "$mStr:$sStr";
  }
}

class _SliderControl extends StatelessWidget {
  final Color color;
  final double value;
  final double max;
  final Function(double) onChange;
  final Function(double) onEnd;
  final bool compact;

  const _SliderControl({required this.color, required this.value, required this.max, required this.onChange, required this.onEnd, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (!compact) Text("0", style: const TextStyle(color: Colors.white24, fontSize: 10)),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color, inactiveTrackColor: Colors.white10, thumbColor: Colors.white, overlayColor: color.withValues(alpha: 0.2),
              trackHeight: compact ? 4 : 8, thumbShape: RoundSliderThumbShape(enabledThumbRadius: compact ? 8 : 12),
            ),
            child: Slider(value: value.clamp(0.0, max), min: 0.0, max: max, onChanged: onChange, onChangeEnd: onEnd),
          ),
        ),
        if (!compact) Text("${max.toInt()}", style: const TextStyle(color: Colors.white24, fontSize: 10)),
      ],
    );
  }
}

class _BooleanControl extends StatelessWidget {
  final Color color;
  final bool isDone;
  final VoidCallback onAction;
  final bool compact;

  const _BooleanControl({required this.color, required this.isDone, required this.onAction, this.compact = false});

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Align(alignment: Alignment.centerRight, child: isDone ? const Icon(Icons.check, color: AscendTheme.accent, size: 20) : GestureDetector(onTap: onAction, child: Text("MARK DONE", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10))));
    }
    return isDone 
      ? Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: AscendTheme.accent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)), child: const Text("COMPLETED", style: TextStyle(color: AscendTheme.accent, fontWeight: FontWeight.bold)))
      : ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: color.withValues(alpha: 0.2), foregroundColor: color), onPressed: onAction, child: const Text("MARK DONE"));
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(6)), child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)));
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