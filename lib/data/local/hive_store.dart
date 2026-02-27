import 'package:finance_pilot/domain/models/goal_config.dart';
import 'package:finance_pilot/domain/models/ledger_entry.dart';
import 'package:finance_pilot/domain/models/payroll_deduction.dart';
import 'package:finance_pilot/domain/models/priority_bill.dart';
import 'package:finance_pilot/domain/models/salary_config.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveStore {
  HiveStore._();

  static final HiveStore instance = HiveStore._();

  static const String configBoxName = 'configBox';
  static const String deductionsBoxName = 'deductionsBox';
  static const String billsBoxName = 'billsBox';
  static const String goalsBoxName = 'goalsBox';
  static const String ledgerBoxName = 'ledgerBox';
  static const String offDaysBoxName = 'offDaysBox';

  static const String _salaryConfigKey = 'salaryConfig';
  static const String _deductionsKey = 'deductions';
  static const String _billsKey = 'bills';
  static const String _goalConfigKey = 'goalConfig';
  static const String _goalChecklistStateKey = 'goalChecklistState';
  static const String _notificationsEnabledKey = 'notificationsEnabled';
  static const String _offDaysKey = 'offDays';

  late final Box<dynamic> _configBox;
  late final Box<dynamic> _deductionsBox;
  late final Box<dynamic> _billsBox;
  late final Box<dynamic> _goalsBox;
  late final Box<dynamic> _ledgerBox;
  late final Box<dynamic> _offDaysBox;

  Future<void> init() async {
    await Hive.initFlutter();
    _configBox = await Hive.openBox<dynamic>(configBoxName);
    _deductionsBox = await Hive.openBox<dynamic>(deductionsBoxName);
    _billsBox = await Hive.openBox<dynamic>(billsBoxName);
    _goalsBox = await Hive.openBox<dynamic>(goalsBoxName);
    _ledgerBox = await Hive.openBox<dynamic>(ledgerBoxName);
    _offDaysBox = await Hive.openBox<dynamic>(offDaysBoxName);
  }

  Future<void> saveConfig(SalaryConfig config) async {
    await _configBox.put(_salaryConfigKey, config.toMap());
  }

  SalaryConfig? loadConfig() {
    final dynamic value = _configBox.get(_salaryConfigKey);
    if (value is! Map) {
      return null;
    }
    return SalaryConfig.fromMap(Map<String, dynamic>.from(value));
  }

  Future<void> saveDeductions(List<PayrollDeduction> deductions) async {
    final List<Map<String, dynamic>> serialized = deductions
        .map((item) => item.toMap())
        .toList();
    await _deductionsBox.put(_deductionsKey, serialized);
  }

  List<PayrollDeduction> loadDeductions() {
    final dynamic value = _deductionsBox.get(_deductionsKey, defaultValue: []);
    if (value is! List) {
      return const [];
    }
    return value
        .whereType<Map>()
        .map(
          (item) => PayrollDeduction.fromMap(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<void> saveBills(List<PriorityBill> bills) async {
    final List<Map<String, dynamic>> serialized = bills
        .map((item) => item.toMap())
        .toList();
    await _billsBox.put(_billsKey, serialized);
  }

  List<PriorityBill> loadBills() {
    final dynamic value = _billsBox.get(_billsKey, defaultValue: []);
    if (value is! List) {
      return const [];
    }
    return value
        .whereType<Map>()
        .map((item) => PriorityBill.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> saveGoals(GoalConfig goals) async {
    await _goalsBox.put(_goalConfigKey, goals.toMap());
  }

  GoalConfig? loadGoals() {
    final dynamic value = _goalsBox.get(_goalConfigKey);
    if (value is! Map) {
      return null;
    }
    return GoalConfig.fromMap(Map<String, dynamic>.from(value));
  }

  Future<void> addLedgerEntry(LedgerEntry entry) async {
    await _ledgerBox.put(entry.id, entry.toMap());
  }

  List<LedgerEntry> listLedgerEntries() {
    return _ledgerBox.values
        .whereType<Map>()
        .map((item) => LedgerEntry.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  Map<String, dynamic> loadGoalChecklistState() {
    final dynamic value = _goalsBox.get(
      _goalChecklistStateKey,
      defaultValue: <String, dynamic>{},
    );
    if (value is! Map) {
      return <String, dynamic>{};
    }
    return Map<String, dynamic>.from(value);
  }

  Future<void> saveGoalChecklistState(Map<String, dynamic> state) async {
    await _goalsBox.put(_goalChecklistStateKey, state);
  }

  bool loadNotificationsEnabled() {
    final dynamic value = _configBox.get(
      _notificationsEnabledKey,
      defaultValue: true,
    );
    if (value is bool) {
      return value;
    }
    return true;
  }

  Future<void> saveNotificationsEnabled(bool enabled) async {
    await _configBox.put(_notificationsEnabledKey, enabled);
  }

  Future<Set<String>> loadOffDays() async {
    final dynamic value = _offDaysBox.get(_offDaysKey);
    if (value is Set) {
      return value.whereType<String>().toSet();
    }
    if (value is List) {
      return value.whereType<String>().toSet();
    }
    return <String>{};
  }

  Future<void> toggleOffDay(String dateKey) async {
    final Set<String> offDays = await loadOffDays();
    if (offDays.contains(dateKey)) {
      offDays.remove(dateKey);
    } else {
      offDays.add(dateKey);
    }
    final List<String> sortedList = offDays.toList()..sort();
    await _offDaysBox.put(_offDaysKey, sortedList);
  }
}
