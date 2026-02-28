import 'package:finance_pilot/domain/models/planned_action.dart';
import 'package:finance_pilot/domain/models/goal_config.dart';
import 'package:finance_pilot/domain/models/payroll_deduction.dart';
import 'package:finance_pilot/domain/models/priority_bill.dart';
import 'package:finance_pilot/domain/models/salary_config.dart';

/// Retorna o dia 20 do mês/ano especificado.
DateTime day20Of(int year, int month) {
  return DateTime(year, month, 20);
}

/// Calcula o 5º dia útil (seg-sex) do mês/ano especificado.
/// Ignora feriados (apenas usa dias da semana).
DateTime fifthBusinessDayOf(int year, int month) {
  int businessDaysCount = 0;
  int day = 1;

  while (businessDaysCount < 5) {
    final DateTime current = DateTime(year, month, day);
    final int weekday = current.weekday; // 1=seg, 7=dom

    // Conta se não for fim de semana
    if (weekday >= 1 && weekday <= 5) {
      businessDaysCount++;
      if (businessDaysCount == 5) {
        return current;
      }
    }

    day++;

    // Se ultrapassar 31 dias, retorna o último dia útil encontrado
    if (day > 31) {
      // Volta para o último dia útil válido
      day--;
      while (day > 0) {
        final DateTime fallback = DateTime(year, month, day);
        if (fallback.weekday >= 1 && fallback.weekday <= 5) {
          return fallback;
        }
        day--;
      }
      // Fallback para dia 1 se nada encontrado (unlikely)
      return DateTime(year, month, 1);
    }
  }

  return DateTime(year, month, 1); // Fallback improvável
}

/// Gera plan mensal de ações.
List<PlannedAction> generateMonthlyPlan({
  required int year,
  required int month,
  required SalaryConfig config,
  required List<PayrollDeduction> deductions,
  required List<PriorityBill> bills,
  required GoalConfig goals,
  required Set<String> offDays,
  required double requiredCycle20,
  required double requiredCycle5,
  required double advanceAmount,
  required double settlementAmount,
}) {
  final List<PlannedAction> actions = [];
  int actionCounter = 0;

  String _newId() => 'plan_${year}_${month}_${actionCounter++}';
  String _dateKey(DateTime d) {
    final String y = d.year.toString().padLeft(4, '0');
    final String m = d.month.toString().padLeft(2, '0');
    final String day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  final DateTime d20 = day20Of(year, month);
  final DateTime d5 = fifthBusinessDayOf(year, month);

  // a) INCOME no dia 20
  actions.add(
    PlannedAction(
      id: _newId(),
      date: d20,
      type: PlannedActionType.income,
      title: 'Recebimento (Dia 20)',
      amount: advanceAmount,
      category: 'income',
      mandatory: true,
      status: PlannedActionStatus.pending,
    ),
  );

  // b) INCOME no 5º dia útil
  actions.add(
    PlannedAction(
      id: _newId(),
      date: d5,
      type: PlannedActionType.income,
      title: 'Recebimento (Dia 5)',
      amount: settlementAmount,
      category: 'income',
      mandatory: true,
      status: PlannedActionStatus.pending,
    ),
  );

  // c) PAY para cada PriorityBill ativa
  for (final bill in bills) {
    if (!bill.active) {
      continue;
    }

    DateTime billDate;
    if (bill.dueType == 'day20') {
      billDate = d20;
    } else if (bill.dueType == 'day5') {
      billDate = d5;
    } else if (bill.dueType == 'custom') {
      // Tenta criar data custom dentro do mês
      final int? cd = bill.customDay;
      if (cd == null) {
        billDate = d20;
      } else {
        try {
          billDate = DateTime(year, month, cd);
        } catch (_) {
          billDate = d20;
        }
      }
    } else {
      // Default dia 20
      billDate = d20;
    }

    actions.add(
      PlannedAction(
        id: _newId(),
        date: billDate,
        type: PlannedActionType.pay,
        title: 'Pagar ${bill.name}',
        amount: bill.amount,
        category: 'priority',
        relatedId: bill.id,
        mandatory: true,
        status: PlannedActionStatus.pending,
      ),
    );
  }

  // d) DEPOSIT Reserva no dia 20
  final double reserveDay20 = requiredCycle20 > 0
      ? requiredCycle20
      : goals.reserveMinPerCycle;
  actions.add(
    PlannedAction(
      id: _newId(),
      date: d20,
      type: PlannedActionType.deposit,
      title: 'Depositar Reserva',
      amount: reserveDay20,
      category: 'reserve',
      mandatory: true,
      status: PlannedActionStatus.pending,
    ),
  );

  // e) DEPOSIT Reserva no dia 5
  final double reserveDay5 = requiredCycle5 > 0
      ? requiredCycle5
      : goals.reserveMinPerCycle;
  actions.add(
    PlannedAction(
      id: _newId(),
      date: d5,
      type: PlannedActionType.deposit,
      title: 'Depositar Reserva',
      amount: reserveDay5,
      category: 'reserve',
      mandatory: true,
      status: PlannedActionStatus.pending,
    ),
  );

  // f) DEPOSIT Serasa/Dívidas
  if (goals.serasaMinPerCycle > 0) {
    actions.add(
      PlannedAction(
        id: _newId(),
        date: d20,
        type: PlannedActionType.deposit,
        title: 'Serasa / Dívidas',
        amount: goals.serasaMinPerCycle,
        category: 'serasa',
        mandatory: true,
        status: PlannedActionStatus.pending,
      ),
    );

    actions.add(
      PlannedAction(
        id: _newId(),
        date: d5,
        type: PlannedActionType.deposit,
        title: 'Serasa / Dívidas',
        amount: goals.serasaMinPerCycle,
        category: 'serasa',
        mandatory: true,
        status: PlannedActionStatus.pending,
      ),
    );
  }

  // g) ALLOWANCE para cada dia marcado como folga
  for (final dateKey in offDays) {
    final List<String> parts = dateKey.split('-');
    if (parts.length != 3) {
      continue;
    }

    final int offYear = int.tryParse(parts[0]) ?? 0;
    final int offMonth = int.tryParse(parts[1]) ?? 0;
    final int offDay = int.tryParse(parts[2]) ?? 0;

    // Filtra apenas folgas do mês atual
    if (offYear != year || offMonth != month) {
      continue;
    }

    try {
      final DateTime offDate = DateTime(offYear, offMonth, offDay);
      actions.add(
        PlannedAction(
          id: _newId(),
          date: offDate,
          type: PlannedActionType.allowance,
          title: 'Cerveja (folga)',
          amount: 0.0,
          category: 'beer',
          mandatory: false,
          status: PlannedActionStatus.pending,
          note: 'Só informativo (valor será calculado depois)',
        ),
      );
    } catch (_) {
      // Data inválida, ignora
    }
  }

  return actions;
}
