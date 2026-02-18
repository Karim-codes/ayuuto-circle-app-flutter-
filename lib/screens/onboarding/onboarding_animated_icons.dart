import 'dart:math';
import 'package:flutter/material.dart';

/// Routes a question [id] to its matching animated widget.
Widget animatedIconFor(String id, {required bool isDark}) {
  switch (id) {
    case 'ayuuto_experience':
      return _HandsCircleAnimation(isDark: isDark);
    case 'your_role':
      return _RoleSwitchAnimation(isDark: isDark);
    case 'circle_size':
      return _GrowingGroupAnimation(isDark: isDark);
    case 'biggest_headache':
      return _ChaoticMessagesAnimation(isDark: isDark);
    case 'ready':
      return _DoorOpenAnimation(isDark: isDark);
    default:
      return const SizedBox(width: 200, height: 200);
  }
}

// ─────────────────────────────────────────────────────────────
// 1. Hands Circle — hands passing coins around a ring (Ayuuto)
// ─────────────────────────────────────────────────────────────

class _HandsCircleAnimation extends StatefulWidget {
  final bool isDark;
  const _HandsCircleAnimation({required this.isDark});

  @override
  State<_HandsCircleAnimation> createState() => _HandsCircleAnimationState();
}

class _HandsCircleAnimationState extends State<_HandsCircleAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _rotateCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _coinCtrl;

  @override
  void initState() {
    super.initState();
    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _coinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _rotateCtrl.dispose();
    _pulseCtrl.dispose();
    _coinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: AnimatedBuilder(
        animation: Listenable.merge([_rotateCtrl, _pulseCtrl, _coinCtrl]),
        builder: (context, _) {
          return CustomPaint(
            size: const Size(200, 200),
            painter: _HandsCirclePainter(
              rotate: _rotateCtrl.value,
              pulse: _pulseCtrl.value,
              coin: _coinCtrl.value,
              isDark: widget.isDark,
            ),
          );
        },
      ),
    );
  }
}

class _HandsCirclePainter extends CustomPainter {
  final double rotate;
  final double pulse;
  final double coin;
  final bool isDark;

  _HandsCirclePainter({
    required this.rotate,
    required this.pulse,
    required this.coin,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final accent = isDark ? const Color(0xFF00E6AC) : const Color(0xFF00D09C);

    // Outer dashed circle
    final dashPaint = Paint()
      ..color = accent.withValues(alpha: 0.12 + pulse * 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    const ringR = 74.0;
    for (var i = 0; i < 24; i++) {
      final a = i / 24 * 2 * pi;
      final len = 0.08;
      final startA = a;
      final endA = a + len;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: ringR),
        startA,
        endA - startA,
        false,
        dashPaint,
      );
    }

    // 5 people nodes around the ring
    const memberCount = 5;
    final memberColors = [
      const Color(0xFF3B82F6),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF8B5CF6),
      accent,
    ];

