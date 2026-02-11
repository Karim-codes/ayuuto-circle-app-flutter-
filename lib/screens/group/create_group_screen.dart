import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/providers.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _whatsappController = TextEditingController();
  String _currency = 'GBP';
  String _frequency = 'monthly';
  bool _isLoading = false;

  final List<_MemberEntry> _members = [];

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _whatsappController.dispose();
    for (final m in _members) {
      m.nameController.dispose();
      m.phoneController.dispose();
    }
    super.dispose();
  }

  void _addMember() {
    setState(() {
      _members.add(_MemberEntry(
        nameController: TextEditingController(),
        phoneController: TextEditingController(),
      ));
    });
  }

  void _removeMember(int index) {
    setState(() {
      _members[index].nameController.dispose();
      _members[index].phoneController.dispose();
      _members.removeAt(index);
    });
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final membersJson = _members
          .where((m) => m.nameController.text.trim().isNotEmpty)
          .toList()
          .asMap()
          .entries
          .map((entry) => {
                'name': entry.value.nameController.text.trim(),
                'phone': entry.value.phoneController.text.trim().isEmpty
                    ? null
                    : entry.value.phoneController.text.trim(),
                'payout_position': entry.key + 2,
              })
          .toList();

      final groupId = await ref.read(groupServiceProvider).createGroup(
            name: _nameController.text.trim(),
            contributionAmount: double.parse(_amountController.text.trim()),
            currency: _currency,
            frequency: _frequency,
            whatsappLink: _whatsappController.text.trim().isEmpty
                ? null
                : _whatsappController.text.trim(),
            members: membersJson.isEmpty ? null : membersJson,
          );

      ref.invalidate(myGroupsProvider);

      if (mounted) {
        context.go('/group/$groupId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create group: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('New Circle'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Group name
            _SectionLabel('Circle Name'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'e.g. Family Ayuuto',
                prefixIcon: Icon(Icons.group_outlined),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter a name' : null,
            ),
            const SizedBox(height: 24),

            // Amount + Currency
            _SectionLabel('Contribution Amount'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    decoration: const InputDecoration(
                      hintText: '100',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter amount';
                      final amount = double.tryParse(v.trim());
                      if (amount == null || amount <= 0) {
                        return 'Invalid amount';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _currency,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'GBP', child: Text('£ GBP')),
                          DropdownMenuItem(value: 'USD', child: Text('\$ USD')),
                          DropdownMenuItem(value: 'SOS', child: Text('Sh SOS')),
                        ],
                        onChanged: (v) => setState(() => _currency = v!),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Frequency
            _SectionLabel('Frequency'),
            const SizedBox(height: 8),
            Row(
              children: [
                _FrequencyChip(
                  label: 'Weekly',
                  selected: _frequency == 'weekly',
                  onTap: () => setState(() => _frequency = 'weekly'),
                ),
                const SizedBox(width: 8),
                _FrequencyChip(
                  label: 'Bi-weekly',
                  selected: _frequency == 'biweekly',
                  onTap: () => setState(() => _frequency = 'biweekly'),
                ),
                const SizedBox(width: 8),
                _FrequencyChip(
                  label: 'Monthly',
                  selected: _frequency == 'monthly',
                  onTap: () => setState(() => _frequency = 'monthly'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // WhatsApp link (optional)
            _SectionLabel('WhatsApp Group Link (optional)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _whatsappController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                hintText: 'https://chat.whatsapp.com/...',
                prefixIcon: Icon(Icons.chat_outlined),
              ),
            ),
            const SizedBox(height: 32),

            // Members section
            Row(
              children: [
                _SectionLabel('Members'),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addMember,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Organizer (you) - always first
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        '1',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'You (Organizer)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Organizer',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Member entries
            ...List.generate(_members.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 2}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _members[index].nameController,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                hintText: 'Member name',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Enter name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _members[index].phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                hintText: 'Phone (optional)',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            size: 18, color: AppColors.textTertiary),
                        onPressed: () => _removeMember(index),
                      ),
                    ],
                  ),
                ),
              );
            }),

            if (_members.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Add members now or invite them later with a code.',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 32),

            // Create button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createGroup,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Create Circle'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _FrequencyChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FrequencyChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.12)
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.accent : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.accent : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MemberEntry {
  final TextEditingController nameController;
  final TextEditingController phoneController;

  _MemberEntry({
    required this.nameController,
    required this.phoneController,
  });
}
