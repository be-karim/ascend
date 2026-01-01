import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ascend/models/template.dart';
import 'package:ascend/models/routine.dart'; // Import Routine
import 'package:ascend/theme.dart';
import 'package:ascend/providers/game_state_provider.dart';

class StackBuilderModal extends ConsumerStatefulWidget {
  final RoutineStack? existingRoutine; // Null = Create, Set = Edit

  const StackBuilderModal({super.key, this.existingRoutine});

  @override
  ConsumerState<StackBuilderModal> createState() => _StackBuilderModalState();
}

class _StackBuilderModalState extends ConsumerState<StackBuilderModal> {
  final TextEditingController _nameCtrl = TextEditingController();
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    if (widget.existingRoutine != null) {
      _nameCtrl.text = widget.existingRoutine!.title;
      _selectedIds.addAll(widget.existingRoutine!.templates.map((t) => t.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(gameProvider).library;
    final isEditing = widget.existingRoutine != null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF151A25),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Text(isEditing ? "MODIFY ROUTINE STACK" : "BUILD ROUTINE STACK", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
          const SizedBox(height: 20),
          
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "ROUTINE NAME (e.g. Morning Glory)",
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              filled: true,
              fillColor: Colors.black,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),
          const Text("SELECT PROTOCOLS", style: TextStyle(color: AscendTheme.textDim, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          
          Expanded(
            child: ListView.builder(
              itemCount: library.length,
              itemBuilder: (context, index) {
                final t = library[index];
                final isSelected = _selectedIds.contains(t.id);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) _selectedIds.remove(t.id);
                      else _selectedIds.add(t.id);
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? AscendTheme.primary.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                      border: Border.all(color: isSelected ? AscendTheme.primary : Colors.transparent),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(isSelected ? Icons.check_circle : Icons.circle_outlined, color: isSelected ? AscendTheme.primary : Colors.white24),
                        const SizedBox(width: 12),
                        Text(t.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AscendTheme.primary, foregroundColor: Colors.black),
              onPressed: _saveStack,
              child: Text(isEditing ? "UPDATE STACK" : "CREATE STACK", style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  void _saveStack() {
    if (_nameCtrl.text.isEmpty || _selectedIds.isEmpty) return;
    
    final allTemplates = ref.read(gameProvider).library;
    final selectedTemplates = allTemplates.where((t) => _selectedIds.contains(t.id)).toList();
    
    if (widget.existingRoutine != null) {
      // UPDATE
      final updated = RoutineStack(
        id: widget.existingRoutine!.id,
        title: _nameCtrl.text,
        iconCodePoint: widget.existingRoutine!.iconCodePoint,
        templates: selectedTemplates,
      );
      ref.read(gameProvider.notifier).updateRoutine(updated);
    } else {
      // CREATE
      ref.read(gameProvider.notifier).createRoutine(
        _nameCtrl.text,
        Icons.layers.codePoint, 
        selectedTemplates
      );
    }
    
    Navigator.pop(context);
  }
}