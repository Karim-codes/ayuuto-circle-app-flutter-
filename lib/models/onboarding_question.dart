class OnboardingQuestion {
  final String id;
  final String title;
  final String? subtitle;
  final List<String> options;
  final bool isMultiSelect;

  const OnboardingQuestion({
    required this.id,
    required this.title,
    this.subtitle,
    required this.options,
    this.isMultiSelect = false,
  });
}
