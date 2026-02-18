import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class AuthBackground extends StatefulWidget {
  final Widget child;

  const AuthBackground({super.key, required this.child});

  @override
  State<AuthBackground> createState() => _AuthBackgroundState();
}

class _AuthBackgroundState extends State<AuthBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base background
        Container(color: AppColors.background),

        // Animated gradient blobs
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              children: [
                // Top-left primary blob
                Positioned(
                  top: -100 + (_controller.value * 20),
                  left: -100 + (_controller.value * 10),
                  child: _buildBlob(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    size: 400,
                  ),
                ),
                // Bottom-right accent blob
                Positioned(
                  bottom: -100 - (_controller.value * 20),
                  right: -100 - (_controller.value * 10),
                  child: _buildBlob(
                    color: AppColors.accent.withValues(alpha: 0.2),
                    size: 350,
                  ),
                ),
                // Center-left secondary blob
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.4,
                  left: -150 + (_controller.value * 30),
                  child: _buildBlob(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                    size: 300,
                  ),
                ),
              ],
            );
          },
        ),

        // Blur effect to mesh the blobs
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: Container(color: Colors.transparent),
        ),

        // Content
        widget.child,
      ],
    );
  }

  Widget _buildBlob({required Color color, required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
