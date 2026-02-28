import 'package:finance_pilot/data/local/hive_store.dart';
import 'package:finance_pilot/data/local/notification_service.dart';
import 'package:finance_pilot/domain/engine/finance_engine.dart';
import 'package:finance_pilot/domain/engine/forecast_engine.dart';
import 'package:finance_pilot/domain/engine/planner_engine.dart';
import 'package:finance_pilot/domain/models/annual_plan_config.dart';
import 'package:finance_pilot/domain/models/goal_config.dart';
import 'package:finance_pilot/domain/models/ledger_entry.dart';
import 'package:finance_pilot/domain/models/payroll_deduction.dart';
import 'package:finance_pilot/domain/models/planned_action.dart';
import 'package:finance_pilot/domain/models/priority_bill.dart';
import 'package:finance_pilot/domain/models/salary_config.dart';
import 'package:flutter/foundation.dart';

enum CashViewMode { advance, settlement }

class AppState extends ChangeNotifier {
  AppState({HiveStore? store}) : _store = store ?? HiveStore.instance;

  final HiveStore _store;

  SalaryConfig _config = const SalaryConfig(grossSalary: 0);
  List<PayrollDeduction> _deductions = const [];
  List<PriorityBill> _bills = const [];
  GoalConfig _goals = const GoalConfig(
    reserveMinPerCycle: 0,
    serasaMinPerCycle: 0,
    beerMaxAbsolute: 0,
    beerPctOfSafeRemainder: 0,
  );
  List<LedgerEntry> _ledger = const [];
  Map<String, Map<String, bool>> _goalChecklistState =
      const <String, Map<String, bool>>{};
  Set<String> _offDays = const <String>{};
  bool _notificationsEnabled = true;
  CashViewMode _cashViewMode = CashViewMode.settlement;
  AnnualPlanConfig _annualPlan = AnnualPlanConfig.defaults();

  SalaryConfig get config => _config;
  List<PayrollDeduction> get deductions => List.unmodifiable(_deductions);
  List<PriorityBill> get bills => List.unmodifiable(_bills);
  GoalConfig get goals => _goals;
  List<LedgerEntry> get ledger => List.unmodifiable(_ledger);
  Set<String> get offDays => Set.unmodifiable(_offDays);
  bool get notificationsEnabled => _notificationsEnabled;
  CashViewMode get cashViewMode => _cashViewMode;
  AnnualPlanConfig get annualPlan => _annualPlan;

  double get advanceAmount => calcAdvance(_config);

  double get settlementAmount =>
      calcSettlementAfterPayrollDeductions(_config, _deductions);

  /// Saldo atual de reserva (soma todas as entradas com categoria 'reserve').
  double get reserveCurrent {
    return _ledger
        .where(
          (entry) =>
              entry.category == 'reserve' ||
              entry.category == 'reserve_deposit' ||
              entry.category == 'Reserve',
        )
        .fold(0.0, (sum, entry) => sum + entry.amount);
  }

  /// Cash disponível no adiantamento (20º).
  double get cash20 => advanceAmount;

  /// Cash disponível no acerto (5º).
  double get cash5 => settlementAmount;

  /// Meses restantes até dezembro do ano da meta anual.
  int get monthsRemaining =>
      monthsRemainingToDec(DateTime.now(), _annualPlan.year);

  /// Média móvel mensal de depósitos de reserva (últimos 3 meses).
  double get avgMonthlyDeposit => avgMonthlyReserveDeposit(_ledger);

  /// Previsão de saldo em dezembro.
  double get forecastAtDec =>
      forecastReserveAtDec(reserveCurrent, avgMonthlyDeposit, monthsRemaining);

  /// Depósito mensal necessário para atingir a meta.
  double get requiredMonthly => requiredMonthlyDeposit(
    reserveCurrent,
    _annualPlan.reserveTarget,
    monthsRemaining,
  );

  /// Ciclo de depósito necessário, distribuído proporcionalmente.
  Map<String, double> get requiredCycles =>
      splitMonthlyToCycles(requiredMonthly, cash20, cash5);

