import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/providers.dart';
import 'widgets/member_entry.dart';
import 'widgets/step_name.dart';
import 'widgets/step_details.dart';
import 'widgets/step_members.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  // Step 1
  final _nameController = TextEditingController();

  // Step 2
  final _amountController = TextEditingController();
  String _currency = 'GBP';
  String _frequency = 'monthly';

  // Step 3
  final List<MemberEntry> _members = [];

  static const _totalSteps = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkTierLimit());
  }

  Future<void> _checkTierLimit() async {
    final profile = ref.read(profileProvider).valueOrNull;
    final groups = ref.read(myGroupsProvider).valueOrNull ?? [];
    final tier = profile?.subscriptionTier ?? 'free';

    if (tier == 'free' && groups.isNotEmpty) {
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.lock_outline_rounded,
                  color: AppColors.warning, size: 24),
              SizedBox(width: 10),
              Text('Free Tier Limit'),
            ],
          ),
          content: const Text(
            'Free accounts can create 1 circle.\n\nUpgrade to Premium for unlimited circles and members.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (mounted) context.pop();
              },
              child: const Text('Go Back'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (mounted) context.pop();
                // TODO: Navigate to upgrade/subscription screen
              },
              child: const Text('Upgrade'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _amountController.dispose();
    for (final m in _members) {
      m.nameController.dispose();
      m.phoneController.dispose();
    }
    super.dispose();
  }

  String get _currencySymbol {
    switch (_currency) {
      case 'USD':
        return '\$';
      case 'SOS':
        return 'Sh';
      default:
        return '£';
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_nameController.text.trim().isEmpty) {
        _showError('Please enter a circle name');
        return;
      }
    } else if (_currentStep == 1) {
      final amount = double.tryParse(_amountController.text.trim());
      if (amount == null || amount <= 0) {
        _showError('Please enter a valid contribution amount');
        return;
      }
    }

    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      context.pop();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _addMember() {
    setState(() {
      _members.add(MemberEntry(
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
            members: membersJson.isEmpty ? null : membersJson,
          );

      ref.invalidate(myGroupsProvider);

      if (mounted) {
        final name = Uri.encodeComponent(_nameController.text.trim());
        context.go('/group-created/$groupId?name=$name');
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to create group: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: _prevStep,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _currentStep == 0
                          ? 'Name your circle'
                          : _currentStep == 1
                              ? 'Set the details'
                              : 'Add members',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '${_currentStep + 1}/$_totalSteps',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),

            // ── Progress bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: List.generate(_totalSteps, (i) {
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 4,
                      margin: EdgeInsets.only(
                          right: i < _totalSteps - 1 ? 6 : 0),
                      decoration: BoxDecoration(
                        color: i <= _currentStep
                            ? AppColors.accent
                            : AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // ── Page content ──
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  StepName(
                    nameController: _nameController,
                    onNext: _nextStep,
                  ),
                  StepDetails(
                    amountController: _amountController,
                    currency: _currency,
                    frequency: _frequency,
                    onCurrencyChanged: (v) => setState(() => _currency = v),
                    onFrequencyChanged: (v) =>
                        setState(() => _frequency = v),
                    onNext: _nextStep,
                  ),
                  StepMembers(
                    members: _members,
                    currencySymbol: _currencySymbol,
                    amount: _amountController.text,
                    groupName: _nameController.text,
                    onAddMember: _addMember,
                    onRemoveMember: _removeMember,
                    onCreateGroup: _createGroup,
                    isLoading: _isLoading,
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
