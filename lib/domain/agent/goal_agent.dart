import 'package:finance_pilot/domain/engine/finance_engine.dart';
import 'package:finance_pilot/domain/models/priority_bill.dart';
import 'package:finance_pilot/state/app_state.dart';

enum CycleType { day20, day5 }

List<String> generateActionableGoals(AppState state, CycleType cycle) {
  final bool isDay20 = cycle == CycleType.day20;
  final double cash = isDay20 ? state.advanceAmount : state.settlementAmount;
  final List<PriorityBill> bills = state.bills.where((bill) {
    if (!bill.active) {
      return false;
    }
    if (cycle == CycleType.day20) {
      return bill.dueType == PriorityBillDueType.day20 ||
          (bill.dueType == PriorityBillDueType.customDate &&
              bill.customDay == 20);
    }
    return bill.dueType == PriorityBillDueType.day5 ||
        (bill.dueType == PriorityBillDueType.customDate && bill.customDay == 5);
  }).toList();

  final double prioritiesPending = bills.fold(
    0.0,
    (sum, bill) => sum + bill.amount,
  );
  final double safeRemainder = calcSafeRemainder(
    cash: cash,
    prioritiesPending: prioritiesPending,
    reserveMin: state.goals.reserveMinPerCycle,
    serasaMin: state.goals.serasaMinPerCycle,
  );

  final List<String> goals = [];

  for (final PriorityBill bill in bills.take(2)) {
    goals.add('Pague ${bill.name} (${_money(bill.amount)})');
  }

  goals.add('Separe ${_money(state.goals.reserveMinPerCycle)} para Reserva');
  goals.add('Separe ${_money(state.goals.serasaMinPerCycle)} para Serasa');

  if (state.beerAllowanceToday > 0) {
    goals.add('Hoje cervejinha: ate ${_money(state.beerAllowanceToday)}');
  } else {
    goals.add('Sem cerveja hoje: ${state.beerReasonToday}');
  }

  final double extraSave = safeRemainder > 0 ? (safeRemainder * 0.5) : 0.0;
  if (extraSave > 0) {
    goals.add('Se sobrar, guarde ${_money(extraSave)}');
  }

  if (goals.length < 3) {
    goals.add('Feche o ciclo sem novas despesas');
  }

  return goals.take(6).toList();
}

String buildGoalChecklistBucket(CycleType cycle, DateTime date) {
  final String month = date.month.toString().padLeft(2, '0');
  return '${date.year}-$month-${cycle.name}';
}

String _money(double value) {
  return 'R\$${value.toStringAsFixed(2).replaceAll('.', ',')}';
}
