class Group {
  final String id;
  final String organizerId;
  final String name;
  final double contributionAmount;
  final String currency;
  final String frequency;
  final int currentCycle;
  final DateTime? cycleStartedAt;
  final String? whatsappLink;
  final DateTime createdAt;
  final DateTime updatedAt;

  Group({
    required this.id,
    required this.organizerId,
    required this.name,
    required this.contributionAmount,
    required this.currency,
    required this.frequency,
    this.currentCycle = 1,
    this.cycleStartedAt,
    this.whatsappLink,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] as String,
      organizerId: json['organizer_id'] as String,
      name: json['name'] as String,
      contributionAmount:
          (json['contribution_amount'] as num).toDouble(),
      currency: json['currency'] as String,
      frequency: json['frequency'] as String,
      currentCycle: json['current_cycle'] as int? ?? 1,
      cycleStartedAt: json['cycle_started_at'] != null
          ? DateTime.parse(json['cycle_started_at'] as String)
          : null,
      whatsappLink: json['whatsapp_link'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  String get currencySymbol {
    switch (currency) {
      case 'GBP':
        return '£';
      case 'USD':
        return '\$';
      case 'SOS':
        return 'Sh';
      default:
        return currency;
    }
  }

  String get frequencyLabel {
    switch (frequency) {
      case 'weekly':
        return 'Weekly';
      case 'biweekly':
        return 'Bi-weekly';
      case 'monthly':
        return 'Monthly';
      default:
        return frequency;
    }
  }
}

class GroupWithStats {
  final String id;
  final String organizerId;
  final String name;
  final double contributionAmount;
  final String currency;
  final String frequency;
  final int currentCycle;
  final DateTime? cycleStartedAt;
  final String? whatsappLink;
  final int memberCount;
  final double totalPot;
  final int pendingCount;
  final int pendingRequestsCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  GroupWithStats({
    required this.id,
    required this.organizerId,
    required this.name,
    required this.contributionAmount,
    required this.currency,
    required this.frequency,
    this.currentCycle = 1,
    this.cycleStartedAt,
    this.whatsappLink,
    this.memberCount = 0,
    this.totalPot = 0,
    this.pendingCount = 0,
    this.pendingRequestsCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GroupWithStats.fromJson(Map<String, dynamic> json) {
    return GroupWithStats(
      id: json['id'] as String,
      organizerId: json['organizer_id'] as String,
      name: json['name'] as String,
      contributionAmount:
          (json['contribution_amount'] as num).toDouble(),
      currency: json['currency'] as String,
      frequency: json['frequency'] as String,
      currentCycle: json['current_cycle'] as int? ?? 1,
      cycleStartedAt: json['cycle_started_at'] != null
          ? DateTime.parse(json['cycle_started_at'] as String)
          : null,
      whatsappLink: json['whatsapp_link'] as String?,
      memberCount: json['member_count'] as int? ?? 0,
      totalPot: (json['total_pot'] as num?)?.toDouble() ?? 0,
      pendingCount: json['pending_count'] as int? ?? 0,
      pendingRequestsCount:
          json['pending_requests_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  String get currencySymbol {
    switch (currency) {
      case 'GBP':
        return '£';
      case 'USD':
        return '\$';
      case 'SOS':
        return 'Sh';
      default:
        return currency;
    }
  }

  String get frequencyLabel {
    switch (frequency) {
      case 'weekly':
        return 'Weekly';
      case 'biweekly':
        return 'Bi-weekly';
      case 'monthly':
        return 'Monthly';
      default:
        return frequency;
    }
  }
}
