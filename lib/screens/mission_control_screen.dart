import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ascend/theme.dart';
import 'package:ascend/models/template.dart';
import 'package:ascend/models/routine.dart';
import 'package:ascend/models/enums.dart';
import 'package:ascend/providers/game_state_provider.dart';
import 'package:ascend/screens/stack_builder_screen.dart';

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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Routines Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle("ROUTINE STACKS"),
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
            SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: routines.length,
                itemBuilder: (ctx, i) => _buildRoutineCard(routines[i]),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Library Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle("PROTOCOL LIBRARY"),
                IconButton(
                  onPressed: () => _showAddTemplateDialog(),
                  icon: const Icon(Icons.add, color: AscendTheme.textDim),
                  tooltip: "Add to Library",
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...library.map((template) => _buildTemplateTile(template)),
            
            const SizedBox(height: 40),
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

  Widget _buildRoutineCard(RoutineStack stack) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () {
          ref.read(gameProvider.notifier).addRoutine(stack);
          Navigator.pop(context); 
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Deploying ${stack.title}..."), backgroundColor: AscendTheme.secondary));
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
          Navigator.pop(context);
        },
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_getTypeIcon(template.type), color: color, size: 20),
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

  // --- DIALOGS ---

  void _showAddTemplateDialog() {
    final titleCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    final unitCtrl = TextEditingController(text: "reps");
    ChallengeType selectedType = ChallengeType.reps;
    ChallengeAttribute selectedAttr = ChallengeAttribute.strength;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AscendTheme.surface,
            title: const Text("NEW PROTOCOL", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Title", labelStyle: TextStyle(color: AscendTheme.textDim))),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: targetCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Target", labelStyle: TextStyle(color: AscendTheme.textDim)))),
                      const SizedBox(width: 10),
                      Expanded(child: TextField(controller: unitCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Unit", labelStyle: TextStyle(color: AscendTheme.textDim)))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButton<ChallengeAttribute>(
                    value: selectedAttr,
                    dropdownColor: AscendTheme.surface,
                    isExpanded: true,
                    items: ChallengeAttribute.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name.toUpperCase(), style: const TextStyle(color: Colors.white)))).toList(),
                    onChanged: (val) => setState(() => selectedAttr = val!),
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<ChallengeType>(
                    value: selectedType,
                    dropdownColor: AscendTheme.surface,
                    isExpanded: true,
                    items: ChallengeType.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name.toUpperCase(), style: const TextStyle(color: Colors.white)))).toList(),
                    onChanged: (val) => setState(() => selectedType = val!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(color: AscendTheme.textDim))),
              TextButton(
                onPressed: () {
                  final val = double.tryParse(targetCtrl.text);
                  if (titleCtrl.text.isNotEmpty && val != null) {
                    final newTemplate = ChallengeTemplate(
                      id: DateTime.now().millisecondsSinceEpoch.toString(), // Temp ID
                      title: titleCtrl.text,
                      description: "Custom",
                      defaultTarget: val,
                      unit: unitCtrl.text,
                      type: selectedType,
                      attribute: selectedAttr
                    );
                    ref.read(gameProvider.notifier).addNewTemplate(newTemplate);
                    Navigator.pop(ctx);
                  }
                }, 
                child: const Text("CREATE", style: TextStyle(color: AscendTheme.secondary, fontWeight: FontWeight.bold))
              ),
            ],
          );
        }
      ),
    );
  }

  void _showEditTemplateDialog(ChallengeTemplate template) {
    // Note: Assuming we just update target/unit for MVP
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
              decoration: const InputDecoration(labelText: "Unit (e.g. reps, min)", labelStyle: TextStyle(color: AscendTheme.textDim)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(color: AscendTheme.textDim))),
          TextButton(
            onPressed: () {
              final val = double.tryParse(targetCtrl.text);
              if (val != null) {
                // Since our Template class is immutable, we create a copy with new values
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