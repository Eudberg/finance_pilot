import 'dart:math' as math;

import 'package:finance_pilot/domain/agent/goal_agent.dart';
import 'package:finance_pilot/domain/models/priority_bill.dart';
import 'package:finance_pilot/state/app_state.dart';
import 'package:finance_pilot/ui/screens/add_expense_screen.dart';
import 'package:finance_pilot/ui/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CycleChecklistScreen extends StatelessWidget {
  const CycleChecklistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Checklist do Ciclo'),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SettingsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.settings),
              tooltip: 'Settings',
            ),
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AddExpenseScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              tooltip: 'Adicionar',
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Dia 20'),
              Tab(text: 'Dia 5'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _CycleTabContent(
              title: 'Dia 20',
              dueType: PriorityBillDueType.day20,
            ),
            _CycleTabContent(title: 'Dia 5', dueType: PriorityBillDueType.day5),
          ],
        ),
      ),
    );
  }
}

class _CycleTabContent extends StatelessWidget {
  const _CycleTabContent({required this.title, required this.dueType});

  final String title;
  final PriorityBillDueType dueType;

  @override
  Widget build(BuildContext context) {
    final NumberFormat currency = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    return Consumer<AppState>(
      builder: (context, state, _) {
        final bool isDay20 = dueType == PriorityBillDueType.day20;
        final CycleType cycleType = isDay20 ? CycleType.day20 : CycleType.day5;
        final String cycleBucket = buildGoalChecklistBucket(
          cycleType,
          DateTime.now(),
        );
        final List<String> generatedGoals = generateActionableGoals(
          state,
          cycleType,
        );
        final double cash = isDay20
            ? state.advanceAmount
            : state.settlementAmount;
        final List<PriorityBill> cycleBills = state.bills.where((bill) {
          if (!bill.active) {
            return false;
          }
          if (bill.dueType == dueType) {
            return true;
          }
          return bill.dueType == PriorityBillDueType.customDate &&
              ((isDay20 && bill.customDay == 20) ||
                  (!isDay20 && bill.customDay == 5));
        }).toList();

        final double prioritiesPending = cycleBills.fold(
          0.0,
          (sum, bill) => sum + bill.amount,
        );

        final double beerAllowance = state.beerAllowanceToday;

        final double cyclePool = math.max(cash - prioritiesPending, 0.0);
        final double reserveProgress = state.goals.reserveMinPerCycle <= 0
            ? 1.0
            : math.min(cyclePool / state.goals.reserveMinPerCycle, 1.0);
        final double afterReserve = math.max(
          cyclePool - state.goals.reserveMinPerCycle,
          0.0,
        );
        final double serasaProgress = state.goals.serasaMinPerCycle <= 0
            ? 1.0
            : math.min(afterReserve / state.goals.serasaMinPerCycle, 1.0);

        String blockedReason = '';
        if (beerAllowance <= 0) {
          if (!state.isTodayOffDay) {
            blockedReason = 'Sem cerveja hoje: não é folga';
          } else if (cash <= prioritiesPending) {
            blockedReason = 'prioridades do ciclo consomem todo o caixa';
          } else if (cash <=
              prioritiesPending + state.goals.reserveMinPerCycle) {
            blockedReason = 'reserva minima ainda nao atingida';
          } else if (cash <=
              prioritiesPending +
                  state.goals.reserveMinPerCycle +
                  state.goals.serasaMinPerCycle) {
            blockedReason = 'meta Serasa minima ainda nao atingida';
          } else {
            blockedReason = 'sem margem segura neste ciclo';
          }
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Metas sugeridas',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...generatedGoals.map(
              (goal) => _AnimatedCycleCard(
                child: Card(
                  child: CheckboxListTile(
                    value: state.isGoalDone(
                      cycleBucket: cycleBucket,
                      goal: goal,
                    ),
                    onChanged: (value) {
                      context.read<AppState>().setGoalDone(
                        cycleBucket: cycleBucket,
                        goal: goal,
                        done: value ?? false,
                      );
                    },
                    title: Text(goal),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _AnimatedCycleCard(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Quanto cai: ${currency.format(cash)}',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Prioridades a pagar',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (cycleBills.isEmpty)
              _AnimatedCycleCard(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(Icons.celebration_outlined, size: 28),
                        SizedBox(height: 8),
                        Text('Nenhuma prioridade ativa neste ciclo.'),
                      ],
                    ),
                  ),
                ),
              )
            else
              ...cycleBills.map(
                (bill) => _AnimatedCycleCard(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bill.name,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 4),
                                Text(currency.format(bill.amount)),
                              ],
                            ),
                          ),
                          FilledButton.tonal(
                            onPressed: () {
                              context.read<AppState>().markBillPaid(bill.id);
                            },
                            child: const Text('Marcar como pago'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              'Metas do ciclo',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            _AnimatedCycleCard(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _GoalProgressRow(
                        label: 'Reserva minima',
                        current: math.min(
                          cyclePool,
                          state.goals.reserveMinPerCycle,
                        ),
                        target: state.goals.reserveMinPerCycle,
                        progress: reserveProgress,
                        formatter: currency,
                      ),
                      const SizedBox(height: 12),
                      _GoalProgressRow(
                        label: 'Serasa minima',
                        current: math.min(
                          afterReserve,
                          state.goals.serasaMinPerCycle,
                        ),
                        target: state.goals.serasaMinPerCycle,
                        progress: serasaProgress,
                        formatter: currency,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Diversao',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (state.goals.beerMonthlyCap > 0) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cerveja no mes: ${currency.format(state.beerSpentThisMonth)} / ${currency.format(state.goals.beerMonthlyCap)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        'Folgas restantes: ${state.offDaysRemainingThisMonth}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            _AnimatedCycleCard(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: beerAllowance > 0
                      ? Text(
                          'Pode ate ${currency.format(beerAllowance)}',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        )
                      : Text(
                          'Hoje nao pode: $blockedReason',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GoalProgressRow extends StatelessWidget {
  const _GoalProgressRow({
    required this.label,
    required this.current,
    required this.target,
    required this.progress,
    required this.formatter,
  });

  final String label;
  final double current;
  final double target;
  final double progress;
  final NumberFormat formatter;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.titleSmall),
            ),
            Text('${formatter.format(current)} / ${formatter.format(target)}'),
          ],
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 500),
          tween: Tween<double>(begin: 0, end: progress),
          builder: (context, value, _) {
            return LinearProgressIndicator(value: value, minHeight: 10);
          },
        ),
      ],
    );
  }
}

class _AnimatedCycleCard extends StatelessWidget {
  const _AnimatedCycleCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 280),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, value, _) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 8 * (1 - value)),
            child: child,
          ),
        );
      },
    );
  }
}
