import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ascend/models/stats.dart';
import 'package:ascend/models/enums.dart';
import 'package:ascend/models/history.dart'; // Import für HistoryEntry
import 'package:ascend/providers/game_state_provider.dart';
import 'package:ascend/theme.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  // Anzahl der Tage für die Heatmap (Standard: 2 Wochen)
  int _historyDays = 14;

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final player = gameState.stats;
    final history = gameState.history; // Echte Historie aus der Datenbank

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "OPERATOR STATISTICS",
                  style: TextStyle(
                    color: AscendTheme.textDim, 
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: AscendTheme.secondary.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text("LVL ${player.globalLevel}", style: const TextStyle(color: AscendTheme.secondary, fontSize: 10, fontWeight: FontWeight.bold)),
                )
              ],
            ),
            
            const SizedBox(height: 30),
            
            // --- RADAR CHART (HEXAGON) ---
            _buildHexagonStat(player),
            
            const SizedBox(height: 30),
            
            // --- SUMMARY GRID (STREAK & TOTAL) ---
            _buildSummaryGrid(player, history),

            const SizedBox(height: 30),
            
            // --- ACTIVITY MATRIX (HEATMAP) ---
            _buildActivityMatrix(history),

            const SizedBox(height: 30),
            
            // --- DETAILED ATTRIBUTE BREAKDOWN ---
            const Text(
              "ATTRIBUTE BREAKDOWN",
              style: TextStyle(
                color: AscendTheme.textDim, 
                letterSpacing: 2.0,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatsBars(player),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildSummaryGrid(PlayerStats player, List<HistoryEntry> history) {
    // Berechne Gesamtanzahl abgeschlossener Missionen aus der Historie
    int totalCompleted = history.fold(0, (sum, entry) => sum + entry.completedCount);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildSummaryCard(Icons.local_fire_department, "${player.streak}", "Day Streak", AscendTheme.primary),
        _buildSummaryCard(Icons.check_circle_outline, "$totalCompleted", "Missions Done", AscendTheme.accent),
      ],
    );
  }

  Widget _buildSummaryCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AscendTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
          Text(label, style: const TextStyle(color: AscendTheme.textDim, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        ],
      ),
    );
  }

  Widget _buildStatsBars(PlayerStats stats) {
    return Column(
      children: [
        _buildStatItem("STRENGTH", stats.strength, AscendTheme.primary),
        const SizedBox(height: 16),
        _buildStatItem("AGILITY", stats.agility, AscendTheme.secondary),
        const SizedBox(height: 16),
        _buildStatItem("INTELLECT", stats.intelligence, Colors.white),
        const SizedBox(height: 16),
        _buildStatItem("DISCIPLINE", stats.discipline, AscendTheme.accent),
      ],
    );
  }

  Widget _buildStatItem(String label, StatAttribute stat, Color color) {
    double progress = stat.maxXp > 0 ? (stat.currentXp / stat.maxXp) : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.hexagon, size: 12, color: color),
                const SizedBox(width: 8),
                Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.0)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text("TIER ${stat.tier}", style: const TextStyle(color: AscendTheme.textDim, fontSize: 8, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
            Text("Lvl ${stat.level}", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 8,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
            FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6)]
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            "${stat.currentXp} / ${stat.maxXp} XP",
            style: const TextStyle(color: AscendTheme.textDim, fontSize: 9, fontWeight: FontWeight.bold),
          ),
        )
      ],
    );
  }

  Widget _buildActivityMatrix(List<HistoryEntry> history) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("ACTIVITY MATRIX", style: TextStyle(color: AscendTheme.textDim, fontSize: 10, letterSpacing: 2.0, fontWeight: FontWeight.bold)),
            DropdownButton<int>(
              value: _historyDays,
              dropdownColor: AscendTheme.surface,
              style: const TextStyle(color: AscendTheme.secondary, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
              underline: Container(),
              icon: const Icon(Icons.arrow_drop_down, color: AscendTheme.secondary, size: 16),
              items: const [
                DropdownMenuItem(value: 14, child: Text("LAST 14 DAYS")),
                DropdownMenuItem(value: 30, child: Text("LAST 30 DAYS")),
              ], 
              onChanged: (val) {
                if(val != null) setState(() => _historyDays = val);
              }
            )
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1.0,
          ),
          itemCount: _historyDays,
          itemBuilder: (context, index) {
            
            final today = DateTime.now();
            final date = today.subtract(Duration(days: (_historyDays - 1) - index));
            
            // --- ECHTE DATEN ---
            // Finde Eintrag für dieses Datum
            final entry = history.firstWhere(
              (h) => h.date.year == date.year && h.date.month == date.month && h.date.day == date.day,
              orElse: () => HistoryEntry(date: date, completedCount: 0)
            );
            
            final dayFormatted = date.day.toString();
            final count = entry.completedCount;
            
            // Farben basierend auf Aktivität
            Color itemColor = AscendTheme.surface;
            Color textColor = AscendTheme.textDim;
            Color borderColor = Colors.transparent;
            
            if (count > 0 && count <= 2) {
              itemColor = AscendTheme.secondary.withValues(alpha: 0.1);
              textColor = AscendTheme.secondary;
            } else if (count > 2 && count <= 5) {
              itemColor = AscendTheme.secondary.withValues(alpha: 0.3);
              textColor = Colors.white;
              borderColor = AscendTheme.secondary.withValues(alpha: 0.5);
            } else if (count > 5) {
              itemColor = AscendTheme.secondary;
              textColor = Colors.black;
              borderColor = AscendTheme.secondary;
            }

            return Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: itemColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: borderColor.withValues(alpha: 0.5), width: 1),
              ),
              child: Text(
                dayFormatted,
                style: TextStyle(
                  color: textColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
  
  Widget _buildHexagonStat(PlayerStats stats) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Hintergrund-Elemente für Tech-Look
          Container(
            width: 220, height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AscendTheme.surface, width: 1),
            ),
          ),
          SizedBox(
            width: 200,
            height: 200,
            child: CustomPaint(
              painter: RadarChartPainter(stats),
            ),
          ),
        ],
      ),
    );
  }
}

