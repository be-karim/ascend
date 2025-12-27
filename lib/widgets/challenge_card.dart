import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ascend/models/models.dart';
import 'package:ascend/theme.dart';

class ChallengeCard extends StatelessWidget {
  final Challenge task;
  final Function(Challenge, double) onUpdate;
  final Function(String) onDelete;
  final Function(Challenge) onToggleTimer;
  final Function(Challenge, double) onEditTarget; // New callback

  const ChallengeCard({
    super.key,
    required this.task,
    required this.onUpdate,
    required this.onDelete,
    required this.onToggleTimer,
    required this.onEditTarget,
  });

  @override
  Widget build(BuildContext context) {
    Color activeColor = AscendTheme.primary;
    if (task.type == ChallengeType.hydration) activeColor = AscendTheme.secondary;
    if (task.type == ChallengeType.time) activeColor = AscendTheme.accent;
    if (task.isCompleted) activeColor = AscendTheme.accent;

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) => _handleSwipe(context, direction),
      background: _buildSwipeBackground(Alignment.centerLeft, Icons.add_circle, AscendTheme.accent),
      secondaryBackground: _buildSwipeBackground(Alignment.centerRight, Icons.delete_forever, Colors.redAccent),
      child: GestureDetector(
        // THE NEW EDIT FRICTION: Long Press to edit details
        onLongPress: () => _showEditDialog(context),
        child: Container(
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
                _buildHeader(context, activeColor),
                const SizedBox(height: 12),
                _buildProgressBar(activeColor),
                const SizedBox(height: 16),
                _buildActionRow(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeBackground(Alignment align, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(24),
      ),
      alignment: align,
      child: Icon(icon, color: color),
    );
  }

  Future<bool> _handleSwipe(BuildContext context, DismissDirection direction) async {
    if (direction == DismissDirection.startToEnd) {
      HapticFeedback.mediumImpact();
      double amount = _getQuickAddAmount();
      onUpdate(task, amount);
      return false; // Don't dismiss
    } else {
      bool confirm = await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AscendTheme.surface,
          title: const Text("Abort Protocol?", style: TextStyle(color: Colors.white)),
          content: Text("Delete ${task.name}?", style: const TextStyle(color: AscendTheme.textDim)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCEL")),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("ABORT", style: TextStyle(color: Colors.red))),
          ],
        )
      ) ?? false;
      
      if (confirm) onDelete(task.id);
      return confirm;
    }
  }

  void _showEditDialog(BuildContext context) {
    HapticFeedback.heavyImpact();
    final controller = TextEditingController(text: task.target.toInt().toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AscendTheme.surface,
        title: const Text("Adjust Parameters", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Modify target value for this session.", style: TextStyle(color: AscendTheme.textDim, fontSize: 12)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          TextButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0) {
                onEditTarget(task, val);
              }
              Navigator.pop(ctx);
            }, 
            child: const Text("UPDATE", style: TextStyle(color: AscendTheme.secondary, fontWeight: FontWeight.bold))
          ),
        ],
      )
    );
  }

  double _getQuickAddAmount() {
    if (task.type == ChallengeType.reps) return 5.0;
    if (task.type == ChallengeType.hydration) return 250.0;
    if (task.type == ChallengeType.time) return 5.0; 
    return 1.0;
  }

  Widget _buildHeader(BuildContext context, Color activeColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(task.name, style: TextStyle(color: activeColor, fontWeight: FontWeight.bold, fontSize: 16)),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: activeColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: activeColor.withValues(alpha: 0.5), width: 0.5),
                    ),
                    child: Text(
                      task.attribute.name.substring(0, 3).toUpperCase(),
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: activeColor),
                    ),
                  ),
                ),
                if (task.isRunning)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Container(
                      width: 8, height: 8, 
                      decoration: const BoxDecoration(color: AscendTheme.accent, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _formatDisplayValue(),
              style: const TextStyle(color: AscendTheme.textDim, fontSize: 12, letterSpacing: 1.0, fontWeight: FontWeight.bold),
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
    );
  }

  String _formatDisplayValue() {
     if (task.type == ChallengeType.time) {
       int m = task.current.floor();
       int s = ((task.current - m) * 60).floor();
       return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')} / ${task.target.toInt()} min";
     }
     return "${task.current.toInt()} / ${task.target.toInt()} ${task.unit}";
  }

  Widget _buildProgressBar(Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: LinearProgressIndicator(
        value: task.progress,
        minHeight: 6,
        backgroundColor: AscendTheme.background,
        color: color,
      ),
    );
  }

  Widget _buildActionRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (!task.isCompleted) ..._buildControls(),
        if (task.isCompleted) 
           const Padding(
             padding: EdgeInsets.symmetric(vertical: 4),
             child: Text("DONE", style: TextStyle(color: AscendTheme.accent, fontWeight: FontWeight.bold, letterSpacing: 2)),
           ),
      ],
    );
  }

  List<Widget> _buildControls() {
    if (task.type == ChallengeType.time) {
      int m = task.current.floor();
      int s = ((task.current - m) * 60).floor();
      String timeStr = "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
      return [
         Text(timeStr, style: const TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold, fontSize: 18)),
         const SizedBox(width: 16),
         GestureDetector(
           onTap: () => onToggleTimer(task),
           child: Container(
             width: 40, height: 40,
             decoration: BoxDecoration(
               color: task.isRunning ? AscendTheme.accent : Colors.white.withValues(alpha: 0.1),
               shape: BoxShape.circle,
             ),
             child: Icon(task.isRunning ? Icons.pause : Icons.play_arrow, color: task.isRunning ? Colors.black : Colors.white),
           ),
         )
      ];
    } else if (task.type == ChallengeType.hydration) {
       return [
          _buildQuickAddBtn(250, Icons.water_drop),
          const SizedBox(width: 8),
          _buildQuickAddBtn(500, Icons.water_drop),
       ];
    } else {
      return [
        _buildQuickAddBtn(5, null, label: "+5"),
        const SizedBox(width: 8),
        _buildQuickAddBtn(10, null, label: "+10"),
      ];
    }
  }

  Widget _buildQuickAddBtn(double amount, IconData? icon, {String? label}) {
     return InkWell(
       onTap: () => onUpdate(task, amount),
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
              Text(label ?? amount.toInt().toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
           ],
         ),
       ),
     );
  }
}