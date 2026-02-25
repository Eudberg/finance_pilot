enum PriorityBillDueType {
  day20,
  day5,
  customDate,
}

class PriorityBill {
  const PriorityBill({
    required this.id,
    required this.name,
    required this.amount,
    required this.dueType,
    this.customDay,
    required this.active,
  });

  final String id;
  final String name;
  final double amount;
  final PriorityBillDueType dueType;
  final int? customDay;
  final bool active;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'dueType': dueType.name,
      'customDay': customDay,
      'active': active,
    };
  }

  factory PriorityBill.fromMap(Map<String, dynamic> map) {
    final String dueTypeValue =
        map['dueType'] as String? ?? PriorityBillDueType.day20.name;

    return PriorityBill(
      id: map['id'] as String,
      name: map['name'] as String,
      amount: (map['amount'] as num).toDouble(),
      dueType: PriorityBillDueType.values.firstWhere(
        (type) => type.name == dueTypeValue,
        orElse: () => PriorityBillDueType.day20,
      ),
      customDay: (map['customDay'] as num?)?.toInt(),
      active: map['active'] as bool,
    );
  }
}
