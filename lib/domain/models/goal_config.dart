class GoalConfig {
  const GoalConfig({
    required this.reserveMinPerCycle,
    required this.serasaMinPerCycle,
    required this.beerMaxAbsolute,
    required this.beerPctOfSafeRemainder,
    this.beerMonthlyCap = 0,
  });

  final double reserveMinPerCycle;
  final double serasaMinPerCycle;
  final double beerMaxAbsolute;
  final double beerPctOfSafeRemainder;
  final double beerMonthlyCap;

  Map<String, dynamic> toMap() {
    return {
      'reserveMinPerCycle': reserveMinPerCycle,
      'serasaMinPerCycle': serasaMinPerCycle,
      'beerMaxAbsolute': beerMaxAbsolute,
      'beerPctOfSafeRemainder': beerPctOfSafeRemainder,
      'beerMonthlyCap': beerMonthlyCap,
    };
  }

  factory GoalConfig.fromMap(Map<String, dynamic> map) {
    return GoalConfig(
      reserveMinPerCycle: (map['reserveMinPerCycle'] as num).toDouble(),
      serasaMinPerCycle: (map['serasaMinPerCycle'] as num).toDouble(),
      beerMaxAbsolute: (map['beerMaxAbsolute'] as num).toDouble(),
      beerPctOfSafeRemainder: (map['beerPctOfSafeRemainder'] as num).toDouble(),
      beerMonthlyCap: (map['beerMonthlyCap'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