    for (var i = 0; i < memberCount; i++) {
      final angle = (i / memberCount) * 2 * pi - pi / 2;
      final mx = cx + cos(angle) * ringR;
      final my = cy + sin(angle) * ringR;

      // Person body (head + shoulders)
      final color = memberColors[i];

      // Head
      canvas.drawCircle(
        Offset(mx, my - 6),
        7,
        Paint()..color = color.withValues(alpha: 0.85),
      );
      // Shoulders arc
      final shoulderPath = Path()
        ..addArc(
          Rect.fromCenter(center: Offset(mx, my + 8), width: 20, height: 14),
          pi,
          pi,
        );
      canvas.drawPath(
        shoulderPath,
        Paint()
          ..color = color.withValues(alpha: 0.6)
          ..style = PaintingStyle.fill,
      );

      // Glow ring around active person
      final isActive = (coin * memberCount).floor() % memberCount == i;
      if (isActive) {
        canvas.drawCircle(
          Offset(mx, my),
          20,
          Paint()
            ..color = accent.withValues(alpha: 0.25 + pulse * 0.15)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
      }
    }

    // Animated coin traveling between members
    final coinIdx = (coin * memberCount) % memberCount;
    final fromIdx = coinIdx.floor();
    final toIdx = (fromIdx + 1) % memberCount;
    final t = coinIdx - fromIdx;

    final fromAngle = (fromIdx / memberCount) * 2 * pi - pi / 2;
    final toAngle = (toIdx / memberCount) * 2 * pi - pi / 2;

    final coinX = cx + cos(fromAngle + (toAngle - fromAngle + 2 * pi) % (2 * pi) * t) * ringR * 0.7;
    final coinY = cy + sin(fromAngle + (toAngle - fromAngle + 2 * pi) % (2 * pi) * t) * ringR * 0.7;

    // Coin glow
    canvas.drawCircle(
      Offset(coinX, coinY),
      14,
      Paint()..color = const Color(0xFFFBBF24).withValues(alpha: 0.15),
    );
    // Coin body
    canvas.drawCircle(
      Offset(coinX, coinY),
      9,
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0xFFFBBF24), const Color(0xFFF59E0B)],
        ).createShader(Rect.fromCircle(center: Offset(coinX, coinY), radius: 9)),
    );
    // £ symbol on coin
    final tp = TextPainter(
      text: const TextSpan(
        text: '£',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(coinX - tp.width / 2, coinY - tp.height / 2));

    // Center label — "Ayuuto" text
    final labelPaint = TextPainter(
      text: TextSpan(
        text: '●',
        style: TextStyle(
          color: accent.withValues(alpha: 0.3 + pulse * 0.2),
          fontSize: 28,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    labelPaint.paint(canvas, Offset(cx - labelPaint.width / 2, cy - labelPaint.height / 2));
  }

  @override
  bool shouldRepaint(covariant _HandsCirclePainter old) => true;
}

// ─────────────────────────────────────────────────────────────
// 2. Role Switch — clipboard (organiser) / person (member)
// ─────────────────────────────────────────────────────────────

class _RoleSwitchAnimation extends StatefulWidget {
  final bool isDark;
  const _RoleSwitchAnimation({required this.isDark});

  @override
  State<_RoleSwitchAnimation> createState() => _RoleSwitchAnimationState();
}

class _RoleSwitchAnimationState extends State<_RoleSwitchAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _switchCtrl;
  late final AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();
    _switchCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _switchCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: AnimatedBuilder(
        animation: Listenable.merge([_switchCtrl, _glowCtrl]),
        builder: (context, _) {
          return CustomPaint(
            size: const Size(200, 200),
            painter: _RoleSwitchPainter(
              phase: _switchCtrl.value,
              glow: _glowCtrl.value,
              isDark: widget.isDark,
            ),
          );
        },
      ),
    );
  }
}

class _RoleSwitchPainter extends CustomPainter {
  final double phase;
  final double glow;
  final bool isDark;

