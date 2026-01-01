import 'package:flutter/material.dart';
import 'package:ascend/models/template.dart';
import 'package:ascend/models/enums.dart';
import 'package:ascend/theme.dart';

class ProtocolEditorModal extends StatefulWidget {
  final ChallengeTemplate? existingTemplate; // Null = New, Set = Edit
  final Function(ChallengeTemplate) onSave;

  const ProtocolEditorModal({super.key, this.existingTemplate, required this.onSave});

  @override
  State<ProtocolEditorModal> createState() => _ProtocolEditorModalState();
}

class _ProtocolEditorModalState extends State<ProtocolEditorModal> {
  late TextEditingController _titleCtrl;
  late TextEditingController _targetCtrl;
  late TextEditingController _unitCtrl;
  
  ChallengeType _selectedType = ChallengeType.reps;
  ChallengeAttribute _selectedAttr = ChallengeAttribute.strength;

  @override
  void initState() {
    super.initState();
    final t = widget.existingTemplate;
    _titleCtrl = TextEditingController(text: t?.title ?? "");
    _targetCtrl = TextEditingController(text: t?.defaultTarget.toInt().toString() ?? "10");
    _unitCtrl = TextEditingController(text: t?.unit ?? "reps");
    
    if (t != null) {
      _selectedType = t.type;
      _selectedAttr = t.attribute;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingTemplate != null;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20, left: 20, right: 20
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF151A25),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Center(
              child: Container(
                width: 40, height: 4, 
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2)),
              )
            ),
            Text(
              isEditing ? "MODIFY PROTOCOL" : "NEW PROTOCOL",
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.0),
            ),
            const SizedBox(height: 20),

            // INPUTS
            _buildLabel("PROTOCOL NAME"),
            _buildTextField(_titleCtrl, "Ex: Morning Pushups"),
            
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _buildLabel("TYPE"),
                    _buildTypeSelector(),
                  ]),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _buildLabel("ATTRIBUTE"),
                    _buildAttributeSelector(),
                  ]),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _buildLabel("TARGET VALUE"),
                    _buildTextField(_targetCtrl, "50", isNumber: true),
                ])),
                const SizedBox(width: 16),
                Expanded(flex: 1, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _buildLabel("UNIT"),
                    _buildTextField(_unitCtrl, "reps"), // Hier kann man 'ml', 'min', 'km' eingeben
                ])),
              ],
            ),

            const SizedBox(height: 30),
            
            // SAVE BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AscendTheme.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _handleSave,
                child: Text(isEditing ? "SAVE CHANGES" : "CREATE PROTOCOL", style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSave() {
    if (_titleCtrl.text.isEmpty) return;
    
    final double target = double.tryParse(_targetCtrl.text) ?? 0.0;
    
    // Auto-Correct Unit if empty based on type
    String unit = _unitCtrl.text;
    if (unit.isEmpty) {
      if (_selectedType == ChallengeType.time) unit = "min";
      if (_selectedType == ChallengeType.reps) unit = "reps";
      if (_selectedType == ChallengeType.hydration) unit = "ml";
      if (_selectedType == ChallengeType.boolean) unit = "done";
    }

    final newTemplate = ChallengeTemplate(
      id: widget.existingTemplate?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleCtrl.text,
      description: "", // Optional, we keep it simple
      type: _selectedType,
      unit: unit,
      defaultTarget: target,
      attribute: _selectedAttr,
    );

    widget.onSave(newTemplate);
    Navigator.pop(context);
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: const TextStyle(color: AscendTheme.textDim, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, {bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
        filled: true,
        fillColor: Colors.black,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ChallengeType>(
          value: _selectedType,
          dropdownColor: const Color(0xFF202530),
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: AscendTheme.textDim),
          items: ChallengeType.values.map((t) {
            return DropdownMenuItem(
              value: t,
              child: Text(t.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12)),
            );
          }).toList(),
          onChanged: (val) {
            if(val != null) setState(() {
               _selectedType = val;
               // Auto-Update Unit Hint
               if(val == ChallengeType.time) _unitCtrl.text = "min";
               if(val == ChallengeType.hydration) _unitCtrl.text = "ml";
               if(val == ChallengeType.boolean) _unitCtrl.text = "done";
               if(val == ChallengeType.reps) _unitCtrl.text = "reps";
            });
          },
        ),
      ),
    );
  }

  Widget _buildAttributeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ChallengeAttribute>(
          value: _selectedAttr,
          dropdownColor: const Color(0xFF202530),
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: AscendTheme.textDim),
          items: ChallengeAttribute.values.map((a) {
            return DropdownMenuItem(
              value: a,
              child: Text(a.name.toUpperCase(), style: TextStyle(color: _getAttrColor(a), fontSize: 12, fontWeight: FontWeight.bold)),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedAttr = val!),
        ),
      ),
    );
  }

  Color _getAttrColor(ChallengeAttribute attr) {
    switch (attr) {
      case ChallengeAttribute.strength: return Colors.pinkAccent; 
      case ChallengeAttribute.agility: return Colors.orangeAccent;
      case ChallengeAttribute.intelligence: return Colors.cyanAccent;
      case ChallengeAttribute.discipline: return const Color(0xFF69F0AE); 
    }
  }
}