class AnnualPlanConfig {
  AnnualPlanConfig({
    required this.reserveTarget,
    required this.year,
    required this.createdAt,
    required this.updatedAt,
  });

  final double reserveTarget;
  final int year;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory AnnualPlanConfig.defaults() {
    final DateTime now = DateTime.now();
    return AnnualPlanConfig(
      reserveTarget: 2000,
      year: now.year,
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reserveTarget': reserveTarget,
      'year': year,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory AnnualPlanConfig.fromMap(Map<String, dynamic> map) {
    return AnnualPlanConfig(
      reserveTarget: (map['reserveTarget'] as num?)?.toDouble() ?? 2000,
      year: (map['year'] as int?) ?? DateTime.now().year,
      createdAt: map['createdAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : DateTime.now(),
      updatedAt: map['updatedAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int)
          : DateTime.now(),
    );
  }

  AnnualPlanConfig copyWith({
    double? reserveTarget,
    int? year,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AnnualPlanConfig(
      reserveTarget: reserveTarget ?? this.reserveTarget,
      year: year ?? this.year,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