  _RoleSwitchPainter({
    required this.phase,
    required this.glow,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;
    final accent = isDark ? const Color(0xFF00E6AC) : const Color(0xFF00D09C);
    final dark = isDark ? const Color(0xFF1E293B) : const Color(0xFF0D2C54);

    // Determine which side is active (0-0.5 = organiser, 0.5-1 = member)
    final isOrganiser = phase < 0.5;
    final leftAlpha = isOrganiser ? 1.0 : 0.35;
    final rightAlpha = isOrganiser ? 0.35 : 1.0;

    // Divider line
    canvas.drawLine(
      Offset(cx, cy - 56),
      Offset(cx, cy + 56),
      Paint()
        ..color = accent.withValues(alpha: 0.1)
        ..strokeWidth = 1,
    );

    // ── Left: Organiser (clipboard with crown) ──
    final lx = cx - 42;

    // Clipboard body
    final clipRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(lx, cy + 6), width: 46, height: 56),
      const Radius.circular(6),
    );
    canvas.drawRRect(
      clipRect,
      Paint()..color = dark.withValues(alpha: 0.7 * leftAlpha),
    );
    canvas.drawRRect(
      clipRect,
      Paint()
        ..color = accent.withValues(alpha: 0.4 * leftAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Clipboard clip
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(lx, cy - 20), width: 20, height: 8),
        const Radius.circular(4),
      ),
      Paint()..color = accent.withValues(alpha: 0.6 * leftAlpha),
    );

    // Checklist lines
    for (var i = 0; i < 3; i++) {
      final ly = cy - 4 + i * 14;
      // Tick
      final tickPaint = Paint()
        ..color = accent.withValues(alpha: 0.7 * leftAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(lx - 12, ly), Offset(lx - 7, ly + 3), tickPaint);
      canvas.drawLine(Offset(lx - 7, ly + 3), Offset(lx - 3, ly - 3), tickPaint);
      // Line
      canvas.drawLine(
        Offset(lx + 2, ly),
        Offset(lx + 16, ly),
        Paint()
          ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2 * leftAlpha)
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
    }

    // Crown above clipboard
    final crownY = cy - 40;
    final crownPaint = Paint()..color = const Color(0xFFFBBF24).withValues(alpha: 0.8 * leftAlpha);
    final crown = Path()
      ..moveTo(lx - 12, crownY + 8)
      ..lineTo(lx - 12, crownY)
      ..lineTo(lx - 6, crownY + 4)
      ..lineTo(lx, crownY - 3)
      ..lineTo(lx + 6, crownY + 4)
      ..lineTo(lx + 12, crownY)
      ..lineTo(lx + 12, crownY + 8)
      ..close();
    canvas.drawPath(crown, crownPaint);

    // Organiser glow
    if (isOrganiser) {
      canvas.drawCircle(
        Offset(lx, cy),
        42,
        Paint()..color = accent.withValues(alpha: 0.06 + glow * 0.04),
      );
    }

    // ── Right: Member (person with hand raised) ──
    final rx = cx + 42;

    // Head
    canvas.drawCircle(
      Offset(rx, cy - 20),
      11,
      Paint()..color = const Color(0xFF3B82F6).withValues(alpha: 0.8 * rightAlpha),
    );

    // Body
    final bodyPath = Path()
      ..moveTo(rx - 14, cy + 20)
      ..quadraticBezierTo(rx - 14, cy - 3, rx, cy - 6)
      ..quadraticBezierTo(rx + 14, cy - 3, rx + 14, cy + 20)
      ..close();
    canvas.drawPath(
      bodyPath,
      Paint()..color = const Color(0xFF3B82F6).withValues(alpha: 0.6 * rightAlpha),
    );

    // Raised hand
    final handWave = sin(glow * pi) * 6;
    canvas.drawLine(
      Offset(rx + 12, cy - 3),
      Offset(rx + 22, cy - 26 + handWave),
      Paint()
        ..color = const Color(0xFF3B82F6).withValues(alpha: 0.7 * rightAlpha)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    // Hand circle
    canvas.drawCircle(
      Offset(rx + 22, cy - 28 + handWave),
      4,
      Paint()..color = const Color(0xFFFBBF24).withValues(alpha: 0.7 * rightAlpha),
    );

    // Member glow
    if (!isOrganiser) {
      canvas.drawCircle(
        Offset(rx, cy),
        42,
        Paint()..color = const Color(0xFF3B82F6).withValues(alpha: 0.06 + glow * 0.04),
      );
    }

    // Active indicator dot
    final dotX = isOrganiser ? lx : rx;
    canvas.drawCircle(
      Offset(dotX, cy + 48),
      4,
      Paint()..color = accent.withValues(alpha: 0.6 + glow * 0.4),
    );
  }

  @override
  bool shouldRepaint(covariant _RoleSwitchPainter old) => true;
}

// ─────────────────────────────────────────────────────────────
// 3. Growing Group — people dots appearing one by one in a ring
// ─────────────────────────────────────────────────────────────

class _GrowingGroupAnimation extends StatefulWidget {
  final bool isDark;
  const _GrowingGroupAnimation({required this.isDark});

  @override
  State<_GrowingGroupAnimation> createState() => _GrowingGroupAnimationState();
}

class _GrowingGroupAnimationState extends State<_GrowingGroupAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _growCtrl;
  late final AnimationController _breatheCtrl;

  @override
  void initState() {
    super.initState();
    _growCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _breatheCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _growCtrl.dispose();
    _breatheCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: AnimatedBuilder(
        animation: Listenable.merge([_growCtrl, _breatheCtrl]),
        builder: (context, _) {
          return CustomPaint(
            size: const Size(200, 200),
            painter: _GrowingGroupPainter(
              grow: _growCtrl.value,
              breathe: _breatheCtrl.value,
              isDark: widget.isDark,
            ),
          );
        },
      ),
    );
  }
}

class _GrowingGroupPainter extends CustomPainter {
  final double grow;
  final double breathe;
  final bool isDark;

