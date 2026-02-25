class SalaryConfig {
  const SalaryConfig({
    required this.grossSalary,
    this.advancePct = 0.4,
    this.settlementPct = 0.6,
  });

  final double grossSalary;
  final double advancePct;
  final double settlementPct;

  Map<String, dynamic> toMap() {
    return {
      'grossSalary': grossSalary,
      'advancePct': advancePct,
      'settlementPct': settlementPct,
    };
  }

  factory SalaryConfig.fromMap(Map<String, dynamic> map) {
    return SalaryConfig(
      grossSalary: (map['grossSalary'] as num).toDouble(),
      advancePct: (map['advancePct'] as num?)?.toDouble() ?? 0.4,
      settlementPct: (map['settlementPct'] as num?)?.toDouble() ?? 0.6,
    );
  }
}
