import 'package:finance_pilot/domain/models/ledger_entry.dart';

/// Calcula meses restantes até dezembro.
int monthsRemainingToDec(DateTime now, int year) {
  if (now.year > year) {
    return 0;
  }
  if (now.year < year) {
    return 12 - now.month + 1;
  }
  final int remaining = 12 - now.month;
  return remaining < 0 ? 0 : remaining;
}

/// Calcula depósito mensal necessário para atingir a meta.
/// requiredMonthly = (reserveTarget - reserveCurrent) / monthsRemaining
double requiredMonthlyDeposit(
  double reserveCurrent,
  double reserveTarget,
  int monthsRemaining,
) {
  if (monthsRemaining <= 0) {
    return 0;
  }
  final double delta = (reserveTarget - reserveCurrent).clamp(
    0,
    double.infinity,
  );
  return delta / monthsRemaining;
}

/// Calcula média móvel de depósitos de reserva dos últimos N meses.
/// Filtra categoria 'reserve' ou 'reserve_deposit' com tipo transfer.
double avgMonthlyReserveDeposit(
  List<LedgerEntry> ledger, {
  int lastNMonths = 3,
}) {
  if (ledger.isEmpty) {
    return 0;
  }
  final DateTime now = DateTime.now();
  final DateTime cutoffDate = DateTime(now.year, now.month - lastNMonths, 1);

  final List<LedgerEntry> recentReserveEntries = ledger.where((entry) {
    final bool isReserveCategory =
        entry.category == 'reserve' ||
        entry.category == 'reserve_deposit' ||
        entry.category == 'Reserve';
    final bool isTransfer = entry.type == LedgerEntryType.transfer;
    final bool isRecent = entry.date.isAfter(cutoffDate);
    return isReserveCategory && isTransfer && isRecent;
  }).toList();

  if (recentReserveEntries.isEmpty) {
    return 0;
  }

  final double totalDeposited = recentReserveEntries.fold(
    0.0,
    (sum, entry) => sum + entry.amount,
  );
  return totalDeposited / lastNMonths;
}

/// Prevê saldo de reserva em dezembro baseado na média móvel.
/// forecastAtDec = reserveCurrent + (avgMonthly * monthsRemaining)
double forecastReserveAtDec(
  double reserveCurrent,
  double avgMonthly,
  int monthsRemaining,
) {
  return reserveCurrent + (avgMonthly * monthsRemaining);
}

/// Calcula diferença entre depósito mensal necessário e a média atual.
/// Positivo = precisa aumentar; Negativo = está acima
double deltaMonthlyToHitTarget(double requiredMonthly, double avgMonthly) {
  return requiredMonthly - avgMonthly;
}

/// Distribui depósito mensal entre ciclos (adiantamento + acerto).
/// Proporcional ao cash disponível em cada um.
Map<String, double> splitMonthlyToCycles(
  double monthly,
  double cash20,
  double cash5,
) {
  if (cash20 + cash5 <= 0) {
    return {'cycle20': 0.0, 'cycle5': 0.0};
  }
  final double total = cash20 + cash5;
  final double ratio20 = cash20 / total;
  final double ratio5 = cash5 / total;

  return {'cycle20': monthly * ratio20, 'cycle5': monthly * ratio5};
}
