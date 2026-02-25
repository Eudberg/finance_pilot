class PayrollDeduction {
  const PayrollDeduction({
    required this.id,
    required this.name,
    required this.amount,
    required this.active,
  });

  final String id;
  final String name;
  final double amount;
  final bool active;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'active': active,
    };
  }

  factory PayrollDeduction.fromMap(Map<String, dynamic> map) {
    return PayrollDeduction(
      id: map['id'] as String,
      name: map['name'] as String,
      amount: (map['amount'] as num).toDouble(),
      active: map['active'] as bool,
    );
  }
}
