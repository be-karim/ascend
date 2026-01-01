import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ascend/theme.dart';
import 'package:ascend/widgets/views/blueprint_library_view.dart';
import 'package:ascend/widgets/views/routine_decks_view.dart';

// Enum für die Sortierung
enum BlueprintSort { nameAZ, attribute, target }

class MissionControlScreen extends StatefulWidget {
  const MissionControlScreen({super.key});

  @override
  State<MissionControlScreen> createState() => _MissionControlScreenState();
}

class _MissionControlScreenState extends State<MissionControlScreen> with SingleTickerProviderStateMixin {
  late TabController _mainTabController;
  
  // State für Sortierung (Standard: Name A-Z)
  BlueprintSort _currentSort = BlueprintSort.nameAZ;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: Column(
          children: [
            // 1. HEADER (Mit Sortier-Logik)
            _buildHeader(),
            
            // 2. SEGMENTED CONTROL
            _buildSegmentedControl(),
            
            // 3. CONTENT
            Expanded(
              child: TabBarView(
                controller: _mainTabController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  const RoutineDecksView(),     
                  // Wir reichen die Sortierung an die Library weiter
                  BlueprintLibraryView(sortOption: _currentSort), 
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "MISSION CONTROL",
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.5),
          ),
          
          // SORTIER BUTTON
          PopupMenuButton<BlueprintSort>(
            icon: Icon(Icons.sort, color: Colors.white.withValues(alpha: 0.5)),
            color: const Color(0xFF202530),
            tooltip: "Sort Database",
            onSelected: (BlueprintSort result) {
              setState(() {
                _currentSort = result;
              });
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("SORTING: ${_getSortName(result)}"), 
                  duration: const Duration(milliseconds: 600),
                  backgroundColor: AscendTheme.primary,
                )
              );
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<BlueprintSort>>[
              _buildPopupItem(BlueprintSort.nameAZ, "Name (A-Z)", Icons.sort_by_alpha),
              _buildPopupItem(BlueprintSort.attribute, "Attribute (Type)", Icons.category),
              _buildPopupItem(BlueprintSort.target, "Target Value (High)", Icons.trending_up),
            ],
          ),
        ],
      ),
    );
  }
  
  PopupMenuItem<BlueprintSort> _buildPopupItem(BlueprintSort value, String text, IconData icon) {
    final isSelected = _currentSort == value;
    return PopupMenuItem<BlueprintSort>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: isSelected ? AscendTheme.primary : Colors.white54),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  String _getSortName(BlueprintSort sort) {
    switch(sort) {
      case BlueprintSort.nameAZ: return "NAME (A-Z)";
      case BlueprintSort.attribute: return "ATTRIBUTE";
      case BlueprintSort.target: return "TARGET VALUE";
    }
  }

  Widget _buildSegmentedControl() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      height: 45,
      decoration: BoxDecoration(
        color: const Color(0xFF151A25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: TabBar(
        controller: _mainTabController,
        indicator: BoxDecoration(
          color: AscendTheme.primary,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: AscendTheme.primary.withValues(alpha: 0.3), blurRadius: 10)],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.black,
        unselectedLabelColor: Colors.white38,
        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.0),
        onTap: (index) => HapticFeedback.mediumImpact(),
        tabs: const [
          Tab(text: "ROUTINE STACKS"),
          Tab(text: "BLUEPRINT DB"),
        ],
      ),
    );
  }
}