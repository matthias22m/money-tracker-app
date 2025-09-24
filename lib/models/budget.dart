class Budget {
  final String id;
  final double amount;
  final int year;
  final int month;
  final DateTime createdAt;
  final DateTime updatedAt;

  Budget({
    required this.id,
    required this.amount,
    required this.year,
    required this.month,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      year: map['year'] ?? DateTime.now().year,
      month: map['month'] ?? DateTime.now().month,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'year': year,
      'month': month,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  Budget copyWith({
    String? id,
    double? amount,
    int? year,
    int? month,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Budget(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      year: year ?? this.year,
      month: month ?? this.month,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper method to get month name
  String get monthName {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  // Helper method to get formatted date
  String get formattedDate => '$monthName $year';

  // Helper method to get days remaining in month
  int get daysRemaining {
    final now = DateTime.now();
    final lastDayOfMonth = DateTime(year, month + 1, 0);
    return lastDayOfMonth.difference(now).inDays + 1;
  }
}