// --- PAINTER FÜR DAS HEXAGON ---

class RadarChartPainter extends CustomPainter {
  final PlayerStats stats;
  RadarChartPainter(this.stats);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Gitter-Linien
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Achsen
    final axisPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Daten-Füllung
    final dataPaint = Paint()
      ..color = AscendTheme.primary.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    
    // Daten-Rahmen
    final borderPaint = Paint()
      ..color = AscendTheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // 1. Zeichne Hintergrund-Netz (4 Ringe)
    for (int i = 1; i <= 4; i++) {
      _drawPolygon(canvas, center, radius * (i / 4), gridPaint);
    }

    // 2. Zeichne Achsen
    for (int i = 0; i < 4; i++) {
      final angle = (i * 90 - 90) * pi / 180;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      canvas.drawLine(center, Offset(x, y), axisPaint);
    }
    
    // 3. Zeichne Daten-Polygon
    // Skalierung: Wir normalisieren das Level auf eine Basis von 20 (für die Demo).
    // Später: Dynamische Skalierung basierend auf dem höchsten Level.
    double maxLvl = [
      stats.strength.level, 
      stats.agility.level, 
      stats.intelligence.level, 
      stats.discipline.level
    ].reduce(max).toDouble();
    
    if (maxLvl < 10) maxLvl = 10; // Mindestgröße damit es nicht winzig aussieht

    final values = [
      stats.strength.level / maxLvl,     // Oben (Strength)
      stats.intelligence.level / maxLvl, // Rechts (Int)
      stats.discipline.level / maxLvl,   // Unten (Dis)
      stats.agility.level / maxLvl,      // Links (Agi)
    ];

    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < 4; i++) {
      final angle = (i * 90 - 90) * pi / 180;
      // Min 0.1 damit man immer ein kleines Polygon sieht
      final r = radius * values[i].clamp(0.1, 1.0); 
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      final point = Offset(x, y);
      points.add(point);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Zeichne Füllung & Rahmen
    canvas.drawPath(path, dataPaint);
    canvas.drawPath(path, borderPaint);

    // Zeichne Punkte an den Ecken
    for (var point in points) {
      canvas.drawCircle(point, 3, Paint()..color = Colors.white);
    }
  }

  void _drawPolygon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 4; i++) {
      final angle = (i * 90 - 90) * pi / 180;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}