  _GrowingGroupPainter({
    required this.grow,
    required this.breathe,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final accent = isDark ? const Color(0xFF00E6AC) : const Color(0xFF00D09C);

    const maxMembers = 8;
    final visibleCount = (grow * maxMembers).ceil().clamp(1, maxMembers);
    final ringR = 60.0 + breathe * 4;

    // Background ring
    canvas.drawCircle(
      Offset(cx, cy),
      ringR + 4,
      Paint()
        ..color = accent.withValues(alpha: 0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final memberColors = [
      accent,
      const Color(0xFF3B82F6),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF8B5CF6),
      const Color(0xFF06B6D4),
      const Color(0xFFEC4899),
      const Color(0xFF84CC16),
    ];

    // Draw members appearing
    for (var i = 0; i < maxMembers; i++) {
      final angle = (i / maxMembers) * 2 * pi - pi / 2;
      final mx = cx + cos(angle) * ringR;
      final my = cy + sin(angle) * ringR;

      if (i < visibleCount) {
        // Calculate pop-in scale for the newest member
        double scale = 1.0;
        if (i == visibleCount - 1) {
          final memberProgress = (grow * maxMembers) - i;
          scale = memberProgress.clamp(0.0, 1.0);
        }

        final color = memberColors[i % memberColors.length];

        // Connection line to center
        canvas.drawLine(
          Offset(cx, cy),
          Offset(mx, my),
          Paint()
            ..color = color.withValues(alpha: 0.08 * scale)
            ..strokeWidth = 1,
        );

        // Head
        canvas.drawCircle(
          Offset(mx, my - 4 * scale),
          6.5 * scale,
          Paint()..color = color.withValues(alpha: 0.85 * scale),
        );
        // Body
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(mx, my + 7 * scale),
            width: 17 * scale,
            height: 11 * scale,
          ),
          pi,
          pi,
          false,
          Paint()..color = color.withValues(alpha: 0.5 * scale),
        );

        // Pop sparkle for newest
        if (i == visibleCount - 1 && scale < 0.8) {
          for (var s = 0; s < 4; s++) {
            final sa = s / 4 * 2 * pi;
            final sd = 14 + (1 - scale) * 11;
            canvas.drawCircle(
              Offset(mx + cos(sa) * sd, my + sin(sa) * sd),
              1.5 * (1 - scale),
              Paint()..color = color.withValues(alpha: 0.4 * (1 - scale)),
            );
          }
        }
      } else {
        // Placeholder dot
        canvas.drawCircle(
          Offset(mx, my),
          3,
          Paint()
            ..color = accent.withValues(alpha: 0.08)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
    }

    // Center count
    final countTp = TextPainter(
      text: TextSpan(
        text: '$visibleCount',
        style: TextStyle(
          color: accent.withValues(alpha: 0.7),
          fontSize: 26,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    countTp.paint(canvas, Offset(cx - countTp.width / 2, cy - countTp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _GrowingGroupPainter old) => true;
}

// ─────────────────────────────────────────────────────────────
// 4. Chaotic Messages — phone with messy notifications
// ─────────────────────────────────────────────────────────────

class _ChaoticMessagesAnimation extends StatefulWidget {
  final bool isDark;
  const _ChaoticMessagesAnimation({required this.isDark});

  @override
  State<_ChaoticMessagesAnimation> createState() =>
      _ChaoticMessagesAnimationState();
}

class _ChaoticMessagesAnimationState extends State<_ChaoticMessagesAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _shakeCtrl;
  late final AnimationController _popCtrl;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
    _popCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _popCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: AnimatedBuilder(
        animation: Listenable.merge([_shakeCtrl, _popCtrl]),
        builder: (context, _) {
          return CustomPaint(
            size: const Size(200, 200),
            painter: _ChaoticMessagesPainter(
              shake: _shakeCtrl.value,
              pop: _popCtrl.value,
              isDark: widget.isDark,
            ),
          );
        },
      ),
    );
  }
}

class _ChaoticMessagesPainter extends CustomPainter {
  final double shake;
  final double pop;
  final bool isDark;

  _ChaoticMessagesPainter({
    required this.shake,
    required this.pop,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;
    final accent = isDark ? const Color(0xFF00E6AC) : const Color(0xFF00D09C);
    final dark = isDark ? const Color(0xFF1E293B) : const Color(0xFF0D2C54);
    final red = const Color(0xFFEF4444);

    // Phone shake offset
    final shakeX = sin(shake * 2 * pi * 3) * 2;
    final shakeY = cos(shake * 2 * pi * 2) * 1;

    canvas.save();
    canvas.translate(shakeX, shakeY);

    // Phone body
    final phoneRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: 74, height: 114),
      const Radius.circular(10),
    );
    canvas.drawRRect(phoneRect, Paint()..color = dark.withValues(alpha: 0.8));
    canvas.drawRRect(
      phoneRect,
      Paint()
        ..color = accent.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Screen area
    final screenRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: 60, height: 88),
      const Radius.circular(4),
    );
    canvas.drawRRect(
      screenRect,
      Paint()..color = (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
    );

    // Message bubbles on screen (stacked, messy)
    final bubbleData = [
      (Offset(cx - 8, cy - 28), 40.0, accent.withValues(alpha: 0.2)),
      (Offset(cx + 6, cy - 12), 34.0, const Color(0xFF3B82F6).withValues(alpha: 0.2)),
      (Offset(cx - 6, cy + 6), 42.0, const Color(0xFFF59E0B).withValues(alpha: 0.2)),
      (Offset(cx + 3, cy + 22), 32.0, const Color(0xFF8B5CF6).withValues(alpha: 0.2)),
    ];

    for (final (pos, width, color) in bubbleData) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: pos, width: width, height: 11),
          const Radius.circular(4),
        ),
        Paint()..color = color,
      );
      // Text lines
      canvas.drawLine(
        Offset(pos.dx - width / 2 + 3, pos.dy),
        Offset(pos.dx + width / 2 - 3, pos.dy),
        Paint()
          ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.15)
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
    }

