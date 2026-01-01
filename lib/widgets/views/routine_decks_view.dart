import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Haptic
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ascend/theme.dart';
import 'package:ascend/providers/game_state_provider.dart';
import 'package:ascend/widgets/stack_builder_modal.dart';
import 'package:ascend/models/routine.dart';
import 'package:ascend/models/enums.dart'; // Needed for icons check

class RoutineDecksView extends ConsumerWidget {
  const RoutineDecksView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routines = ref.watch(gameProvider).routines;

    if (routines.isEmpty) return _buildEmptyState(context);

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: routines.length,
            itemBuilder: (context, index) {
              return _buildDeckCard(context, ref, routines[index]);
            },
          ),
        ),
        
        // Quick Add Button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AscendTheme.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _openStackBuilder(context, null),
              icon: const Icon(Icons.add),
              label: const Text("BUILD NEW ROUTINE", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeckCard(BuildContext context, WidgetRef ref, RoutineStack routine) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF151A25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          // PRIMARY ACTION: EDIT / VIEW (Matches Blueprint logic)
          onTap: () {
             HapticFeedback.selectionClick();
             _openStackBuilder(context, routine);
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // DECK ICON VISUAL
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF202530),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Center(
                    child: Icon(IconData(routine.iconCodePoint, fontFamily: 'MaterialIcons'), color: AscendTheme.primary, size: 30),
                  ),
                ),
                const SizedBox(width: 20),
                
                // DECK INFO
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(routine.title.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5)),
                      const SizedBox(height: 6),
                      Text("${routine.templates.length} OPERATIONS", style: const TextStyle(color: AscendTheme.textDim, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      // PREVIEW MINI ICONS
                      Row(
                        children: routine.templates.take(4).map((t) => Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: Icon(_getIcon(t.type), size: 12, color: Colors.white38),
                        )).toList(),
                      )
                    ],
                  ),
                ),

                // SECONDARY ACTION: DEPLOY (Matches Blueprint + Button)
                GestureDetector(
                  onTap: () {
                     HapticFeedback.heavyImpact();
                     ref.read(gameProvider.notifier).addRoutine(routine);
                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("ROUTINE '${routine.title.toUpperCase()}' ACTIVATED"), backgroundColor: AscendTheme.accent, duration: const Duration(milliseconds: 800)));
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AscendTheme.primary.withValues(alpha: 0.1), 
                      shape: BoxShape.circle,
                      border: Border.all(color: AscendTheme.primary.withValues(alpha: 0.5)),
                    ),
                    child: const Icon(Icons.play_arrow, color: AscendTheme.primary, size: 24),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.layers_clear, size: 64, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 20),
          const Text("NO ROUTINES DEFINED", style: TextStyle(color: Colors.white38, letterSpacing: 1.5)),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF202530),
              foregroundColor: AscendTheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () => _openStackBuilder(context, null),
            icon: const Icon(Icons.add),
            label: const Text("CREATE FIRST DECK"),
          )
        ],
      ),
    );
  }

  void _openStackBuilder(BuildContext context, RoutineStack? routine) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StackBuilderModal(existingRoutine: routine),
    );
  }
  
  // Utils
  IconData _getIcon(dynamic type) {
    switch (type) {
      case ChallengeType.reps: return Icons.fitness_center;
      case ChallengeType.time: return Icons.timer;
      case ChallengeType.hydration: return Icons.water_drop;
      case ChallengeType.boolean: return Icons.check_circle_outline;
      default: return Icons.circle;
    }
  }
}