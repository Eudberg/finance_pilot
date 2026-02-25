import 'package:finance_pilot/domain/models/goal_config.dart';
import 'package:finance_pilot/domain/models/payroll_deduction.dart';
import 'package:finance_pilot/domain/models/salary_config.dart';

double calcAdvance(SalaryConfig config) {
  return config.grossSalary * config.advancePct;
}

double calcSettlementBeforeDeductions(SalaryConfig config) {
  return config.grossSalary * config.settlementPct;
}

double calcSettlementAfterPayrollDeductions(
  SalaryConfig config,
  List<PayrollDeduction> deductions,
) {
  final double baseSettlement = calcSettlementBeforeDeductions(config);
  final double totalDeductions = deductions
      .where((deduction) => deduction.active)
      .fold(0.0, (sum, deduction) => sum + deduction.amount);
  return baseSettlement - totalDeductions;
}

double calcSafeRemainder({
  required double cash,
  required double prioritiesPending,
  required double reserveMin,
  required double serasaMin,
}) {
  return cash - prioritiesPending - reserveMin - serasaMin;
}

double calcBeerAllowance(GoalConfig config, double safeRemainder) {
  if (safeRemainder <= 0) {
    return 0;
  }

  final double pctLimit = safeRemainder * config.beerPctOfSafeRemainder;
  return pctLimit < config.beerMaxAbsolute ? pctLimit : config.beerMaxAbsolute;
}
