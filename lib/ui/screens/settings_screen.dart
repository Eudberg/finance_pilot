import 'package:finance_pilot/domain/models/payroll_deduction.dart';
import 'package:finance_pilot/state/app_state.dart';
import 'package:finance_pilot/ui/screens/off_days_calendar_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _grossSalaryController = TextEditingController();
  final TextEditingController _advancePctController = TextEditingController();
  final TextEditingController _settlementPctController = TextEditingController();

  final TextEditingController _reserveMinController = TextEditingController();
  final TextEditingController _serasaMinController = TextEditingController();
  final TextEditingController _beerMaxController = TextEditingController();
  final TextEditingController _beerPctController = TextEditingController();

  bool _loaded = false;
  final NumberFormat _currency =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) {
      return;
    }
    final AppState state = context.read<AppState>();
    _syncControllers(state);
    _loaded = true;
  }

  @override
  void dispose() {
    _grossSalaryController.dispose();
    _advancePctController.dispose();
    _settlementPctController.dispose();
    _reserveMinController.dispose();
    _serasaMinController.dispose();
    _beerMaxController.dispose();
    _beerPctController.dispose();
    super.dispose();
  }

  void _syncControllers(AppState state) {
    _grossSalaryController.text = state.config.grossSalary.toStringAsFixed(2);
    _advancePctController.text =
        (state.config.advancePct * 100).toStringAsFixed(2);
    _settlementPctController.text =
        (state.config.settlementPct * 100).toStringAsFixed(2);

    _reserveMinController.text =
        state.goals.reserveMinPerCycle.toStringAsFixed(2);
    _serasaMinController.text = state.goals.serasaMinPerCycle.toStringAsFixed(2);
    _beerMaxController.text = state.goals.beerMaxAbsolute.toStringAsFixed(2);
    _beerPctController.text =
        (state.goals.beerPctOfSafeRemainder * 100).toStringAsFixed(2);
  }

  double? _parseNumber(String value) {
    final String normalized = value.replaceAll(',', '.').trim();
    return double.tryParse(normalized);
  }

  double _parsePercentField(String value) {
    final double parsed = _parseNumber(value) ?? 0;
    if (parsed > 1) {
      return parsed / 100;
    }
    return parsed;
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _saveSalary(AppState state) async {
    final double? grossSalary = _parseNumber(_grossSalaryController.text);
    final double advancePct = _parsePercentField(_advancePctController.text);
    final double settlementPct = _parsePercentField(_settlementPctController.text);

    if (grossSalary == null || grossSalary < 0) {
      _showError('Salario bruto invalido');
      return;
    }
    if (advancePct < 0 || settlementPct < 0) {
      _showError('Percentuais nao podem ser negativos');
      return;
    }

    final double totalPct = advancePct + settlementPct;
    if (totalPct < 0.99 || totalPct > 1.01) {
      _showError('Adiantamento + acerto precisa somar 100%');
      return;
    }

    await state.setSalaryConfig(
      grossSalary: grossSalary,
      advancePct: advancePct,
      settlementPct: settlementPct,
    );

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Salario salvo')),
    );
  }

  Future<void> _saveGoals(AppState state) async {
    final double? reserveMin = _parseNumber(_reserveMinController.text);
    final double? serasaMin = _parseNumber(_serasaMinController.text);
    final double? beerMax = _parseNumber(_beerMaxController.text);
    final double beerPct = _parsePercentField(_beerPctController.text);

    if (reserveMin == null || serasaMin == null || beerMax == null) {
      _showError('Preencha todos os valores das metas');
      return;
    }
    if (reserveMin < 0 || serasaMin < 0 || beerMax < 0 || beerPct < 0) {
      _showError('Valores das metas nao podem ser negativos');
      return;
    }

    await state.setGoalConfig(
      reserveMinPerCycle: reserveMin,
      serasaMinPerCycle: serasaMin,
      beerMaxAbsolute: beerMax,
      beerPctOfSafeRemainder: beerPct,
    );

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Metas salvas')),
    );
  }

  Future<void> _showDeductionDialog(
    BuildContext context,
    AppState state, {
    PayrollDeduction? initial,
  }) async {
    final TextEditingController nameController = TextEditingController(
      text: initial?.name ?? '',
    );
    final TextEditingController amountController = TextEditingController(
      text: initial == null ? '' : initial.amount.toStringAsFixed(2),
    );
    bool active = initial?.active ?? true;
    final BuildContext rootContext = context;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(initial == null ? 'Novo desconto' : 'Editar desconto'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nome'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(labelText: 'Valor'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Ativo'),
                    value: active,
                    onChanged: (value) {
                      setDialogState(() {
                        active = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () async {
                    final String name = nameController.text.trim();
                    final double? amount = _parseNumber(amountController.text);
                    if (name.isEmpty || amount == null || amount <= 0) {
                      if (!mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(rootContext).showSnackBar(
                        const SnackBar(
                          content: Text('Nome e valor validos sao obrigatorios'),
                        ),
                      );
                      return;
                    }

                    if (initial == null) {
                      await state.addPayrollDeduction(
                        name: name,
                        amount: amount,
                        active: active,
                      );
                    } else {
                      await state.updatePayrollDeduction(
                        id: initial.id,
                        name: name,
                        amount: amount,
                        active: active,
                      );
                    }

                    Navigator.of(dialogContext).pop();

                    if (mounted) {
                      ScaffoldMessenger.of(rootContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            initial == null
                                ? 'Desconto salvo'
                                : 'Desconto atualizado',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    amountController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<AppState>(
        builder: (context, state, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SwitchListTile(
                title: const Text('Notificacoes de ciclo'),
                subtitle: const Text('Dia 20 as 09:00 e 5o dia util as 09:00'),
                value: state.notificationsEnabled,
                onChanged: (value) {
                  context.read<AppState>().setNotificationsEnabled(value);
                },
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_month_outlined),
                  title: const Text('Folgas'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const OffDaysCalendarScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Salario e percentuais',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _grossSalaryController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Salario bruto',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _advancePctController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: '% adiantamento (40)',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _settlementPctController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: '% acerto (60)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => _saveSalary(state),
                        child: const Text('Salvar salario'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Descontos na folha',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          IconButton(
                            onPressed: () => _showDeductionDialog(context, state),
                            icon: const Icon(Icons.add),
                            tooltip: 'Adicionar desconto',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (state.deductions.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 8),
                              const Text('Nenhum desconto cadastrado'),
                            ],
                          ),
                        )
                      else
                        ...state.deductions.map(
                          (deduction) => ListTile(
                            key: ValueKey(deduction.id),
                            contentPadding: EdgeInsets.zero,
                            title: Text(deduction.name),
                            subtitle: Text(_currency.format(deduction.amount)),
                            leading: Switch(
                              value: deduction.active,
                              onChanged: (value) async {
                                await context.read<AppState>().updatePayrollDeduction(
                                  id: deduction.id,
                                  name: deduction.name,
                                  amount: deduction.amount,
                                  active: value,
                                );
                              },
                            ),
                            trailing: Wrap(
                              spacing: 4,
                              children: [
                                IconButton(
                                  onPressed: () => _showDeductionDialog(
                                    context,
                                    state,
                                    initial: deduction,
                                  ),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    await context.read<AppState>().removePayrollDeduction(deduction.id);
                                  },
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Metas',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _reserveMinController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Reserva minima por ciclo',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _serasaMinController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Serasa minima por ciclo',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _beerMaxController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Teto cerveja absoluto',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _beerPctController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: '% da sobra segura para cerveja',
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => _saveGoals(state),
                        child: const Text('Salvar metas'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () async {
                  await state.restoreExampleData();
                  _syncControllers(state);
                  if (!mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Dados de exemplo restaurados')),
                  );
                },
                child: const Text('Restaurar dados de exemplo'),
              ),
            ],
          );
        },
      ),
    );
  }
}