  /// Depósito necessário no adiantamento (20º).
  double get requiredCycle20 => requiredCycles['cycle20'] ?? 0.0;

  /// Depósito necessário no acerto (5º).
  double get requiredCycle5 => requiredCycles['cycle5'] ?? 0.0;

  /// Ano atual.
  int get currentYear => DateTime.now().year;

  /// Mês atual.
  int get currentMonth => DateTime.now().month;

  /// Plano mensal de ações (gerado deterministicamente).
  List<PlannedAction> get monthlyPlan => generateMonthlyPlan(
    year: currentYear,
    month: currentMonth,
    config: _config,
    deductions: _deductions,
    bills: _bills,
    goals: _goals,
    offDays: _offDays,
    requiredCycle20: requiredCycle20,
    requiredCycle5: requiredCycle5,
    advanceAmount: advanceAmount,
    settlementAmount: settlementAmount,
  );

  String dateKeyOf(DateTime d) {
    final String year = d.year.toString().padLeft(4, '0');
    final String month = d.month.toString().padLeft(2, '0');
    final String day = d.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  bool get isTodayOffDay => _offDays.contains(dateKeyOf(DateTime.now()));

  double get beerSpentThisMonth {
    final DateTime now = DateTime.now();
    final int currentMonth = now.month;
    final int currentYear = now.year;
    return _ledger
        .where((entry) {
          if (entry.date.month != currentMonth ||
              entry.date.year != currentYear) {
            return false;
          }
          return entry.category == 'lazer' || entry.category == 'Cerveja';
        })
        .fold(0.0, (sum, entry) => sum + entry.amount);
  }

  int get offDaysRemainingThisMonth {
    final DateTime now = DateTime.now();
    final int currentMonth = now.month;
    final int currentYear = now.year;
    return _offDays.where((dateKey) {
      final List<String> parts = dateKey.split('-');
      if (parts.length != 3) {
        return false;
      }
      final int year = int.tryParse(parts[0]) ?? 0;
      final int month = int.tryParse(parts[1]) ?? 0;
      final int day = int.tryParse(parts[2]) ?? 0;
      if (year != currentYear || month != currentMonth) {
        return false;
      }
      final DateTime dateOfOffDay = DateTime(year, month, day);
      return dateOfOffDay.isAfter(now) ||
          (dateOfOffDay.day == now.day &&
              dateOfOffDay.month == now.month &&
              dateOfOffDay.year == now.year);
    }).length;
  }

  double get beerAllowanceToday {
    if (!isTodayOffDay) {
      return 0.0;
    }
    final double cash = _cashViewMode == CashViewMode.advance
        ? advanceAmount
        : settlementAmount;
    final double prioritiesPending = _bills
        .where((bill) => bill.active)
        .fold(0.0, (sum, bill) => sum + bill.amount);
    final double safeRemainder = calcSafeRemainder(
      cash: cash,
      prioritiesPending: prioritiesPending,
      reserveMin: _goals.reserveMinPerCycle,
      serasaMin: _goals.serasaMinPerCycle,
    );
    final double safeBasedAllowance = calcBeerAllowance(_goals, safeRemainder);

    if (_goals.beerMonthlyCap <= 0) {
      return safeBasedAllowance;
    }

    final double monthlyRemaining = (_goals.beerMonthlyCap - beerSpentThisMonth)
        .clamp(0.0, double.infinity);
    final int offDaysRemaining = offDaysRemainingThisMonth.clamp(1, 999);
    final double rateLimit = monthlyRemaining / offDaysRemaining;

    return [
      _goals.beerMaxAbsolute,
      safeBasedAllowance,
      rateLimit,
    ].reduce((a, b) => a < b ? a : b);
  }

  String get beerReasonToday {
    return isTodayOffDay ? 'OK' : 'Hoje não é folga';
  }

  Future<void> load() async {
    final SalaryConfig? loadedConfig = _store.loadConfig();
    final GoalConfig? loadedGoals = _store.loadGoals();
    final AnnualPlanConfig? loadedAnnualPlan = _store.loadAnnualPlanConfig();

    _config = loadedConfig ?? _config;
    _deductions = _store.loadDeductions();
    _bills = _store.loadBills();
    _goals = loadedGoals ?? _goals;
    _ledger = _store.listLedgerEntries();
    _offDays = await _store.loadOffDays();
    _notificationsEnabled = _store.loadNotificationsEnabled();
    _annualPlan = loadedAnnualPlan ?? AnnualPlanConfig.defaults();
    await NotificationService.instance.scheduleCycleReminders(
      enabled: _notificationsEnabled,
    );
    final Map<String, dynamic> rawChecklistState = _store
        .loadGoalChecklistState();
    final Map<String, Map<String, bool>> parsedChecklistState = {};
    rawChecklistState.forEach((bucket, value) {
      if (value is! Map) {
        return;
      }
      final Map<String, bool> perGoal = {};
      value.forEach((goalKey, doneValue) {
        if (goalKey is String && doneValue is bool) {
          perGoal[goalKey] = doneValue;
        }
      });
      parsedChecklistState[bucket] = perGoal;
    });
    _goalChecklistState = parsedChecklistState;
    notifyListeners();
  }

  void setCashViewMode(CashViewMode mode) {
    if (_cashViewMode == mode) {
      return;
    }
    _cashViewMode = mode;
    notifyListeners();
  }

  Future<void> setReserveTarget(double value) async {
    _annualPlan = _annualPlan.copyWith(
      reserveTarget: value,
      updatedAt: DateTime.now(),
    );
    await _store.saveAnnualPlanConfig(_annualPlan);
    notifyListeners();
  }

  Future<void> markBillPaid(String id) async {
    bool updated = false;
    PriorityBill? paidBill;
    final List<PriorityBill> nextBills = _bills.map((bill) {
      if (bill.id != id || !bill.active) {
        return bill;
      }
      updated = true;
      paidBill = bill;
      return PriorityBill(
        id: bill.id,
        name: bill.name,
        amount: bill.amount,
        dueType: bill.dueType,
        customDay: bill.customDay,
        active: false,
      );
    }).toList();

    if (!updated) {
      return;
    }

    _bills = nextBills;
    await _store.saveBills(_bills);
    if (paidBill != null) {
      final LedgerEntry entry = LedgerEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        date: DateTime.now(),
        type: LedgerEntryType.expense,
        category: 'priority_bill',
        amount: paidBill!.amount,
        note: 'Pagamento: ${paidBill!.name}',
      );
      await _store.addLedgerEntry(entry);
      _ledger = [..._ledger, entry];
    }
    notifyListeners();
  }

