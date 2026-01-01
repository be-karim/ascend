import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ascend/theme.dart';
import 'package:ascend/models/enums.dart';
import 'package:ascend/models/template.dart';
import 'package:ascend/providers/game_state_provider.dart';
import 'package:ascend/widgets/blueprint_card.dart';
import 'package:ascend/widgets/protocol_editor_modal.dart';
import 'package:ascend/screens/mission_control_screen.dart'; // Import für BlueprintSort Enum

class BlueprintLibraryView extends ConsumerStatefulWidget {
  final BlueprintSort sortOption; // NEU: Parameter empfangen

  const BlueprintLibraryView({super.key, required this.sortOption});

  @override
  ConsumerState<BlueprintLibraryView> createState() => _BlueprintLibraryViewState();
}

class _BlueprintLibraryViewState extends ConsumerState<BlueprintLibraryView> with SingleTickerProviderStateMixin {
  late TabController _catTabController;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _catTabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final library = gameState.library;

    // 1. Filtern (Suche & Kategorie)
    List<ChallengeTemplate> filtered = library.where((t) {
      final matchesSearch = t.title.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;

      if (_catTabController.index == 0) return true; // ALL
      if (_catTabController.index == 1) return t.attribute == ChallengeAttribute.strength || t.attribute == ChallengeAttribute.agility;
      if (_catTabController.index == 2) return t.attribute == ChallengeAttribute.intelligence;
      if (_catTabController.index == 3) return t.attribute == ChallengeAttribute.discipline;
      return true;
    }).toList();

    // 2. Sortieren (Neue Logik)
    filtered.sort((a, b) {
      switch (widget.sortOption) {
        case BlueprintSort.nameAZ:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        
        case BlueprintSort.attribute:
          // Sortiert primär nach Attribut, sekundär nach Name
          int attrComp = a.attribute.index.compareTo(b.attribute.index);
          if (attrComp != 0) return attrComp;
          return a.title.compareTo(b.title);
          
        case BlueprintSort.target:
          // Sortiert primär nach Target-Menge (Absteigend - "Highest first"), sekundär nach Name
          int targetComp = b.defaultTarget.compareTo(a.defaultTarget);
          if (targetComp != 0) return targetComp;
          return a.title.compareTo(b.title);
      }
    });

    return Column(
      children: [
        _buildSearchBar(),
        _buildCategoryTabs(),
        
        Expanded(
          child: filtered.isEmpty 
            ? _buildEmptyState()
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final template = filtered[index];
                  // key hinzufügen hilft Flutter, Elemente bei Neusortierung effizienter zu verschieben
                  return BlueprintCard(
                    key: ValueKey(template.id), 
                    template: template,
                    onDeploy: () {
                      ref.read(gameProvider.notifier).addChallenge(template);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("UNIT '${template.title.toUpperCase()}' DEPLOYED"), backgroundColor: AscendTheme.accent, duration: const Duration(milliseconds: 800)));
                    },
                    onEdit: () => _openEditor(context, template),
                  );
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
                backgroundColor: const Color(0xFF202530),
                foregroundColor: AscendTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AscendTheme.primary.withValues(alpha: 0.3))),
              ),
              onPressed: () => _openEditor(context, null),
              icon: const Icon(Icons.add),
              label: const Text("DESIGN NEW BLUEPRINT", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: TextField(
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          hintText: "SEARCH COLLECTION...",
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 12, letterSpacing: 1.0),
          prefixIcon: const Icon(Icons.search, color: AscendTheme.textDim, size: 18),
          filled: true,
          fillColor: const Color(0xFF0F1522),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          isDense: true,
        ),
        onChanged: (val) => setState(() => _searchQuery = val),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 8),
      child: TabBar(
        controller: _catTabController,
        isScrollable: false,
        labelColor: AscendTheme.primary,
        unselectedLabelColor: Colors.white38,
        indicatorColor: AscendTheme.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
        onTap: (index) => setState(() {}),
        tabs: const [
           Tab(text: "ALL"),
           Tab(text: "BODY"),
           Tab(text: "MIND"),
           Tab(text: "GRIND"),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.grid_view, size: 48, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          const Text("NO BLUEPRINTS FOUND", style: TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  void _openEditor(BuildContext context, ChallengeTemplate? template) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => ProtocolEditorModal(
        existingTemplate: template,
        onSave: (newTemplate) {
          if (template == null) ref.read(gameProvider.notifier).addNewTemplate(newTemplate);
          else ref.read(gameProvider.notifier).updateTemplate(newTemplate);
        },
      ),
    );
  }
}