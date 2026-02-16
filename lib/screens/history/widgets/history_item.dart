enum HistoryType { contribution, payout }

class HistoryItem {
  final HistoryType type;
  final String groupName;
  final double amount;
  final String currency;
  final int cycleNumber;
  final DateTime date;
  final String? recipientName;
  final bool isCurrentUser;

  HistoryItem({
    required this.type,
    required this.groupName,
    required this.amount,
    required this.currency,
    required this.cycleNumber,
    required this.date,
    this.recipientName,
    this.isCurrentUser = false,
  });

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
}
