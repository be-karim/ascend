import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ascend/theme.dart';
import 'package:ascend/models/template.dart';
import 'package:ascend/models/routine.dart';
import 'package:ascend/models/enums.dart';
import 'package:ascend/providers/game_state_provider.dart';
import 'package:ascend/screens/stack_builder_screen.dart';
import 'package:ascend/widgets/add_protocol_modal.dart'; // Importieren!

class MissionControlScreen extends ConsumerStatefulWidget {
  const MissionControlScreen({super.key});

  @override
  ConsumerState<MissionControlScreen> createState() => _MissionControlScreenState();
}

class _MissionControlScreenState extends ConsumerState<MissionControlScreen> {

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final routines = gameState.routines;
    final library = gameState.library;

    return Scaffold(
      appBar: AppBar(
        title: const Text("MISSION CONTROL", style: TextStyle(letterSpacing: 2.0, fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        backgroundColor: AscendTheme.background,
        elevation: 0,
        automaticallyImplyLeading: false, 
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- ROUTINES SECTION ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle("ROUTINE PACKAGES"),
                IconButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const StackBuilderScreen()));
                  },
                  icon: const Icon(Icons.add_circle, color: AscendTheme.secondary),
                  tooltip: "Build Routine",
                )
              ],
            ),
            const SizedBox(height: 12),
            
            if (routines.isEmpty)
              _buildEmptyRoutinesState()
            else
              SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: routines.length,
                  itemBuilder: (ctx, i) => _buildRoutineCard(routines[i]),
                ),
              ),
            
            const SizedBox(height: 40),
            
            // --- LIBRARY SECTION ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle("PROTOCOL LIBRARY"),
                // Nur zeigen wenn Library NICHT leer ist (sonst haben wir den großen Button unten)
                if (library.isNotEmpty)
                  IconButton(
                    onPressed: () => showModalBottomSheet(
                        context: context, 
                        isScrollControlled: true, 
                        backgroundColor: Colors.transparent, 
                        builder: (c) => const AddProtocolModal()
                    ),
                    icon: const Icon(Icons.add, color: AscendTheme.textDim),
                    tooltip: "Add Protocol",
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (library.isEmpty)
              _buildEmptyLibraryState(context)
            else
              ...library.map((template) => _buildTemplateTile(template)),
            
            const SizedBox(height: 100), // Platz für Navigation Bar
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(color: AscendTheme.textDim, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5),
    );
  }

  // --- EMPTY STATES ---

  Widget _buildEmptyRoutinesState() {
    return DottedBorder(child: Container(
      height: 100,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text("NO ROUTINES COMPILED", style: TextStyle(color: AscendTheme.textDim, fontSize: 10, letterSpacing: 1.0)),
    ));
  }

  Widget _buildEmptyLibraryState(BuildContext context) {
    return DottedBorder(
      child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AscendTheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.library_books_outlined, size: 40, color: AscendTheme.textDim),
          const SizedBox(height: 16),
          const Text("LIBRARY EMPTY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          const SizedBox(height: 8),
          const Text("Initialize new protocols to build routines.", textAlign: TextAlign.center, style: TextStyle(color: AscendTheme.textDim, fontSize: 12)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => showModalBottomSheet(
                context: context, 
                isScrollControlled: true, 
                backgroundColor: Colors.transparent, 
                builder: (c) => const AddProtocolModal()
            ),
            icon: const Icon(Icons.add),
            label: const Text("CREATE PROTOCOL"),
            style: ElevatedButton.styleFrom(backgroundColor: AscendTheme.secondary.withValues(alpha: 0.2), foregroundColor: AscendTheme.secondary),
          )
        ],
      ),
    ));
  }

  // --- CARDS & TILES ---

  Widget _buildRoutineCard(RoutineStack stack) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () {
          ref.read(gameProvider.notifier).addRoutine(stack);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("DEPLOYED: ${stack.title}"), 
              backgroundColor: AscendTheme.secondary,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 1),
            )
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AscendTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AscendTheme.secondary.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(stack.icon, color: AscendTheme.secondary, size: 32),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stack.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2),
                  const SizedBox(height: 4),
                  Text("${stack.templates.length} Modules", style: const TextStyle(color: AscendTheme.textDim, fontSize: 10)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateTile(ChallengeTemplate template) {
    Color color = _getAttributeColor(template.attribute);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AscendTheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        onTap: () {
          ref.read(gameProvider.notifier).addChallenge(template);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("ADDED: ${template.title}"), 
              backgroundColor: AscendTheme.primary,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(milliseconds: 800),
            )
          );
        },
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(template.icon ?? _getTypeIcon(template.type), color: color, size: 20),
        ),
        title: Text(template.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text("${template.defaultTarget.toInt()} ${template.unit} • ${template.attribute.name.toUpperCase()}", style: const TextStyle(color: AscendTheme.textDim, fontSize: 10)),
        trailing: IconButton(
          icon: const Icon(Icons.edit, size: 16, color: AscendTheme.textDim),
          onPressed: () => _showEditTemplateDialog(template),
        ),
      ),
    );
  }

  // --- EDIT DIALOG (Legacy, could also be modernized later) ---
  void _showEditTemplateDialog(ChallengeTemplate template) {
    final targetCtrl = TextEditingController(text: template.defaultTarget.toInt().toString());
    final unitCtrl = TextEditingController(text: template.unit);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AscendTheme.surface,
        title: Text("EDIT: ${template.title}", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: targetCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Default Target", labelStyle: TextStyle(color: AscendTheme.textDim)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: unitCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Unit", labelStyle: TextStyle(color: AscendTheme.textDim)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(color: AscendTheme.textDim))),
          TextButton(
            onPressed: () {
              final val = double.tryParse(targetCtrl.text);
              if (val != null) {
                final updated = template.copyWith(defaultTarget: val, unit: unitCtrl.text);
                ref.read(gameProvider.notifier).updateTemplate(updated);
              }
              Navigator.pop(ctx);
            }, 
            child: const Text("SAVE", style: TextStyle(color: AscendTheme.secondary, fontWeight: FontWeight.bold))
          ),
        ],
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

  IconData _getTypeIcon(ChallengeType type) {
    switch (type) {
      case ChallengeType.reps: return Icons.fitness_center;
      case ChallengeType.time: return Icons.timer;
      case ChallengeType.hydration: return Icons.water_drop;
      case ChallengeType.boolean: return Icons.check_box;
    }
  }
}