    canvas.restore();

    // Floating notification badges popping around the phone
    final badges = [
      (Offset(cx + 40, cy - 48), '3'),
      (Offset(cx - 42, cy - 26), '!'),
      (Offset(cx + 44, cy + 12), '7'),
      (Offset(cx - 40, cy + 32), '?'),
    ];

    for (var i = 0; i < badges.length; i++) {
      final t = (pop + i / badges.length) % 1.0;
      final visible = t < 0.7;
      if (!visible) continue;

      final scale = t < 0.1 ? t / 0.1 : (t > 0.5 ? (0.7 - t) / 0.2 : 1.0);
      final (basePos, label) = badges[i];
      final floatY = basePos.dy - t * 8;

      // Red badge
      canvas.drawCircle(
        Offset(basePos.dx, floatY),
        11 * scale.clamp(0.0, 1.0),
        Paint()..color = red.withValues(alpha: 0.85 * scale.clamp(0.0, 1.0)),
      );

      // Badge text
      if (scale > 0.3) {
        final tp = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: scale.clamp(0.0, 1.0)),
              fontSize: 11 * scale.clamp(0.5, 1.0),
              fontWeight: FontWeight.w800,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(basePos.dx - tp.width / 2, floatY - tp.height / 2));
      }
    }

    // Stress lines radiating from phone
    for (var i = 0; i < 6; i++) {
      final angle = (i / 6) * 2 * pi + shake * pi;
      final innerR = 64.0;
      final outerR = 70.0 + sin(pop * 2 * pi + i) * 4;
      canvas.drawLine(
        Offset(cx + cos(angle) * innerR, cy + sin(angle) * innerR),
        Offset(cx + cos(angle) * outerR, cy + sin(angle) * outerR),
        Paint()
          ..color = red.withValues(alpha: 0.15)
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ChaoticMessagesPainter old) => true;
}

// ─────────────────────────────────────────────────────────────
// 5. Door Open — door opening with light streaming through
// ─────────────────────────────────────────────────────────────

class _DoorOpenAnimation extends StatefulWidget {
  final bool isDark;
  const _DoorOpenAnimation({required this.isDark});

  @override
  State<_DoorOpenAnimation> createState() => _DoorOpenAnimationState();
}

class _DoorOpenAnimationState extends State<_DoorOpenAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _doorCtrl;
  late final AnimationController _sparkleCtrl;

  @override
  void initState() {
    super.initState();
    _doorCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _sparkleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _doorCtrl.dispose();
    _sparkleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: AnimatedBuilder(
        animation: Listenable.merge([_doorCtrl, _sparkleCtrl]),
        builder: (context, _) {
          return CustomPaint(
            size: const Size(200, 200),
            painter: _DoorOpenPainter(
              door: _doorCtrl.value,
              sparkle: _sparkleCtrl.value,
              isDark: widget.isDark,
            ),
          );
        },
      ),
    );
  }
}

class _DoorOpenPainter extends CustomPainter {
  final double door;
  final double sparkle;
  final bool isDark;

