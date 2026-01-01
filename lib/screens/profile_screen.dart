import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ascend/theme.dart';
import 'package:ascend/models/enums.dart';
import 'package:ascend/models/stats.dart';
import 'package:ascend/providers/game_state_provider.dart';
import 'package:ascend/widgets/charts/stat_radar_chart.dart'; // Import the new chart

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final stats = gameState.stats;

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              const Text("BARRACKS", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              const Text("OPERATOR ANALYSIS & CONFIG", style: TextStyle(color: AscendTheme.textDim, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              const SizedBox(height: 30),

              // 1. RADAR CHART SECTION
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background Labels
                    const Positioned(top: 0, child: Text("STR", style: TextStyle(color: Colors.pinkAccent, fontSize: 10, fontWeight: FontWeight.bold))),
                    const Positioned(right: 0, child: Text("INT", style: TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold))),
                    const Positioned(bottom: 0, child: Text("DSC", style: TextStyle(color: Color(0xFF69F0AE), fontSize: 10, fontWeight: FontWeight.bold))),
                    const Positioned(left: 0, child: Text("AGI", style: TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold))),
                    
                    // Chart
                    Container(
                      margin: const EdgeInsets.all(20),
                      child: StatRadarChart(stats: stats, size: 220),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // 2. ATTRIBUTE BREAKDOWN
              _buildAttributeRow("STRENGTH", stats.strength, Colors.pinkAccent),
              _buildAttributeRow("AGILITY", stats.agility, Colors.orangeAccent),
              _buildAttributeRow("INTELLIGENCE", stats.intelligence, Colors.cyanAccent),
              _buildAttributeRow("DISCIPLINE", stats.discipline, const Color(0xFF69F0AE)),
              
              const SizedBox(height: 40),
              const Divider(color: Colors.white10),
              const SizedBox(height: 20),

              // 3. SYSTEM CONFIGURATION
              const Text("SYSTEM CONFIGURATION", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              const SizedBox(height: 16),
              
              _buildConfigTile(
                icon: Icons.notifications,
                title: "NOTIFICATIONS",
                subtitle: "Mission reminders & alerts",
                onTap: () {
                   // Todo: Implement Notifications
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("NOTIFICATION SETTINGS [COMING SOON]")));
                },
              ),
              _buildConfigTile(
                icon: Icons.download,
                title: "EXPORT DATA",
                subtitle: "Backup mission logs",
                onTap: () {
                   // Todo: Export Logic
                },
              ),
              _buildConfigTile(
                icon: Icons.delete_forever,
                title: "FACTORY RESET",
                subtitle: "Wipe all progress & data",
                isDestructive: true,
                onTap: () => _showResetDialog(context, ref),
              ),
              
              const SizedBox(height: 40),
              const Center(child: Text("ASCEND OS v1.0.2", style: TextStyle(color: Colors.white12, fontSize: 10, fontFamily: 'Courier'))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttributeRow(String label, StatAttribute attr, Color color) {
    double progress = (attr.currentXp / attr.maxXp).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text("${attr.level}", style: TextStyle(color: color, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    Text("${attr.currentXp.toInt()} / ${attr.maxXp.toInt()} XP", style: const TextStyle(color: AscendTheme.textDim, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white10,
                  color: color,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildConfigTile({required IconData icon, required String title, required String subtitle, required VoidCallback onTap, bool isDestructive = false}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: isDestructive ? Colors.red.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: isDestructive ? Colors.redAccent : Colors.white70, size: 20),
      ),
      title: Text(title, style: TextStyle(color: isDestructive ? Colors.redAccent : Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white24),
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151A25),
        title: const Text("CONFIRM RESET", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: const Text("This will eradicate all mission data, stats, and blueprints. This action cannot be undone.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(color: Colors.white38))),
          TextButton(
            onPressed: () {
              // HIER WÜRDE DER RESET CODE STEHEN
              // ref.read(gameProvider.notifier).resetAllData();
              Navigator.pop(ctx);
            }, 
            child: const Text("WIPE DATA", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }
}