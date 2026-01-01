import 'dart:math';
import 'package:flutter/material.dart';
import 'package:ascend/models/stats.dart';
import 'package:ascend/theme.dart';

class StatRadarChart extends StatelessWidget {
  final PlayerStats stats;
  final double size;

  const StatRadarChart({super.key, required this.stats, this.size = 200});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RadarPainter(
          stats: stats,
          lineColor: AscendTheme.textDim,
          fillColor: AscendTheme.primary.withValues(alpha: 0.3),
          outlineColor: AscendTheme.primary,
        ),
        child: const Center(
          child: Icon(Icons.person, color: Colors.white24),
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final PlayerStats stats;
  final Color lineColor;
  final Color fillColor;
  final Color outlineColor;

  _RadarPainter({
    required this.stats,
    required this.lineColor,
    required this.fillColor,
    required this.outlineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;

    // 1. Draw Grid (Web)
    final paintGrid = Paint()
      ..color = lineColor.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 1; i <= 4; i++) {
      _drawPolygon(canvas, center, radius * (i / 4), 4, paintGrid);
    }

    // 2. Draw Stats Polygon
    // Normalize levels (Assumption: Level 10 is max for chart visualization, or use dynamic max)
    double maxLvl = [
      stats.strength.level,
      stats.agility.level,
      stats.intelligence.level,
      stats.discipline.level
    ].reduce(max).toDouble();
    
    if (maxLvl < 10) maxLvl = 10; // Min scale

    final values = [
      stats.strength.level / maxLvl,     // Top (Strength)
      stats.intelligence.level / maxLvl, // Right (Intel)
      stats.discipline.level / maxLvl,   // Bottom (Discipline) - swapped order for visual balance if needed
      stats.agility.level / maxLvl,      // Left (Agility)
    ];

    final path = Path();
    for (int i = 0; i < 4; i++) {
      final angle = (i * 90 - 90) * (pi / 180); // Start at top (-90 deg)
      final r = radius * values[i];
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    path.close();

    // Fill
    canvas.drawPath(path, Paint()..color = fillColor..style = PaintingStyle.fill);
    // Outline
    canvas.drawPath(path, Paint()..color = outlineColor..style = PaintingStyle.stroke..strokeWidth = 2);

    // 3. Draw Axis Labels (Optional, simplified here)
  }

  void _drawPolygon(Canvas canvas, Offset center, double radius, int sides, Paint paint) {
    final path = Path();
    for (int i = 0; i < sides; i++) {
      final angle = (i * 360 / sides - 90) * (pi / 180);
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