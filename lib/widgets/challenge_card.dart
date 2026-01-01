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
  // Lokaler State für flüssige Animation ohne Datenbank-Lag
  double _sliderValue = 0.0;
  bool _isSliding = false;

  @override
  void initState() {
    super.initState();
    _sliderValue = widget.task.current;
  }

  @override
  void didUpdateWidget(ActiveChallengeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Nur updaten, wenn der User NICHT gerade schiebt, sonst springt der Slider unter dem Finger weg
    if (!_isSliding) {
      _sliderValue = widget.task.current;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor(widget.task.attribute);
    final isDone = widget.task.isCompleted;
    
    // WICHTIG: Visueller Fortschritt basiert auf Slider (direkt) oder Task (wenn inaktiv)
    final double displayValue = _isSliding ? _sliderValue : widget.task.current;
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
              // 1. LIQUID FILL BACKGROUND (Game Feel)
              // Reagiert jetzt sofort auf den Slider
              Align(
                alignment: Alignment.bottomCenter,
                child: AnimatedContainer(
                  duration: _isSliding ? Duration.zero : const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  height: cardHeight * progress,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDone ? AscendTheme.accent.withValues(alpha: 0.15) : color.withValues(alpha: 0.15),
                  ),
                ),
              ),

              // 2. CONTENT
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: widget.isPriority 
                  ? _buildPriorityContent(context, color, isDone, displayValue) 
                  : _buildCompactContent(context, color, isDone, displayValue),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- LAYOUTS ---

  Widget _buildPriorityContent(BuildContext context, Color color, bool isDone, double displayValue) {
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
            
            // Value Display (Live Update)
            Column(
              children: [
                Text(
                  widget.task.type == ChallengeType.time 
                    ? _formatDuration(displayValue.toInt()) 
                    : "${displayValue.toInt()}", 
                  style: const TextStyle(fontFamily: 'Courier', fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)
                ),
                Text(
                  "/ ${widget.task.target.toInt()} ${widget.task.unit}", 
                  style: const TextStyle(color: AscendTheme.textDim, fontSize: 12, fontWeight: FontWeight.bold)
                ),
              ],
            ),
          ],
        ),

        if (widget.task.type == ChallengeType.boolean || widget.task.type == ChallengeType.hydration)
           _buildBooleanControls(color, isDone)
        else
           _buildSliderControl(color),
      ],
    );
  }

  Widget _buildCompactContent(BuildContext context, Color color, bool isDone, double displayValue) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 44, height: 44,
                  child: CircularProgressIndicator(
                    value: (displayValue / widget.task.target).clamp(0.0, 1.0),
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
                children: [
                  Text(widget.task.name, style: TextStyle(fontWeight: FontWeight.bold, color: isDone ? AscendTheme.textDim : Colors.white, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(
                    widget.task.type == ChallengeType.time
                      ? "${_formatDuration(displayValue.toInt())} / ${_formatDuration(widget.task.target.toInt())}"
                      : "${displayValue.toInt()} / ${widget.task.target.toInt()} ${widget.task.unit}",
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
                 decoration: BoxDecoration(shape: BoxShape.circle, color: widget.task.isRunning ? Colors.white : Colors.white.withValues(alpha: 0.1)),
                 child: Icon(widget.task.isRunning ? Icons.pause : Icons.play_arrow, color: widget.task.isRunning ? Colors.black : Colors.white, size: 20)
               ),
             )
          ],
        ),
        
        const SizedBox(height: 12),
        
        if (widget.task.type != ChallengeType.boolean && widget.task.type != ChallengeType.hydration)
           SizedBox(
             height: 30,
             child: _buildSliderControl(color, compact: true),
           ),
        
        if (widget.task.type == ChallengeType.boolean)
            _buildBooleanControls(color, isDone, compact: true),
      ],
    );
  }

  // --- CONTROLS ---

  Widget _buildSliderControl(Color color, {bool compact = false}) {
    return Row(
      children: [
        if (!compact) Text("0", style: const TextStyle(color: Colors.white24, fontSize: 10)),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: Colors.white10,
              thumbColor: Colors.white,
              overlayColor: color.withValues(alpha: 0.2),
              trackHeight: compact ? 4 : 8,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: compact ? 8 : 12),
            ),
            child: Slider(
              value: _sliderValue.clamp(0.0, widget.task.target),
              min: 0.0,
              max: widget.task.target,
              onChanged: (val) {
                // Update Local UI instantly (Game Feel)
                setState(() {
                  _isSliding = true;
                  _sliderValue = val;
                });
                // Haptik während des Schiebens ist nett, aber vielleicht zu viel. 
                // Lassen wir es beim Loslassen oder nur leichte Haptik bei Steps.
              },
              onChangeEnd: (val) {
                setState(() => _isSliding = false);
                
                // 1. Delta berechnen
                double delta = val - widget.task.current;
                
                // 2. Datenbank Update
                if (delta != 0) {
                   widget.onUpdate(delta); 
                   
                   // 3. VISUAL FEEDBACK (XP FLYOUT)
                   // Position des Sliders finden (ungefähr Daumen)
                   // Wir nehmen einfach die Mitte der Karte für den Effekt, oder genauer:
                   RenderBox box = context.findRenderObject() as RenderBox;
                   Offset position = box.localToGlobal(box.size.center(Offset.zero));
                   
                   String text = delta > 0 ? "+${delta.toInt()}" : "${delta.toInt()}";
                   if (widget.task.type == ChallengeType.time) text += " min";
                   
                   FeedbackAnimation.show(context, position, text, color);
                }
              },
            ),
          ),
        ),
        if (!compact) Text("${widget.task.target.toInt()}", style: const TextStyle(color: Colors.white24, fontSize: 10)),
      ],
    );
  }

  // ... (Restliche Methoden _buildBooleanControls, _buildBadge, _showSmartCalibrationDialog, _getColor, _getIcon bleiben gleich wie im vorherigen Code) ...
  
  // (Nur zur Sicherheit hier nochmal einfügen, falls du copy-paste machst:)
  Widget _buildBooleanControls(Color color, bool isDone, {bool compact = false}) {
    if (compact) {
      return Align(alignment: Alignment.centerRight, child: isDone ? const Icon(Icons.check, color: AscendTheme.accent, size: 20) : GestureDetector(onTap: () => widget.onUpdate(1), child: Text("MARK DONE", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10))));
    }
    if (widget.task.type == ChallengeType.time) {
        return GestureDetector(onTap: widget.onTimerToggle, child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.all(16), decoration: BoxDecoration(shape: BoxShape.circle, color: widget.task.isRunning ? Colors.white : Colors.white10, boxShadow: widget.task.isRunning ? [BoxShadow(color: Colors.white.withValues(alpha: 0.5), blurRadius: 15)] : []), child: Icon(widget.task.isRunning ? Icons.pause : Icons.play_arrow, size: 32, color: widget.task.isRunning ? Colors.black : Colors.white)));
    }
    return isDone ? Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: AscendTheme.accent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)), child: const Text("COMPLETED", style: TextStyle(color: AscendTheme.accent, fontWeight: FontWeight.bold))) : ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: color.withValues(alpha: 0.2), foregroundColor: color), onPressed: () => widget.onUpdate(1), child: const Text("MARK DONE"));
  }
  
  Widget _buildBadge(Color color) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(6)), child: Text(widget.task.attribute.name.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)));
  }

  void _showSmartCalibrationDialog(BuildContext context) {
    final controller = TextEditingController(text: widget.task.target.toInt().toString());
    final bool hasToken = widget.mercyTokenAvailable;
    showDialog(context: context, builder: (ctx) => AlertDialog(backgroundColor: const Color(0xFF151A25), title: Row(children: [Icon(Icons.tune, color: hasToken ? AscendTheme.accent : Colors.redAccent, size: 18), const SizedBox(width: 8), const Text("TACTICAL CALIBRATION", style: TextStyle(color: Colors.white, fontSize: 14))]), content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(hasToken ? "Mercy Protocol active. Parameters can be adjusted freely." : "Mercy Protocol DEPLETED. Calibration requires XP Override.", style: TextStyle(color: hasToken ? AscendTheme.textDim : Colors.redAccent, fontSize: 12)), if (!hasToken) Padding(padding: const EdgeInsets.only(top: 8.0), child: Row(children: [const Text("COST: ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), const Text("-150 XP", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))])), const SizedBox(height: 20), TextField(controller: controller, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center, decoration: const InputDecoration(filled: true, fillColor: Colors.black, border: OutlineInputBorder(borderSide: BorderSide.none)))]), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(color: Colors.white38))), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: hasToken ? AscendTheme.secondary : Colors.redAccent), onPressed: () { final val = double.tryParse(controller.text); if (val != null && val > 0) { widget.onCalibrate(val, !hasToken); Navigator.pop(ctx); } }, child: Text(hasToken ? "CONFIRM" : "PAY XP & CONFIRM", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)))]));
  }

  String _formatDuration(int totalMinutes) {
    int m = totalMinutes % 60;
    int h = (totalMinutes / 60).floor();
    if (h > 0) return "${h}h ${m}m";
    return "${m}m";
  }
}

// Utils (falls noch benötigt)
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