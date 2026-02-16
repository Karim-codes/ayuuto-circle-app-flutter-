import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _ringController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.6, end: 1).animate(
      CurvedAnimation(
          parent: _fadeController,
          curve: const Interval(0, 0.7, curve: Curves.elasticOut)),
    );
    _slideAnimation = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
          parent: _fadeController,
          curve: const Interval(0.3, 1, curve: Curves.easeOut)),
    );

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _fadeController.forward();
    _redirect();
  }

  Future<void> _redirect() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_complete') ?? false;

    if (!onboardingDone) {
      if (mounted) context.go('/onboarding');
      return;
    }

    if (!mounted) return;
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      if (mounted) context.go('/home');
    } else {
      if (mounted) context.go('/sign-in');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _ringController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071E1A),
      body: Stack(
        children: [
          // Animated background rings
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_ringController, _pulseController]),
              builder: (context, child) {
                final pulse = 1.0 + _pulseController.value * 0.08;
                return CustomPaint(
                  size: const Size(360, 360),
                  painter: _SplashRingsPainter(
                    rotation: _ringController.value * 2 * pi,
                    pulse: pulse,
                  ),
                );
              },
            ),
          ),

          // Content
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: AnimatedBuilder(
                animation: _slideAnimation,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: child,
                ),
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF00E4A8),
                              Color(0xFF00D09C),
                              Color(0xFF00B88C),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.4),
                              blurRadius: 30,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.circle_outlined,
                              size: 42,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            Icon(
                              Icons.circle_outlined,
                              size: 28,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'AyuutoCircle',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your savings, your circle',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.5),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom shimmer loading indicator
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accent.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashRingsPainter extends CustomPainter {
  final double rotation;
  final double pulse;

  _SplashRingsPainter({required this.rotation, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Outer ring
    final outerPaint = Paint()
      ..color = const Color(0xFF00D09C).withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, 160 * pulse, outerPaint);

    // Middle ring
    final midPaint = Paint()
      ..color = const Color(0xFF00D09C).withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, 120 * pulse, midPaint);

    // Inner ring
    final innerPaint = Paint()
      ..color = const Color(0xFF00D09C).withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawCircle(center, 80 * pulse, innerPaint);

    // Orbiting dot on outer ring
    final dotX = center.dx + 160 * pulse * cos(rotation);
    final dotY = center.dy + 160 * pulse * sin(rotation);
    final dotPaint = Paint()
      ..color = const Color(0xFF00D09C).withValues(alpha: 0.35);
    canvas.drawCircle(Offset(dotX, dotY), 3, dotPaint);

    // Second orbiting dot on middle ring (opposite direction)
    final dot2X = center.dx + 120 * pulse * cos(-rotation * 0.7);
    final dot2Y = center.dy + 120 * pulse * sin(-rotation * 0.7);
    canvas.drawCircle(Offset(dot2X, dot2Y), 2.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _SplashRingsPainter oldDelegate) => true;
}
