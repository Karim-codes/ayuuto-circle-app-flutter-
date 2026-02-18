import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../models/onboarding_question.dart';
import 'onboarding_questions_data.dart';
import 'onboarding_animated_icons.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  final Map<String, List<String>> _answers = {};

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;
  late final AnimationController _slideCtrl;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));

    _fadeCtrl.forward();
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  OnboardingQuestion get _question => onboardingQuestions[_currentIndex];
  bool get _isLastQuestion => _currentIndex == onboardingQuestions.length - 1;
  bool get _hasSelection =>
      (_answers[_question.id] ?? []).isNotEmpty;

  double get _progress =>
      (_currentIndex + 1) / onboardingQuestions.length;

  void _selectOption(String option) {
    setState(() {
      if (_question.isMultiSelect) {
        final current = _answers[_question.id] ?? [];
        if (current.contains(option)) {
          current.remove(option);
        } else {
          current.add(option);
        }
        _answers[_question.id] = current;
      } else {
        _answers[_question.id] = [option];
      }
    });
  }

  bool _isSelected(String option) {
    return (_answers[_question.id] ?? []).contains(option);
  }

  Future<void> _animateTransition(VoidCallback onChange) async {
    await _fadeCtrl.reverse();
    onChange();
    _fadeCtrl.forward();
    _slideCtrl.reset();
    _slideCtrl.forward();
  }

  void _next() {
    if (!_hasSelection) return;

    if (_isLastQuestion) {
      _completeOnboarding();
    } else {
      _animateTransition(() {
        setState(() => _currentIndex++);
      });
    }
  }

  void _back() {
    if (_currentIndex > 0) {
      _animateTransition(() {
        setState(() => _currentIndex--);
      });
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    await prefs.setString(
        'onboarding_answers', jsonEncode(_answers));
    if (mounted) context.go('/sign-in');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar: back + skip ──
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
              child: Row(
                children: [
                  // Back button
                  if (_currentIndex > 0)
                    GestureDetector(
                      onTap: _back,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surfaceVariant,
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 40),
                  const Spacer(),
                  // Skip
                  GestureDetector(
                    onTap: _completeOnboarding,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Progress bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      // Track
                      Container(
                        height: 4,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Fill
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                        height: 4,
                        width: constraints.maxWidth * _progress,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.accent, Color(0xFF00E6AC)],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // ── Question content ──
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      children: [
                        const Spacer(flex: 2),

                        // Animated icon
                        animatedIconFor(_question.id, isDark: isDark),

                        const SizedBox(height: 32),

                        // Question title
                        Text(
                          _question.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                            height: 1.25,
                          ),
                        ),

                        if (_question.subtitle != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            _question.subtitle!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],

                        const SizedBox(height: 28),

                        // Multi-select hint
                        if (_question.isMultiSelect)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              'Select all that apply',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.accent.withValues(alpha: 0.7),
                              ),
                            ),
                          ),

                        // Option chips
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          alignment: WrapAlignment.center,
                          children: _question.options.map((option) {
                            final selected = _isSelected(option);
                            return GestureDetector(
                              onTap: () => _selectOption(option),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.accent.withValues(alpha: 0.12)
                                      : AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: selected
                                        ? AppColors.accent
                                        : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  option,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: selected
                                        ? AppColors.accent
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const Spacer(flex: 3),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Bottom: step indicator + CTA ──
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
              child: Row(
                children: [
                  // Step label
                  Text(
                    '${_currentIndex + 1} of ${onboardingQuestions.length}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const Spacer(),
                  // CTA button
                  GestureDetector(
                    onTap: _hasSelection ? _next : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 54,
                      padding: EdgeInsets.symmetric(
                        horizontal: _isLastQuestion ? 28 : 20,
                      ),
                      decoration: BoxDecoration(
                        gradient: _hasSelection
                            ? const LinearGradient(
                                colors: [
                                  AppColors.accent,
                                  Color(0xFF00E6AC)
                                ],
                              )
                            : LinearGradient(
                                colors: [
                                  AppColors.accent.withValues(alpha: 0.3),
                                  const Color(0xFF00E6AC)
                                      .withValues(alpha: 0.3),
                                ],
                              ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _hasSelection
                            ? [
                                BoxShadow(
                                  color: AppColors.accent
                                      .withValues(alpha: 0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isLastQuestion ? "Let's Go!" : 'Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _hasSelection
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _isLastQuestion
                                ? Icons.rocket_launch_rounded
                                : Icons.arrow_forward_rounded,
                            color: _hasSelection
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.5),
                            size: 20,
                          ),
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
}
