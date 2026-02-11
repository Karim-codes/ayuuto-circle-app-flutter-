class Payout {
  final String id;
  final String groupId;
  final int cycleNumber;
  final String recipientMemberId;
  final double amount;
  final DateTime paidAt;
  final DateTime createdAt;

  Payout({
    required this.id,
    required this.groupId,
    required this.cycleNumber,
    required this.recipientMemberId,
    required this.amount,
    required this.paidAt,
    required this.createdAt,
  });

  factory Payout.fromJson(Map<String, dynamic> json) {
    return Payout(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      cycleNumber: json['cycle_number'] as int,
      recipientMemberId: json['recipient_member_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      paidAt: DateTime.parse(json['paid_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
