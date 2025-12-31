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
    if(mounted) setState(() => _entries.add(_FeedbackEntry(id, position, text, color)));
    
    Future.delayed(const Duration(milliseconds: 1000), () {
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
      left: entry.position.dx - 50,
      top: entry.position.dy - 50,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutExpo,
          builder: (context, val, child) {
            return Transform.translate(
              offset: Offset(0, -60 * val),
              child: Opacity(
                opacity: (1.0 - val).clamp(0.0, 1.0),
                child: SizedBox(
                  width: 100,
                  child: Text(
                    entry.text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: entry.color, 
                      fontSize: 16 + (4 * val),
                      fontWeight: FontWeight.w900,
                      shadows: [const Shadow(color: Colors.black, blurRadius: 4)]
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