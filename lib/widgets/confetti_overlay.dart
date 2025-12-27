import 'dart:math';
import 'package:flutter/material.dart';

class ConfettiOverlay extends StatefulWidget {
  final Widget child;
  final ConfettiController controller;

  const ConfettiOverlay({super.key, required this.child, required this.controller});

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class ConfettiController extends ChangeNotifier {
  void play() {
    notifyListeners();
  }
}

class _ConfettiOverlayState extends State<ConfettiOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final List<_Particle> _particles = [];
  final Random _rnd = Random();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _animController.addListener(_updateTypes);
    widget.controller.addListener(_onPlay);
  }

  @override
  void dispose() {
    _animController.dispose();
    widget.controller.removeListener(_onPlay);
    super.dispose();
  }

  void _onPlay() {
    _particles.clear();
    // Spawn particles
    for (int i = 0; i < 50; i++) {
      _particles.add(_Particle(
        x: 0.5, 
        y: 0.5,
        dx: (_rnd.nextDouble() - 0.5) * 2.0,
        dy: (_rnd.nextDouble() - 0.5) * 2.0,
        color: HSLColor.fromAHSL(1.0, _rnd.nextDouble() * 360, 0.7, 0.5).toColor(),
        size: _rnd.nextDouble() * 8 + 4,
      ));
    }
    _animController.forward(from: 0.0);
  }

  void _updateTypes() {
    for (var p in _particles) {
      p.x += p.dx * 0.02;
      p.y += p.dy * 0.02;
      p.dy += 0.05; // Gravity
      p.opacity -= 0.01;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_animController.isAnimating)
          IgnorePointer(
            child: CustomPaint(
              size: Size.infinite,
              painter: _ConfettiPainter(_particles),
            ),
          ),
      ],
    );
  }
}

class _Particle {
  double x; // 0..1 normalized to screen? No, simpler to use relative to center or pixel
  // Let's use normalized 0.5 = center
  double y;
  double dx; // velocity
  double dy;
  Color color;
  double size;
  double opacity = 1.0;

  _Particle({required this.x, required this.y, required this.dx, required this.dy, required this.color, required this.size});
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;

  _ConfettiPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      if (p.opacity <= 0) continue;
      final paint = Paint()..color = p.color.withValues(alpha: p.opacity.clamp(0.0, 1.0));
      
      // Convert normalized (0.5, 0.5 is center) to pixels? 
      // Actually let's assume emitter is at center for now or specific point.
      // But adding normalized logic:
      // Let's just say x=0.5 is center.
      final dx = p.x * size.width;
      final dy = p.y * size.height;

      canvas.drawCircle(Offset(dx, dy), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