  _DoorOpenPainter({
    required this.door,
    required this.sparkle,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final accent = isDark ? const Color(0xFF00E6AC) : const Color(0xFF00D09C);
    final dark = isDark ? const Color(0xFF1E293B) : const Color(0xFF0D2C54);

    // Door opening amount (ease in-out)
    final openAmount = Curves.easeInOut.transform(door);

    // Door frame
    final frameLeft = cx - 34;
    final frameRight = cx + 34;
    final frameTop = h * 0.2;
    final frameBottom = h * 0.85;

    // Frame outline
    final framePath = Path()
      ..moveTo(frameLeft - 4, frameBottom)
      ..lineTo(frameLeft - 4, frameTop - 4)
      ..arcToPoint(
        Offset(frameLeft, frameTop - 8),
        radius: const Radius.circular(4),
      )
      ..lineTo(frameRight, frameTop - 8)
      ..arcToPoint(
        Offset(frameRight + 4, frameTop - 4),
        radius: const Radius.circular(4),
      )
      ..lineTo(frameRight + 4, frameBottom);

    canvas.drawPath(
      framePath,
      Paint()
        ..color = dark.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    // Light streaming through the opening
    final lightWidth = openAmount * 62;
    if (lightWidth > 0) {
      final lightPath = Path()
        ..moveTo(cx - lightWidth / 2, frameTop)
        ..lineTo(cx - lightWidth * 0.8, frameBottom)
        ..lineTo(cx + lightWidth * 0.8, frameBottom)
        ..lineTo(cx + lightWidth / 2, frameTop)
        ..close();

      canvas.drawPath(
        lightPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              accent.withValues(alpha: 0.3 * openAmount),
              accent.withValues(alpha: 0.05 * openAmount),
            ],
          ).createShader(Rect.fromLTWH(0, frameTop, w, frameBottom - frameTop)),
      );

      // Light rays
      for (var i = 0; i < 5; i++) {
        final rayAngle = (i - 2) * 0.15;
        final rayX = cx + rayAngle * 85;
        canvas.drawLine(
          Offset(cx, frameTop + 10),
          Offset(rayX, frameBottom - 5),
          Paint()
            ..color = accent.withValues(alpha: 0.08 * openAmount)
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    // Door panel (perspective skew as it opens)
    final doorWidth = 32.0 * (1 - openAmount * 0.7);
    final doorLeft = frameLeft;

    final doorPath = Path()
      ..moveTo(doorLeft, frameTop)
      ..lineTo(doorLeft + doorWidth, frameTop + openAmount * 6)
      ..lineTo(doorLeft + doorWidth, frameBottom - openAmount * 3)
      ..lineTo(doorLeft, frameBottom)
      ..close();

    canvas.drawPath(
      doorPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            dark.withValues(alpha: 0.9),
            dark.withValues(alpha: 0.6),
          ],
        ).createShader(Rect.fromLTWH(doorLeft, frameTop, doorWidth, frameBottom - frameTop)),
    );

    // Door handle
    final handleX = doorLeft + doorWidth - 4;
    final handleY = (frameTop + frameBottom) / 2;
    canvas.drawCircle(
      Offset(handleX, handleY),
      3.5,
      Paint()..color = const Color(0xFFFBBF24).withValues(alpha: 0.8),
    );

    // Sparkles coming through the door
    if (openAmount > 0.3) {
      final sparkleAlpha = (openAmount - 0.3) / 0.7;
      for (var i = 0; i < 8; i++) {
        final t = (sparkle + i / 8) % 1.0;
        final sx = cx - 14 + (i % 3 - 1) * 17 + sin(t * pi * 2) * 6;
        final sy = frameTop + 20 + t * (frameBottom - frameTop - 30);
        final sa = (1.0 - t) * sparkleAlpha;

        // Star sparkle shape
        final starSize = 3.0 + sin(t * pi) * 2.0;
        canvas.drawCircle(
          Offset(sx, sy),
          starSize,
          Paint()..color = accent.withValues(alpha: 0.4 * sa),
        );
        // Cross sparkle
        canvas.drawLine(
          Offset(sx - starSize, sy),
          Offset(sx + starSize, sy),
          Paint()
            ..color = accent.withValues(alpha: 0.3 * sa)
            ..strokeWidth = 0.8,
        );
        canvas.drawLine(
          Offset(sx, sy - starSize),
          Offset(sx, sy + starSize),
          Paint()
            ..color = accent.withValues(alpha: 0.3 * sa)
            ..strokeWidth = 0.8,
        );
      }
    }

    // Floor line
    canvas.drawLine(
      Offset(cx - 56, frameBottom),
      Offset(cx + 56, frameBottom),
      Paint()
        ..color = dark.withValues(alpha: 0.2)
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _DoorOpenPainter old) => true;
}
