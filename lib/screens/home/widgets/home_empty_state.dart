import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../../config/theme.dart';

class HomeEmptyState extends StatefulWidget {
  const HomeEmptyState({super.key});

  @override
  State<HomeEmptyState> createState() => _HomeEmptyStateState();
}

class _HomeEmptyStateState extends State<HomeEmptyState>
    with TickerProviderStateMixin {
  late final AnimationController _orbitController;
  late final AnimationController _pulseController;
  late final AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _orbitController.dispose();
    _pulseController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated illustration
            SizedBox(
              width: 220,
              height: 220,
              child: AnimatedBuilder(
                animation: Listenable.merge(
                    [_orbitController, _pulseController, _floatController]),
                builder: (context, child) {
                  final pulse = 0.85 + (_pulseController.value * 0.15);
                  final floatY = sin(_floatController.value * pi) * 6;

                  return Transform.translate(
                    offset: Offset(0, floatY),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer glow ring
                        Transform.scale(
                          scale: pulse,
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.accent.withValues(alpha: 0.12),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        // Inner glow ring
                        Transform.scale(
                          scale: 0.9 + (_pulseController.value * 0.1),
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.accent.withValues(alpha: 0.08),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        // Center pot icon
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.accent,
                                AppColors.accent.withValues(alpha: 0.7),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.3 * pulse),
                                blurRadius: 20 * pulse,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.savings_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        // Orbiting member avatars
                        ..._buildOrbitingAvatars(),
                        // Floating coins
                        ..._buildFloatingCoins(),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 28),
            // Title
            const Text(
              'Start Your Circle',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
            // Subtitle
            Text(
              'Gather your people, pool your savings,\nand take turns receiving the pot.\nThat\'s Ayuuto — simple & powerful.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            // Create button
            GestureDetector(
              onTap: () => context.push('/create-group'),
              child: Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accent, Color(0xFF00E6AC)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline_rounded,
                        color: Colors.white, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'Create a Circle',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Join button — glass
            GestureDetector(
              onTap: () => context.push('/join'),
              child: GlassCard(
                useOwnLayer: true,
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.link_rounded,
                        color: AppColors.textPrimary, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Join with Invite Code',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildOrbitingAvatars() {
    final avatars = [
      (color: const Color(0xFF3B82F6), icon: Icons.person_rounded, offset: 0.0),
      (color: const Color(0xFFF59E0B), icon: Icons.person_rounded, offset: 0.33),
      (color: const Color(0xFFEF4444), icon: Icons.person_rounded, offset: 0.66),
    ];

    return avatars.map((a) {
      final angle = (_orbitController.value + a.offset) * 2 * pi;
      const radius = 80.0;
      final x = cos(angle) * radius;
      final y = sin(angle) * radius * 0.45; // Elliptical orbit
      final scale = 0.7 + (0.3 * ((sin(angle) + 1) / 2)); // Depth effect

      return Transform.translate(
        offset: Offset(x, y),
        child: Transform.scale(
          scale: scale,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: a.color.withValues(alpha: 0.15),
              border: Border.all(
                color: a.color.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: Icon(a.icon, size: 18, color: a.color),
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildFloatingCoins() {
    final coins = [
      (dx: -50.0, dy: -30.0, delay: 0.0),
      (dx: 55.0, dy: -45.0, delay: 0.4),
      (dx: 40.0, dy: 50.0, delay: 0.7),
    ];

    return coins.map((c) {
      final t = (_floatController.value + c.delay) % 1.0;
      final y = sin(t * pi) * 8;
      final opacity = 0.3 + (sin(t * pi) * 0.4);

      return Transform.translate(
        offset: Offset(c.dx, c.dy + y),
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Text(
            '£',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.accent.withValues(alpha: 0.6),
            ),
          ),
        ),
      );
    }).toList();
  }
}
