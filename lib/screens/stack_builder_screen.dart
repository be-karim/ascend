import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ascend/theme.dart';
import 'package:ascend/models/template.dart';
import 'package:ascend/models/enums.dart';
import 'package:ascend/providers/game_state_provider.dart';

class StackBuilderScreen extends ConsumerStatefulWidget {
  const StackBuilderScreen({super.key});

  @override
  ConsumerState<StackBuilderScreen> createState() => _StackBuilderScreenState();
}

class _StackBuilderScreenState extends ConsumerState<StackBuilderScreen> {
  final TextEditingController _nameController = TextEditingController();
  final List<ChallengeTemplate> _selectedTemplates = [];
  
  IconData _selectedIcon = Icons.layers;

  final List<IconData> _icons = [
    Icons.wb_sunny,
    Icons.bedtime,
    Icons.directions_run,
    Icons.fitness_center,
    Icons.school,
    Icons.laptop_mac,
    Icons.self_improvement,
    Icons.bolt,
  ];

  void _toggleSelection(ChallengeTemplate template) {
    setState(() {
      if (_selectedTemplates.contains(template)) {
        _selectedTemplates.remove(template);
      } else {
        _selectedTemplates.add(template);
      }
    });
  }

  void _saveStack() {
    if (_nameController.text.isEmpty || _selectedTemplates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name and at least 1 task required."), backgroundColor: Colors.redAccent)
      );
      return;
    }

    ref.read(gameProvider.notifier).createRoutine(
      _nameController.text, 
      _selectedIcon, 
      _selectedTemplates
    );
    
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Access library from provider
    final library = ref.watch(gameProvider).library;

    return Scaffold(
      appBar: AppBar(
        title: const Text("BUILD ROUTINE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.5)),
        backgroundColor: AscendTheme.background,
        actions: [
          TextButton(
            onPressed: _saveStack,
            child: const Text("SAVE", style: TextStyle(color: AscendTheme.accent, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name Input
            const Text("ROUTINE IDENTITY", style: TextStyle(color: AscendTheme.textDim, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                filled: true,
                fillColor: AscendTheme.surface,
                hintText: "e.g. Morning Grind",
                hintStyle: TextStyle(color: AscendTheme.textDim.withValues(alpha: 0.5)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),

            // Icon Selector
            const Text("ICONOGRAPHY", style: TextStyle(color: AscendTheme.textDim, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _icons.map((icon) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ChoiceChip(
                    label: Icon(icon, size: 18, color: _selectedIcon == icon ? Colors.black : Colors.white),
                    selected: _selectedIcon == icon,
                    onSelected: (bool selected) {
                      if (selected) setState(() => _selectedIcon = icon);
                    },
                    selectedColor: AscendTheme.secondary,
                    backgroundColor: AscendTheme.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    showCheckmark: false,
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: 30),

            // Template List
            const Text("SELECT MODULES", style: TextStyle(color: AscendTheme.textDim, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...library.map((template) {
              final isSelected = _selectedTemplates.contains(template);
              Color attrColor = _getAttributeColor(template.attribute);
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected ? attrColor.withValues(alpha: 0.1) : AscendTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? attrColor : Colors.transparent,
                    width: 1
                  ),
                ),
                child: ListTile(
                  onTap: () => _toggleSelection(template),
                  leading: Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected ? attrColor : AscendTheme.textDim,
                  ),
                  title: Text(template.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text("${template.defaultTarget.toInt()} ${template.unit}", style: const TextStyle(color: AscendTheme.textDim, fontSize: 12)),
                  trailing: Text(
                    template.attribute.name.substring(0,3).toUpperCase(), 
                    style: TextStyle(color: attrColor, fontWeight: FontWeight.bold, fontSize: 10)
                  ),
                ),
              );
            }),
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
}