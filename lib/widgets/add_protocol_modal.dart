import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ascend/theme.dart';
import 'package:ascend/models/template.dart';
import 'package:ascend/models/enums.dart';
import 'package:ascend/providers/game_state_provider.dart';

class AddProtocolModal extends ConsumerStatefulWidget {
  const AddProtocolModal({super.key});

  @override
  ConsumerState<AddProtocolModal> createState() => _AddProtocolModalState();
}

class _AddProtocolModalState extends ConsumerState<AddProtocolModal> {
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _targetCtrl = TextEditingController();
  final TextEditingController _unitCtrl = TextEditingController(text: "reps");
  
  ChallengeType _selectedType = ChallengeType.reps;
  ChallengeAttribute _selectedAttr = ChallengeAttribute.strength;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 24, 
        left: 24, 
        right: 24, 
        bottom: MediaQuery.of(context).viewInsets.bottom + 24
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0F1522),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("NEW PROTOCOL", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          const SizedBox(height: 24),
          
          // NAME INPUT
          _buildLabel("IDENTIFIER"),
          TextField(
            controller: _titleCtrl,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            decoration: _inputDeco("e.g. Morning Run"),
          ),
          const SizedBox(height: 16),

          // ATTRIBUTE SELECTOR (Pills)
          _buildLabel("ATTRIBUTE"),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ChallengeAttribute.values.map((attr) {
                final isSelected = _selectedAttr == attr;
                final color = _getAttrColor(attr);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(attr.name.toUpperCase()),
                    selected: isSelected,
                    onSelected: (val) => setState(() => _selectedAttr = attr),
                    selectedColor: color.withValues(alpha: 0.2),
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    labelStyle: TextStyle(
                      color: isSelected ? color : AscendTheme.textDim,
                      fontWeight: FontWeight.bold,
                      fontSize: 10
                    ),
                    side: BorderSide(color: isSelected ? color : Colors.transparent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // TYPE SELECTOR
          _buildLabel("TRACKING METHOD"),
          Row(
            children: ChallengeType.values.map((type) {
              final isSelected = _selectedType == type;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedType = type;
                      if (type == ChallengeType.time) _unitCtrl.text = "min";
                      if (type == ChallengeType.hydration) _unitCtrl.text = "ml";
                      if (type == ChallengeType.reps) _unitCtrl.text = "reps";
                      if (type == ChallengeType.boolean) _unitCtrl.text = "custom";
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(_getTypeIcon(type), size: 16, color: isSelected ? Colors.black : Colors.white38),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // TARGET & UNIT
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("TARGET VALUE"),
                    TextField(
                      controller: _targetCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      decoration: _inputDeco("00"),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("UNIT"),
                    TextField(
                      controller: _unitCtrl,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      decoration: _inputDeco("unit"),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // ACTION BUTTON
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AscendTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("INITIALIZE PROTOCOL", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ),
          ),
        ],
      ),
    );
  }

  void _save() {
    final val = double.tryParse(_targetCtrl.text);
    if (_titleCtrl.text.isNotEmpty && val != null) {
      final newTemplate = ChallengeTemplate(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleCtrl.text,
        description: "Custom Protocol",
        defaultTarget: val,
        unit: _unitCtrl.text,
        type: _selectedType,
        attribute: _selectedAttr
      );
      ref.read(gameProvider.notifier).addNewTemplate(newTemplate);
      Navigator.pop(context);
    }
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(color: AscendTheme.textDim, fontSize: 10, letterSpacing: 1.0, fontWeight: FontWeight.bold)),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.1)),
      filled: true,
      fillColor: Colors.black26,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Color _getAttrColor(ChallengeAttribute attr) {
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