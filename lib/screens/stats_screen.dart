import 'package:flutter/material.dart';
import 'package:ascend/models/models.dart';
import 'package:ascend/theme.dart';
import 'dart:math';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _historyDays = 14;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                child: Text("LVL ${mockPlayer.globalLevel}", style: const TextStyle(color: AscendTheme.secondary, fontSize: 10, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 30),
          _buildHexagonStat(mockPlayer),
          const SizedBox(height: 30),
          _buildStatsBars(mockPlayer),
          const SizedBox(height: 30),
          _buildActivityMatrix(),
          const SizedBox(height: 30),
          _buildSummaryGrid(),
        ],
      ),
    );
  }

  Widget _buildStatsBars(PlayerStats stats) {
    return Column(
      children: [
        _buildStatItem("STRENGTH", stats.strength, AscendTheme.primary),
        const SizedBox(height: 12),
        _buildStatItem("AGILITY", stats.agility, AscendTheme.secondary),
        const SizedBox(height: 12),
        _buildStatItem("INTELLECT", stats.intelligence, Colors.white),
        const SizedBox(height: 12),
        _buildStatItem("DISCIPLINE", stats.discipline, AscendTheme.accent),
      ],
    );
  }

  Widget _buildStatItem(String label, StatAttribute stat, Color color) {
    double progress = stat.currentXp / stat.maxXp;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(text: "$label ", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.0)),
                  TextSpan(text: " TIER ${stat.tier}", style: const TextStyle(color: AscendTheme.textDim, fontSize: 8, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            Text("Lvl ${stat.level}", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 6,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AscendTheme.background,
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            widthFactor: progress.clamp(0.0, 1.0),
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            "${stat.currentXp}/${stat.maxXp} XP",
            style: const TextStyle(color: Colors.grey, fontSize: 10),
          ),
        )
      ],
    );
  }

  Widget _buildActivityMatrix() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("ACTIVITY MATRIX", style: TextStyle(color: AscendTheme.textDim, fontSize: 10, letterSpacing: 2.0, fontWeight: FontWeight.bold)),
            DropdownButton<int>(
              value: _historyDays,
              dropdownColor: AscendTheme.surface,
              style: const TextStyle(color: AscendTheme.accent, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
              underline: Container(),
              icon: const Icon(Icons.arrow_drop_down, color: AscendTheme.accent, size: 16),
              items: const [
                DropdownMenuItem(value: 7, child: Text("LAST 7 DAYS")),
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
            // Mock Data: Random intensity
            // Index 0 is oldest day, Index count-1 is today
            // We want to show Day Number
            
            // Calculate date for this cell
            // today is the last cell. so cell date = today - (total - 1 - index)
            final today = DateTime.now();
            final date = today.subtract(Duration(days: (_historyDays - 1) - index));
            final dayFormatted = date.day.toString();
            
            // Mock intensity: 0=none, 1=low, 2=high
            // Let's make it deterministic based on day to avoid flickering
            final intensity = (date.day % 3); 
            
            Color itemColor = Colors.white.withValues(alpha: 0.05);
            Color textColor = AscendTheme.textDim;
            
            if (intensity == 1) {
              itemColor = AscendTheme.accent.withValues(alpha: 0.2);
              textColor = AscendTheme.accent;
            } else if (intensity == 2) {
              itemColor = AscendTheme.accent.withValues(alpha: 0.5);
              textColor = Colors.black;
            }

            return Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: itemColor,
                borderRadius: BorderRadius.circular(6),
                border: intensity > 0 ? Border.all(color: AscendTheme.accent.withValues(alpha: 0.3)) : null,
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

  Widget _buildSummaryGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildSummaryCard(Icons.local_fire_department, "${mockPlayer.streak}", "Day Streak", AscendTheme.primary),
        _buildSummaryCard(Icons.check_circle, "42", "Tasks Done", AscendTheme.accent),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: AscendTheme.textDim, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        ],
      ),
    );
  }
  
  // A simulated Radar chart using CustomPaint
  Widget _buildHexagonStat(PlayerStats stats) {
    return Center(
      child: SizedBox(
        width: 200,
        height: 200,
        child: CustomPaint(
          painter: RadarChartPainter(stats),
        ),
      ),
    );
  }
}

class RadarChartPainter extends CustomPainter {
  final PlayerStats stats;
  RadarChartPainter(this.stats);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..color = AscendTheme.surface // Dim line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw square background webs (4 stats)
    for (int i = 1; i <= 4; i++) {
      _drawPolygon(canvas, center, radius * (i / 4), paint);
    }
    
    // Draw data polygon
    final dataPaint = Paint()
      ..color = AscendTheme.primary.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = AscendTheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    _drawDataPolygon(canvas, center, radius, dataPaint, borderPaint);
  }

  void _drawPolygon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 4; i++) {
      final angle = (i * 90 - 90) * pi / 180;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawDataPolygon(Canvas canvas, Offset center, double maxRadius, Paint fillPaint, Paint borderPaint) {
    final values = [
      stats.strength.level / 20.0, // Top
      stats.intelligence.level / 20.0, // Right
      stats.discipline.level / 20.0, // Bottom
      stats.agility.level / 20.0, // Left
    ];

    final path = Path();
    for (int i = 0; i < 4; i++) {
      final angle = (i * 90 - 90) * pi / 180;
      final radius = maxRadius * values[i].clamp(0.1, 1.0); // Min 0.1 so it doesn't disappear
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
