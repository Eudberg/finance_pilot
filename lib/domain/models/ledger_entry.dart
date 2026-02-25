enum LedgerEntryType {
  income,
  expense,
  transfer,
}

class LedgerEntry {
  const LedgerEntry({
    required this.id,
    required this.date,
    required this.type,
    required this.category,
    required this.amount,
    required this.note,
  });

  final String id;
  final DateTime date;
  final LedgerEntryType type;
  final String category;
  final double amount;
  final String note;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'type': type.name,
      'category': category,
      'amount': amount,
      'note': note,
    };
  }

  factory LedgerEntry.fromMap(Map<String, dynamic> map) {
    final String typeValue =
        map['type'] as String? ?? LedgerEntryType.expense.name;

    return LedgerEntry(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      type: LedgerEntryType.values.firstWhere(
        (entryType) => entryType.name == typeValue,
        orElse: () => LedgerEntryType.expense,
      ),
      category: map['category'] as String,
      amount: (map['amount'] as num).toDouble(),
      note: map['note'] as String,
    );
  }
}
