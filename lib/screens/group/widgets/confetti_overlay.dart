import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A reusable confetti burst overlay.
///
/// Usage:
/// ```dart
/// ConfettiOverlay.show(context);                    // small burst
/// ConfettiOverlay.show(context, isBig: true);       // big celebration burst
/// ```
class ConfettiOverlay {
  static void show(BuildContext context, {bool isBig = false}) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ConfettiAnimation(
        isBig: isBig,
        onComplete: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

class _ConfettiAnimation extends StatefulWidget {
  final bool isBig;
  final VoidCallback onComplete;

  const _ConfettiAnimation({
    required this.isBig,
    required this.onComplete,
  });

  @override
  State<_ConfettiAnimation> createState() => _ConfettiAnimationState();
}

class _ConfettiAnimationState extends State<_ConfettiAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_ConfettiParticle> _particles;
  final _random = math.Random();

  static const _colors = [
    Color(0xFF00D09C), // accent green
    Color(0xFF0D2C54), // primary blue
    Color(0xFFFFD700), // gold
    Color(0xFFFF6B6B), // coral
    Color(0xFF4ECDC4), // teal
    Color(0xFFFF9F43), // orange
    Color(0xFFA29BFE), // lavender
    Color(0xFFFF85A2), // pink
  ];

  @override
  void initState() {
    super.initState();
    final count = widget.isBig ? 80 : 35;
    final duration = widget.isBig
        ? const Duration(milliseconds: 2200)
        : const Duration(milliseconds: 1400);

    _controller = AnimationController(vsync: this, duration: duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onComplete();
        }
      });

    _particles = List.generate(count, (_) => _generateParticle());
    _controller.forward();
  }

  _ConfettiParticle _generateParticle() {
    final angle = _random.nextDouble() * math.pi * 2;
    final speed = widget.isBig
        ? 300 + _random.nextDouble() * 500
        : 200 + _random.nextDouble() * 350;
    final rotationSpeed = (_random.nextDouble() - 0.5) * 10;
    final size = 4.0 + _random.nextDouble() * (widget.isBig ? 8 : 5);
    final color = _colors[_random.nextInt(_colors.length)];
    final shape = _random.nextInt(3); // 0=rect, 1=circle, 2=strip

    return _ConfettiParticle(
      angle: angle,
      speed: speed,
      rotationSpeed: rotationSpeed,
      size: size,
      color: color,
      shape: shape,
      startDelay: _random.nextDouble() * 0.15,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return IgnorePointer(
          child: CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _ConfettiPainter(
              particles: _particles,
              progress: _controller.value,
              screenSize: MediaQuery.of(context).size,
              isBig: widget.isBig,
            ),
          ),
        );
      },
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;
  final Size screenSize;
  final bool isBig;

  _ConfettiPainter({
    required this.particles,
    required this.progress,
    required this.screenSize,
    required this.isBig,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final originY = isBig ? size.height * 0.35 : size.height * 0.4;
    final gravity = isBig ? 600.0 : 450.0;

    for (final p in particles) {
      final t = (progress - p.startDelay).clamp(0.0, 1.0);
      if (t <= 0) continue;

      final opacity = (1.0 - t).clamp(0.0, 1.0);
      if (opacity <= 0) continue;

      final vx = math.cos(p.angle) * p.speed;
      final vy = math.sin(p.angle) * p.speed - gravity * t;

      final x = centerX + vx * t;
      final y = originY - vy * t + 0.5 * gravity * t * t;

      final rotation = p.rotationSpeed * t * math.pi;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity * 0.9)
        ..style = PaintingStyle.fill;

      switch (p.shape) {
        case 0: // rectangle
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset.zero, width: p.size, height: p.size * 0.6),
              const Radius.circular(1),
            ),
            paint,
          );
          break;
        case 1: // circle
          canvas.drawCircle(Offset.zero, p.size * 0.4, paint);
          break;
        default: // strip
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset.zero, width: p.size * 0.3, height: p.size),
              const Radius.circular(1),
            ),
            paint,
          );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress;
}

class _ConfettiParticle {
  final double angle;
  final double speed;
  final double rotationSpeed;
  final double size;
  final Color color;
  final int shape;
  final double startDelay;

  _ConfettiParticle({
    required this.angle,
    required this.speed,
    required this.rotationSpeed,
    required this.size,
    required this.color,
    required this.shape,
    required this.startDelay,
  });
}
