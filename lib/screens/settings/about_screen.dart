import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../config/theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const SizedBox(height: 8),

            // Back button
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            // App icon + name hero
            Center(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF0B2B26), Color(0xFF163D34)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: GlassContainer(
                  useOwnLayer: true,
                  settings: const LiquidGlassSettings(
                    thickness: 0.5,
                    blur: 6.0,
                    glassColor: Color(0x18FFFFFF),
                  ),
                  shape: const LiquidRoundedSuperellipse(borderRadius: 28),
                  padding: const EdgeInsets.all(20),
                  child: const Icon(
                    Icons.donut_large_rounded,
                    size: 44,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Center(
              child: Text(
                'AyuutoCircle',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Description card
            GlassCard(
              useOwnLayer: true,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded,
                          size: 18, color: AppColors.accent),
                      const SizedBox(width: 8),
                      const Text(
                        'What is AyuutoCircle?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'A non-custodial digital ledger for managing Somali Ayuuto '
                    '(rotating savings groups). Track contributions, manage payouts, '
                    'and keep your circle organised — all from your phone.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Features
            GlassCard(
              useOwnLayer: true,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bolt_rounded,
                          size: 18, color: AppColors.warning),
                      const SizedBox(width: 8),
                      const Text(
                        'Key Features',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _FeatureRow(
                    icon: Icons.groups_rounded,
                    color: AppColors.accent,
                    title: 'Circle Management',
                    subtitle: 'Create and manage multiple savings circles',
                  ),
                  _FeatureRow(
                    icon: Icons.payments_rounded,
                    color: AppColors.info,
                    title: 'Payment Tracking',
                    subtitle: 'Track who has paid and who is pending',
                  ),
                  _FeatureRow(
                    icon: Icons.account_balance_wallet_rounded,
                    color: AppColors.warning,
                    title: 'Payout Management',
                    subtitle: 'Confirm and record payouts to members',
                  ),
                  _FeatureRow(
                    icon: Icons.share_rounded,
                    color: const Color(0xFF6366F1),
                    title: 'Easy Invites',
                    subtitle: 'Share circle codes to invite members',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Legal & info
            GlassCard(
              useOwnLayer: true,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _InfoRow(
                    label: 'Developer',
                    value: 'AyuutoCircle Team',
                  ),
                  const Divider(height: 20, color: AppColors.divider),
                  _InfoRow(
                    label: 'Platform',
                    value: 'Flutter + Supabase',
                  ),
                  const Divider(height: 20, color: AppColors.divider),
                  GestureDetector(
                    onTap: () {
                      showLicensePage(
                        context: context,
                        applicationName: 'AyuutoCircle',
                        applicationVersion: '1.0.0',
                      );
                    },
                    child: Row(
                      children: [
                        Text(
                          'Open Source Licenses',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.chevron_right_rounded,
                            size: 20, color: AppColors.textTertiary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Footer
            Center(
              child: Column(
                children: [
                  Text(
                    'Made with ❤️ for the Somali community',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '© ${DateTime.now().year} AyuutoCircle',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── Feature Row ──────────────────────────────────────────

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _FeatureRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info Row ─────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
