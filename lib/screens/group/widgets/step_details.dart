import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/theme.dart';

class StepDetails extends StatelessWidget {
  final TextEditingController amountController;
  final String currency;
  final String frequency;
  final ValueChanged<String> onCurrencyChanged;
  final ValueChanged<String> onFrequencyChanged;
  final VoidCallback onNext;

  const StepDetails({
    super.key,
    required this.amountController,
    required this.currency,
    required this.frequency,
    required this.onCurrencyChanged,
    required this.onFrequencyChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.tune_rounded,
                size: 28, color: AppColors.primary),
          ),
          const SizedBox(height: 24),
          const Text(
            'How much and\nhow often?',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set the contribution amount and payment schedule.',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),

          // Amount field
          Text(
            'CONTRIBUTION',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: amountController,
                  autofocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: '100',
                    hintStyle: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textTertiary.withValues(alpha: 0.5),
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Currency selector
              ...[
                _CurrencyPill(
                    label: '£',
                    value: 'GBP',
                    selected: currency,
                    onTap: onCurrencyChanged),
                const SizedBox(width: 6),
                _CurrencyPill(
                    label: '\$',
                    value: 'USD',
                    selected: currency,
                    onTap: onCurrencyChanged),
                const SizedBox(width: 6),
                _CurrencyPill(
                    label: 'Sh',
                    value: 'SOS',
                    selected: currency,
                    onTap: onCurrencyChanged),
              ],
            ],
          ),
          const SizedBox(height: 28),

          // Frequency
          Text(
            'FREQUENCY',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _FrequencyOption(
                label: 'Weekly',
                value: 'weekly',
                selected: frequency,
                onTap: onFrequencyChanged,
              ),
              const SizedBox(width: 10),
              _FrequencyOption(
                label: 'Bi-weekly',
                value: 'biweekly',
                selected: frequency,
                onTap: onFrequencyChanged,
              ),
              const SizedBox(width: 10),
              _FrequencyOption(
                label: 'Monthly',
                value: 'monthly',
                selected: frequency,
                onTap: onFrequencyChanged,
              ),
            ],
          ),

          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                textStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Continue'),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Currency Pill ───────────────────────────────────────

class _CurrencyPill extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onTap;

  const _CurrencyPill({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.12)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.accent : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isSelected ? AppColors.accent : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Frequency Option ────────────────────────────────────

class _FrequencyOption extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onTap;

  const _FrequencyOption({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.accent.withValues(alpha: 0.12)
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.accent : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color:
                    isSelected ? AppColors.accent : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
