class JoinRequest {
  final String id;
  final String groupId;
  final String userId;
  final String name;
  final String? phone;
  final String status;
  final DateTime? reviewedAt;
  final DateTime createdAt;

  JoinRequest({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.name,
    this.phone,
    this.status = 'pending',
    this.reviewedAt,
    required this.createdAt,
  });

  factory JoinRequest.fromJson(Map<String, dynamic> json) {
    return JoinRequest(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      status: json['status'] as String? ?? 'pending',
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
}
