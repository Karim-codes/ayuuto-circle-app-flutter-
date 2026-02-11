class Profile {
  final String id;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final bool isFoundingMember;
  final int? foundingMemberNumber;
  final String subscriptionTier;
  final DateTime createdAt;
  final DateTime updatedAt;

  Profile({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    this.isFoundingMember = false,
    this.foundingMemberNumber,
    this.subscriptionTier = 'free',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      isFoundingMember: json['is_founding_member'] as bool? ?? false,
      foundingMemberNumber: json['founding_member_number'] as int?,
      subscriptionTier: json['subscription_tier'] as String? ?? 'free',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'avatar_url': avatarUrl,
        'is_founding_member': isFoundingMember,
        'founding_member_number': foundingMemberNumber,
        'subscription_tier': subscriptionTier,
      };

  bool get isPremium =>
      subscriptionTier == 'premium' || isFoundingMember;

  int get maxGroups => isPremium ? 999 : 1;
  int get maxMembersPerGroup => isPremium ? 999 : 7;

  Profile copyWith({
    String? fullName,
    String? avatarUrl,
    String? subscriptionTier,
    bool? isFoundingMember,
    int? foundingMemberNumber,
  }) {
    return Profile(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isFoundingMember: isFoundingMember ?? this.isFoundingMember,
      foundingMemberNumber: foundingMemberNumber ?? this.foundingMemberNumber,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
