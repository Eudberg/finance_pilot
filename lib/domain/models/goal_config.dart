class GoalConfig {
  const GoalConfig({
    required this.reserveMinPerCycle,
    required this.serasaMinPerCycle,
    required this.beerMaxAbsolute,
    required this.beerPctOfSafeRemainder,
  });

  final double reserveMinPerCycle;
  final double serasaMinPerCycle;
  final double beerMaxAbsolute;
  final double beerPctOfSafeRemainder;

  Map<String, dynamic> toMap() {
    return {
      'reserveMinPerCycle': reserveMinPerCycle,
      'serasaMinPerCycle': serasaMinPerCycle,
      'beerMaxAbsolute': beerMaxAbsolute,
      'beerPctOfSafeRemainder': beerPctOfSafeRemainder,
    };
  }

  factory GoalConfig.fromMap(Map<String, dynamic> map) {
    return GoalConfig(
      reserveMinPerCycle: (map['reserveMinPerCycle'] as num).toDouble(),
      serasaMinPerCycle: (map['serasaMinPerCycle'] as num).toDouble(),
      beerMaxAbsolute: (map['beerMaxAbsolute'] as num).toDouble(),
      beerPctOfSafeRemainder:
          (map['beerPctOfSafeRemainder'] as num).toDouble(),
    );
  }
}
