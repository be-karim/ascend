import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ascend/theme.dart';
import 'package:ascend/models/template.dart';
import 'package:ascend/models/enums.dart';
import 'package:ascend/providers/game_state_provider.dart';
import 'package:ascend/widgets/add_protocol_modal.dart'; // Importieren!

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
    Icons.wb_sunny, Icons.bedtime, Icons.directions_run, Icons.fitness_center,
    Icons.school, Icons.laptop_mac, Icons.self_improvement, Icons.bolt,
  ];

  void _toggleSelection(ChallengeTemplate template) {
    setState(() {
      _selectedTemplates.contains(template) 
          ? _selectedTemplates.remove(template) 
          : _selectedTemplates.add(template);
    });
  }

  void _saveStack() {
    if (_nameController.text.isEmpty || _selectedTemplates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Missing name or protocols."), backgroundColor: Colors.redAccent));
      return;
    }
    ref.read(gameProvider.notifier).createRoutine(_nameController.text, _selectedIcon, _selectedTemplates);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(gameProvider).library;

    return Scaffold(
      appBar: AppBar(
        title: const Text("BUILD ROUTINE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 2.0)),
        centerTitle: true,
        backgroundColor: AscendTheme.background,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saveStack,
            child: const Text("SAVE", style: TextStyle(color: AscendTheme.accent, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // NAME INPUT
            _buildSectionHeader("IDENTITY"),
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
            const SizedBox(height: 24),

            // ICON SELECTOR
            _buildSectionHeader("ICONOGRAPHY"),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _icons.map((icon) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ChoiceChip(
                    label: Icon(icon, size: 20, color: _selectedIcon == icon ? Colors.black : Colors.white),
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
            const SizedBox(height: 32),

            // PROTOCOL SELECTION
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader("SELECT PROTOCOLS"),
                if (library.isNotEmpty)
                  IconButton(
                    onPressed: () => showModalBottomSheet(
                        context: context, 
                        isScrollControlled: true, 
                        backgroundColor: Colors.transparent, 
                        builder: (c) => const AddProtocolModal()
                    ),
                    icon: const Icon(Icons.add_circle, color: AscendTheme.textDim),
                    tooltip: "New Protocol",
                  )
              ],
            ),
            const SizedBox(height: 8),
            
            if (library.isEmpty)
              _buildEmptyState(context)
            else
              ...library.map((template) => _buildProtocolTile(template)),
              
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(color: AscendTheme.textDim, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AscendTheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05), style: BorderStyle.solid),
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
    );
  }

  Widget _buildProtocolTile(ChallengeTemplate template) {
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