import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ascend/models/routine.dart';
import 'package:ascend/theme.dart';

class RoutineDeckCard extends StatelessWidget {
  final RoutineStack routine;
  final VoidCallback onDeploy;

  const RoutineDeckCard({super.key, required this.routine, required this.onDeploy});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact();
        onDeploy();
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF202530),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Stack Icon Effect
            Stack(
              alignment: Alignment.center,
              children: [
                Transform.rotate(angle: -0.1, child: Container(width: 40, height: 50, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)))),
                Transform.rotate(angle: 0.1, child: Container(width: 40, height: 50, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)))),
                Icon(IconData(routine.iconCodePoint, fontFamily: 'MaterialIcons'), size: 32, color: Colors.white),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              routine.title.toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              "${routine.templates.length} CARDS",
              style: const TextStyle(color: AscendTheme.accent, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}