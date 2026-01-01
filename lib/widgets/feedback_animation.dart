import 'package:flutter/material.dart';

class FeedbackAnimation extends StatefulWidget {
  final Widget child;
  const FeedbackAnimation({super.key, required this.child});

  static void show(BuildContext context, Offset position, String text, Color color) {
    final state = context.findAncestorStateOfType<_FeedbackAnimationState>();
    state?.addPopup(position, text, color);
  }

  @override
  State<FeedbackAnimation> createState() => _FeedbackAnimationState();
}

class _FeedbackEntry {
  final String id;
  final Offset position;
  final String text;
  final Color color;
  _FeedbackEntry(this.id, this.position, this.text, this.color);
}

class _FeedbackAnimationState extends State<FeedbackAnimation> {
  final List<_FeedbackEntry> _entries = [];

  void addPopup(Offset position, String text, Color color) {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    if (mounted) setState(() => _entries.add(_FeedbackEntry(id, position, text, color)));
    
    // DAUER AUF 3 SEKUNDEN ERHÖHT
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) setState(() => _entries.removeWhere((e) => e.id == id));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        ..._entries.map((e) => _buildPopup(e)),
      ],
    );
  }

  Widget _buildPopup(_FeedbackEntry entry) {
    return Positioned(
      left: entry.position.dx - 50, // Zentrieren (Textbreite ca 100)
      top: entry.position.dy - 50,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          // LANGSAME ANIMATION (3 Sekunden)
          duration: const Duration(milliseconds: 3000),
          curve: Curves.easeOutQuart, // Sanftes Ausschweben
          builder: (context, val, child) {
            return Transform.translate(
              // Schwebt höher (120px statt 60px)
              offset: Offset(0, -120 * val),
              child: Opacity(
                // Bleibt länger sichtbar, faded erst im letzten Drittel
                opacity: (1.0 - (val - 0.7) * 3.3).clamp(0.0, 1.0),
                child: SizedBox(
                  width: 100,
                  child: Text(
                    entry.text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: entry.color, 
                      fontSize: 16 + (2 * val), // Wächst minimal
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 4),
                        Shadow(color: entry.color.withValues(alpha: 0.4), blurRadius: 12) // Glow
                      ]
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}