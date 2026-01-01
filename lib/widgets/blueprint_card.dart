import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ascend/models/template.dart';
import 'package:ascend/models/enums.dart';
import 'package:ascend/theme.dart';

class BlueprintCard extends StatelessWidget {
  final ChallengeTemplate template;
  final VoidCallback onDeploy;
  final VoidCallback onEdit;

  const BlueprintCard({
    super.key,
    required this.template,
    required this.onDeploy,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColor(template.attribute);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onEdit();
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF151A25),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Stack(
          children: [
            // 1. BACKGROUND GRADIENT
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color.withValues(alpha: 0.15), Colors.transparent],
                ),
              ),
            ),

            // 2. MAIN CONTENT (Centered & Spaced)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // Vertikal zentrieren
                crossAxisAlignment: CrossAxisAlignment.center, // Horizontal zentrieren
                children: [
                  const SizedBox(height: 10), // Platz für Deploy Button oben
                  
                  // ICON (Centralized)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black26,
                      border: Border.all(color: color.withValues(alpha: 0.5)),
                    ),
                    child: Icon(_getIcon(template.type), color: color, size: 24),
                  ),
                  
                  // FLEXIBLER PLATZ ZWISCHEN ICON UND TEXT
                  const Spacer(flex: 1),

                  // TITLE (Auto Linebreak & Spacing)
                  Text(
                    template.title.toUpperCase(),
                    textAlign: TextAlign.center,
                    maxLines: 3, // Erlaubt bis zu 3 Zeilen
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12, // Etwas kleiner für mehr Platz
                      letterSpacing: 0.5,
                      height: 1.2, // Besserer Zeilenabstand
                    ),
                  ),
                  
                  const SizedBox(height: 8), // Fester Abstand zum Unit Badge
                  
                  // UNIT BADGE
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "${template.defaultTarget.toInt()} ${template.unit}",
                      style: const TextStyle(color: AscendTheme.textDim, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),

                  // FLEXIBLER PLATZ ZUM ATTRIBUT
                  const Spacer(flex: 2),
                ],
              ),
            ),

            // 3. DEPLOY BUTTON (Top Right - Fixed)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.heavyImpact();
                  onDeploy();
                },
                child: Container(
                  padding: const EdgeInsets.all(8), // Größere Touch Area
                  decoration: BoxDecoration(
                    color: AscendTheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AscendTheme.primary.withValues(alpha: 0.4), blurRadius: 8)],
                  ),
                  child: const Icon(Icons.add, size: 16, color: Colors.black),
                ),
              ),
            ),
            
            // 4. ATTRIBUTE LABEL (Bottom Center - Fixed)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  template.attribute.name.toUpperCase(),
                  style: TextStyle(color: color.withValues(alpha: 0.6), fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
      case ChallengeType.time: return Icons.timer;
      case ChallengeType.hydration: return Icons.water_drop;
      case ChallengeType.boolean: return Icons.check_circle_outline;
    }
  }
}