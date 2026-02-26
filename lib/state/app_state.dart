import 'package:finance_pilot/data/local/hive_store.dart';
import 'package:finance_pilot/data/local/notification_service.dart';
import 'package:finance_pilot/domain/engine/finance_engine.dart';
import 'package:finance_pilot/domain/models/goal_config.dart';
import 'package:finance_pilot/domain/models/ledger_entry.dart';
import 'package:finance_pilot/domain/models/payroll_deduction.dart';
import 'package:finance_pilot/domain/models/priority_bill.dart';
import 'package:finance_pilot/domain/models/salary_config.dart';
import 'package:flutter/foundation.dart';

enum CashViewMode {
  advance,
  settlement,
}

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

  SalaryConfig get config => _config;
  List<PayrollDeduction> get deductions => List.unmodifiable(_deductions);
  List<PriorityBill> get bills => List.unmodifiable(_bills);
  GoalConfig get goals => _goals;
  List<LedgerEntry> get ledger => List.unmodifiable(_ledger);
  Set<String> get offDays => Set.unmodifiable(_offDays);
  bool get notificationsEnabled => _notificationsEnabled;
  CashViewMode get cashViewMode => _cashViewMode;

  double get advanceAmount => calcAdvance(_config);

  double get settlementAmount =>
      calcSettlementAfterPayrollDeductions(_config, _deductions);

  double get beerAllowanceToday {
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
    return calcBeerAllowance(_goals, safeRemainder);
  }

  Future<void> load() async {
    final SalaryConfig? loadedConfig = _store.loadConfig();
    final GoalConfig? loadedGoals = _store.loadGoals();

    _config = loadedConfig ?? _config;
    _deductions = _store.loadDeductions();
    _bills = _store.loadBills();
    _goals = loadedGoals ?? _goals;
    _ledger = _store.listLedgerEntries();
    _offDays = await _store.loadOffDays();
    _notificationsEnabled = _store.loadNotificationsEnabled();
    await NotificationService.instance.scheduleCycleReminders(
      enabled: _notificationsEnabled,
    );
    final Map<String, dynamic> rawChecklistState =
        _store.loadGoalChecklistState();
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
  }) async {
    _goals = GoalConfig(
      reserveMinPerCycle: reserveMinPerCycle,
      serasaMinPerCycle: serasaMinPerCycle,
      beerMaxAbsolute: beerMaxAbsolute,
      beerPctOfSafeRemainder: beerPctOfSafeRemainder,
    );
    await _store.saveGoals(_goals);
    notifyListeners();
  }

  bool isGoalDone({
    required String cycleBucket,
    required String goal,
  }) {
    return _goalChecklistState[cycleBucket]?[goal] ?? false;
  }

  Future<void> setGoalDone({
    required String cycleBucket,
    required String goal,
    required bool done,
  }) async {
    final Map<String, bool> currentBucket =
        Map<String, bool>.from(_goalChecklistState[cycleBucket] ?? {});
    currentBucket[goal] = done;
    _goalChecklistState = {
      ..._goalChecklistState,
      cycleBucket: currentBucket,
    };

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

  Future<void> toggleOffDay(DateTime date) async {
    final String year = date.year.toString().padLeft(4, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    final String dateKey = '$year-$month-$day';

    final Set<String> nextOffDays = Set<String>.from(_offDays);
    if (nextOffDays.contains(dateKey)) {
      nextOffDays.remove(dateKey);
    } else {
      nextOffDays.add(dateKey);
    }
    _offDays = nextOffDays;
    await _store.toggleOffDay(dateKey);
    notifyListeners();
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
        name: 'Plano de saude',
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
    );

    await _store.saveConfig(_config);
    await _store.saveDeductions(_deductions);
    await _store.saveGoals(_goals);
    notifyListeners();
  }
}