  Future<void> addCustomExpense(
    String name,
    double amount,
    DateTime date,
    String category,
  ) async {
    final LedgerEntry entry = LedgerEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      date: date,
      type: LedgerEntryType.expense,
      category: category,
      amount: amount,
      note: name,
    );

    await _store.addLedgerEntry(entry);
    _ledger = [..._ledger, entry];
    notifyListeners();
  }

  Future<void> addPriorityBill({
    required String name,
    required double amount,
    required PriorityBillDueType dueType,
    int? customDay,
  }) async {
    final PriorityBill bill = PriorityBill(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      amount: amount,
      dueType: dueType,
      customDay: dueType == PriorityBillDueType.customDate ? customDay : null,
      active: true,
    );

    _bills = [..._bills, bill];
    await _store.saveBills(_bills);
    notifyListeners();
  }

  Future<void> setSalaryConfig({
    required double grossSalary,
    required double advancePct,
    required double settlementPct,
  }) async {
    _config = SalaryConfig(
      grossSalary: grossSalary,
      advancePct: advancePct,
      settlementPct: settlementPct,
    );
    await _store.saveConfig(_config);
    notifyListeners();
  }

  Future<void> addPayrollDeduction({
    required String name,
    required double amount,
    bool active = true,
  }) async {
    final PayrollDeduction deduction = PayrollDeduction(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      amount: amount,
      active: active,
    );
    _deductions = [..._deductions, deduction];
    await _store.saveDeductions(_deductions);
    notifyListeners();
  }

  Future<void> updatePayrollDeduction({
    required String id,
    required String name,
    required double amount,
    required bool active,
  }) async {
    _deductions = _deductions.map((deduction) {
      if (deduction.id != id) {
        return deduction;
      }
      return PayrollDeduction(
        id: deduction.id,
        name: name,
        amount: amount,
        active: active,
      );
    }).toList();
    await _store.saveDeductions(_deductions);
    notifyListeners();
  }

  Future<void> removePayrollDeduction(String id) async {
    _deductions = _deductions.where((deduction) => deduction.id != id).toList();
    await _store.saveDeductions(_deductions);
    notifyListeners();
  }

  Future<void> setGoalConfig({
    required double reserveMinPerCycle,
    required double serasaMinPerCycle,
    required double beerMaxAbsolute,
    required double beerPctOfSafeRemainder,
    double beerMonthlyCap = 0,
  }) async {
    _goals = GoalConfig(
      reserveMinPerCycle: reserveMinPerCycle,
      serasaMinPerCycle: serasaMinPerCycle,
      beerMaxAbsolute: beerMaxAbsolute,
      beerPctOfSafeRemainder: beerPctOfSafeRemainder,
      beerMonthlyCap: beerMonthlyCap,
    );
    await _store.saveGoals(_goals);
    notifyListeners();
  }

  bool isGoalDone({required String cycleBucket, required String goal}) {
    return _goalChecklistState[cycleBucket]?[goal] ?? false;
  }

  Future<void> setGoalDone({
    required String cycleBucket,
    required String goal,
    required bool done,
  }) async {
    final Map<String, bool> currentBucket = Map<String, bool>.from(
      _goalChecklistState[cycleBucket] ?? {},
    );
    currentBucket[goal] = done;
    _goalChecklistState = {..._goalChecklistState, cycleBucket: currentBucket};

    final Map<String, dynamic> serialized = {};
    _goalChecklistState.forEach((bucket, value) {
      serialized[bucket] = Map<String, bool>.from(value);
    });
    await _store.saveGoalChecklistState(serialized);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    await _store.saveNotificationsEnabled(enabled);
    await NotificationService.instance.scheduleCycleReminders(enabled: enabled);
    notifyListeners();
  }

  // ✅ FIX: notificar antes do await para UI reagir imediatamente.
  Future<void> toggleOffDay(DateTime date) async {
    final String dateKey = dateKeyOf(date);

    final Set<String> nextOffDays = Set<String>.from(_offDays);
    if (nextOffDays.contains(dateKey)) {
      nextOffDays.remove(dateKey);
    } else {
      nextOffDays.add(dateKey);
    }
    _offDays = nextOffDays;

    // Notifica já para o calendário "pintar" na hora.
    notifyListeners();

    // Persistência depois. Se falhar, ao menos o feedback já aconteceu.
    try {
      await _store.toggleOffDay(dateKey);
    } catch (_) {
      // opcional: registrar log / reverter. Mantido simples.
    }
  }

  Future<void> restoreExampleData() async {
    _config = const SalaryConfig(
      grossSalary: 4500,
      advancePct: 0.4,
      settlementPct: 0.6,
    );
    _deductions = const [
      PayrollDeduction(
        id: 'example-1',
        name: 'Plano de saúde',
        amount: 220,
        active: true,
      ),
      PayrollDeduction(
        id: 'example-2',
        name: 'Vale transporte',
        amount: 180,
        active: true,
      ),
    ];
    _goals = const GoalConfig(
      reserveMinPerCycle: 300,
      serasaMinPerCycle: 250,
      beerMaxAbsolute: 120,
      beerPctOfSafeRemainder: 0.15,
      beerMonthlyCap: 500,
    );

    await _store.saveConfig(_config);
    await _store.saveDeductions(_deductions);
    await _store.saveGoals(_goals);
    notifyListeners();
  }
}
