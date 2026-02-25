import 'package:finance_pilot/domain/engine/finance_engine.dart';
import 'package:finance_pilot/domain/models/goal_config.dart';
import 'package:finance_pilot/domain/models/payroll_deduction.dart';
import 'package:finance_pilot/domain/models/salary_config.dart';

List<String> runEngineSanity() {
  const SalaryConfig salary = SalaryConfig(grossSalary: 4000);
  const List<PayrollDeduction> deductions = [
    PayrollDeduction(id: '1', name: 'Vale', amount: 100, active: true),
    PayrollDeduction(id: '2', name: 'Plano', amount: 50, active: false),
    PayrollDeduction(id: '3', name: 'Sindicato', amount: 80, active: true),
  ];
  const GoalConfig goals = GoalConfig(
    reserveMinPerCycle: 200,
    serasaMinPerCycle: 120,
    beerMaxAbsolute: 180,
    beerPctOfSafeRemainder: 0.2,
  );

  final double advance = calcAdvance(salary);
  final double settlementBefore = calcSettlementBeforeDeductions(salary);
  final double settlementAfter =
      calcSettlementAfterPayrollDeductions(salary, deductions);
  final double safeRemainder = calcSafeRemainder(
    cash: 1200,
    prioritiesPending: 300,
    reserveMin: goals.reserveMinPerCycle,
    serasaMin: goals.serasaMinPerCycle,
  );
  final double beerAllowance = calcBeerAllowance(goals, safeRemainder);

  return [
    'advance=$advance expected=1600.0',
    'settlementBefore=$settlementBefore expected=2400.0',
    'settlementAfter=$settlementAfter expected=2220.0',
    'safeRemainder=$safeRemainder expected=580.0',
    'beerAllowance=$beerAllowance expected=116.0',
  ];
}
