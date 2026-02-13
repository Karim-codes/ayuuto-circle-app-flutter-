import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _pageController = PageController();
  int _currentPage = 0;

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
      duration: const Duration(milliseconds: 2200),
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
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (mounted) context.go('/sign-in');
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = _buildPages();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, right: 20),
                child: GestureDetector(
                  onTap: _completeOnboarding,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: 4,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) => pages[index],
              ),
            ),

            // Dots + button
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
              child: Row(
                children: [
                  // Page dots
                  Row(
                    children: List.generate(4, (i) {
                      final isActive = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        width: isActive ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.accent
                              : AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  // Next / Get Started button
                  GestureDetector(
                    onTap: _nextPage,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 54,
                      padding: EdgeInsets.symmetric(
                        horizontal: _currentPage == 3 ? 28 : 20,
                      ),
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currentPage == 3 ? 'Get Started' : 'Next',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded,
                              color: Colors.white, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPages() {
    return [
      _buildPage1(),
      _buildPage2(),
      _buildPage3(),
      _buildPage4(),
    ];
  }

  // ── Page 1: Welcome — Orbiting people around Ayuuto pot ──

  Widget _buildPage1() {
    return AnimatedBuilder(
      animation: Listenable.merge([_orbitController, _pulseController, _floatController]),
      builder: (context, child) {
        final pulse = 0.88 + (_pulseController.value * 0.12);
        final floatY = sin(_floatController.value * pi) * 8;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 240,
                height: 240,
                child: Transform.translate(
                  offset: Offset(0, floatY),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer ring
                      Transform.scale(
                        scale: pulse,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.1),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      // Inner ring
                      Transform.scale(
                        scale: 0.92 + (_pulseController.value * 0.08),
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.06),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      // Center pot
                      Container(
                        width: 70,
                        height: 70,
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
                              blurRadius: 24 * pulse,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.savings_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      // Orbiting members
                      ..._buildOrbitingMembers(radius: 85),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Welcome to\nAyuutoCircle',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'The modern way to manage your\nrotating savings circles',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Page 2: Create — Composed card scene with member badges ──

  Widget _buildPage2() {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        final t = _floatController.value;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 260,
                height: 260,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background soft circle
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.06),
                      ),
                    ),
                    // Main card
                    Transform.translate(
                      offset: Offset(0, sin(t * pi) * 4),
                      child: Container(
                        width: 140,
                        height: 170,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                                ),
                              ),
                              child: const Icon(Icons.groups_rounded,
                                  color: Colors.white, size: 24),
                            ),
                            const SizedBox(height: 12),
                            const Text('Family',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary)),
                            const SizedBox(height: 4),
                            Text('5 members',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textTertiary)),
                          ],
                        ),
                      ),
                    ),
                    // Floating member badge — top left
                    Transform.translate(
                      offset: Offset(-75, -70 + sin((t + 0.2) * pi) * 6),
                      child: _memberBadge(
                          'A', const Color(0xFFEF4444)),
                    ),
                    // Floating member badge — top right
                    Transform.translate(
                      offset: Offset(80, -55 + sin((t + 0.5) * pi) * 6),
                      child: _memberBadge(
                          'K', AppColors.accent),
                    ),
                    // Floating member badge — bottom left
                    Transform.translate(
                      offset: Offset(-70, 65 + sin((t + 0.7) * pi) * 6),
                      child: _memberBadge(
                          'M', const Color(0xFFF59E0B)),
                    ),
                    // Floating member badge — bottom right
                    Transform.translate(
                      offset: Offset(75, 70 + sin((t + 0.3) * pi) * 6),
                      child: _memberBadge(
                          'S', const Color(0xFF8B5CF6)),
                    ),
                    // Link lines (decorative)
                    Transform.translate(
                      offset: Offset(85, -15 + sin(t * pi) * 3),
                      child: Icon(Icons.link_rounded,
                          size: 18,
                          color: AppColors.accent.withValues(alpha: 0.3)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Create Your Circle',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Set up a savings group in seconds.\nInvite friends and family to join.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Page 3: Contribute — Coins dropping into jar scene ──

  Widget _buildPage3() {
    return AnimatedBuilder(
      animation: Listenable.merge([_floatController, _pulseController]),
      builder: (context, child) {
        final t = _floatController.value;
        final pulse = 0.92 + (_pulseController.value * 0.08);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 260,
                height: 260,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background warm circle
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.06),
                      ),
                    ),
                    // Jar body
                    Positioned(
                      bottom: 30,
                      child: Container(
                        width: 100,
                        height: 110,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                            bottomLeft: Radius.circular(24),
                            bottomRight: Radius.circular(24),
                          ),
                          border: Border.all(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Fill level (animated)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 600),
                              width: 80,
                              height: 50 + (pulse - 0.92) * 200,
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFFFBBF24),
                                    Color(0xFFF59E0B),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Jar lid
                    Positioned(
                      bottom: 138,
                      child: Container(
                        width: 116,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B),
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                    ),
                    // Falling coin 1
                    Transform.translate(
                      offset: Offset(-15, -80 + (t * 40)),
                      child: Opacity(
                        opacity: (1.0 - t).clamp(0.3, 1.0),
                        child: _coinWidget(),
                      ),
                    ),
                    // Falling coin 2
                    Transform.translate(
                      offset: Offset(20, -95 + (((t + 0.4) % 1.0) * 40)),
                      child: Opacity(
                        opacity: (1.0 - ((t + 0.4) % 1.0)).clamp(0.3, 1.0),
                        child: _coinWidget(),
                      ),
                    ),
                    // Falling coin 3
                    Transform.translate(
                      offset: Offset(0, -110 + (((t + 0.7) % 1.0) * 40)),
                      child: Opacity(
                        opacity: (1.0 - ((t + 0.7) % 1.0)).clamp(0.3, 1.0),
                        child: _coinWidget(),
                      ),
                    ),
                    // Sparkle decorations
                    Transform.translate(
                      offset: Offset(-80, -20 + sin(t * pi) * 5),
                      child: Icon(Icons.auto_awesome,
                          size: 18,
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                    ),
                    Transform.translate(
                      offset: Offset(85, 10 + sin((t + 0.5) * pi) * 5),
                      child: Icon(Icons.auto_awesome,
                          size: 14,
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Everyone Contributes',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Each member pays into the pot.\nTrack payments in real-time.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Page 4: Track — Phone dashboard scene ──

  Widget _buildPage4() {
    return AnimatedBuilder(
      animation: Listenable.merge([_floatController, _pulseController]),
      builder: (context, child) {
        final t = _floatController.value;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 260,
                height: 260,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background circle
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accent.withValues(alpha: 0.05),
                      ),
                    ),
                    // Phone frame
                    Transform.translate(
                      offset: Offset(0, sin(t * pi) * 4),
                      child: Container(
                        width: 130,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          border: Border.all(
                            color: AppColors.divider,
                            width: 1.5,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              // Status bar dots
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 30,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: AppColors.divider,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              // Mini chart bars
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _chartBar(28, const Color(0xFF3B82F6).withValues(alpha: 0.3)),
                                  _chartBar(45, AppColors.accent.withValues(alpha: 0.5)),
                                  _chartBar(35, const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                                  _chartBar(55, AppColors.accent),
                                  _chartBar(40, const Color(0xFF3B82F6).withValues(alpha: 0.4)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Divider line
                              Container(
                                height: 1,
                                color: AppColors.divider,
                              ),
                              const SizedBox(height: 10),
                              // Mini list rows
                              _miniRow(AppColors.accent),
                              const SizedBox(height: 6),
                              _miniRow(const Color(0xFF3B82F6)),
                              const SizedBox(height: 6),
                              _miniRow(const Color(0xFFF59E0B)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Floating checkmark badge — top right
                    Transform.translate(
                      offset: Offset(75, -70 + sin((t + 0.3) * pi) * 6),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accent,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.3),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.check_rounded,
                            color: Colors.white, size: 24),
                      ),
                    ),
                    // Floating notification bell — top left
                    Transform.translate(
                      offset: Offset(-75, -55 + sin((t + 0.6) * pi) * 6),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                          border: Border.all(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(Icons.notifications_rounded,
                            size: 16,
                            color: const Color(0xFFF59E0B)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Track Everything',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Fair, transparent, and automatic.\nThat\'s the power of Ayuuto.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Helper widgets ──

  Widget _memberBadge(String initial, Color color) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _coinWidget() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
            blurRadius: 6,
          ),
        ],
      ),
      child: const Center(
        child: Text(
          '£',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _chartBar(double height, Color color) {
    return Container(
      width: 14,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _miniRow(Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 24,
          height: 6,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildOrbitingMembers({required double radius}) {
    final members = [
      (color: const Color(0xFF3B82F6), offset: 0.0),
      (color: const Color(0xFFF59E0B), offset: 0.2),
      (color: const Color(0xFFEF4444), offset: 0.4),
      (color: const Color(0xFF8B5CF6), offset: 0.6),
      (color: AppColors.accent, offset: 0.8),
    ];

    return members.map((m) {
      final angle = (_orbitController.value + m.offset) * 2 * pi;
      final x = cos(angle) * radius;
      final y = sin(angle) * radius * 0.45;
      final scale = 0.65 + (0.35 * ((sin(angle) + 1) / 2));

      return Transform.translate(
        offset: Offset(x, y),
        child: Transform.scale(
          scale: scale,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: m.color.withValues(alpha: 0.15),
              border: Border.all(
                color: m.color.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Icon(Icons.person_rounded, size: 16, color: m.color),
          ),
        ),
      );
    }).toList();
  }
}
