class Payment {
  final String id;
  final String groupId;
  final String memberId;
  final int cycleNumber;
  final double amount;
  final DateTime paymentDate;
  final DateTime? voidedAt;
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.groupId,
    required this.memberId,
    required this.cycleNumber,
    required this.amount,
    required this.paymentDate,
    this.voidedAt,
    required this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      memberId: json['member_id'] as String,
      cycleNumber: json['cycle_number'] as int,
      amount: (json['amount'] as num).toDouble(),
      paymentDate: DateTime.parse(json['payment_date'] as String),
      voidedAt: json['voided_at'] != null
          ? DateTime.parse(json['voided_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get isActive => voidedAt == null;
}
