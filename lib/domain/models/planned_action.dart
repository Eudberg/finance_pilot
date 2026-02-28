enum PlannedActionType { income, pay, deposit, allowance, alert }

enum PlannedActionStatus { pending, done, skipped }

class PlannedAction {
  PlannedAction({
    required this.id,
    required this.date,
    required this.type,
    required this.title,
    required this.amount,
    required this.category,
    this.relatedId,
    required this.mandatory,
    required this.status,
    this.note,
  });

  final String id;
  final DateTime date;
  final PlannedActionType type;
  final String title;
  final double amount;
  final String category;
  final String? relatedId;
  final bool mandatory;
  final PlannedActionStatus status;
  final String? note;

  PlannedAction copyWith({PlannedActionStatus? status, String? note}) {
    return PlannedAction(
      id: id,
      date: date,
      type: type,
      title: title,
      amount: amount,
      category: category,
      relatedId: relatedId,
      mandatory: mandatory,
      status: status ?? this.status,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.millisecondsSinceEpoch,
      'type': type.name,
      'title': title,
      'amount': amount,
      'category': category,
      'relatedId': relatedId,
      'mandatory': mandatory,
      'status': status.name,
      'note': note,
    };
  }

  factory PlannedAction.fromMap(Map<String, dynamic> map) {
    return PlannedAction(
      id: map['id'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      type: PlannedActionType.values.firstWhere(
        (t) => t.name == (map['type'] as String),
        orElse: () => PlannedActionType.alert,
      ),
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      relatedId: map['relatedId'] as String?,
      mandatory: map['mandatory'] as bool? ?? false,
      status: PlannedActionStatus.values.firstWhere(
        (s) => s.name == (map['status'] as String),
        orElse: () => PlannedActionStatus.pending,
      ),
      note: map['note'] as String?,
    );
  }
}
