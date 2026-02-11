class Member {
  final String id;
  final String groupId;
  final String name;
  final String? phone;
  final String? userId;
  final int payoutPosition;
  final bool hasReceivedPayout;
  final double totalPaid;
  final bool isOrganiser;
  final DateTime createdAt;

  Member({
    required this.id,
    required this.groupId,
    required this.name,
    this.phone,
    this.userId,
    required this.payoutPosition,
    this.hasReceivedPayout = false,
    this.totalPaid = 0,
    this.isOrganiser = false,
    required this.createdAt,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      userId: json['user_id'] as String?,
      payoutPosition: json['payout_position'] as int,
      hasReceivedPayout: json['has_received_payout'] as bool? ?? false,
      totalPaid: (json['total_paid'] as num?)?.toDouble() ?? 0,
      isOrganiser: json['is_organiser'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'payout_position': payoutPosition,
      };
}
