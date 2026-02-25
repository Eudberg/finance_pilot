import 'package:finance_pilot/domain/models/priority_bill.dart';
import 'package:finance_pilot/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final GlobalKey<FormState> _expenseFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _priorityFormKey = GlobalKey<FormState>();

  final TextEditingController _expenseNameController = TextEditingController();
  final TextEditingController _expenseAmountController = TextEditingController();

  final TextEditingController _priorityNameController = TextEditingController();
  final TextEditingController _priorityAmountController =
      TextEditingController();
  final TextEditingController _customDayController = TextEditingController();

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  DateTime _expenseDate = DateTime.now();
  String _expenseCategory = _categories.first;
  PriorityBillDueType _priorityDueType = PriorityBillDueType.day20;

  static const List<String> _categories = [
    'Lazer',
    'Sa\u00FAde',
    'Transporte',
    'Outros',
    'Serasa',
    'Reserva',
  ];

  @override
  void dispose() {
    _expenseNameController.dispose();
    _expenseAmountController.dispose();
    _priorityNameController.dispose();
    _priorityAmountController.dispose();
    _customDayController.dispose();
    super.dispose();
  }

  double? _parseAmount(String value) {
    final String normalized = value.replaceAll(',', '.').trim();
    return double.tryParse(normalized);
  }

  Future<void> _pickExpenseDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _expenseDate = picked;
    });
  }

  Future<void> _saveExpense() async {
    if (!_expenseFormKey.currentState!.validate()) {
      return;
    }

    final double? amount = _parseAmount(_expenseAmountController.text);
    if (amount == null || amount <= 0) {
      return;
    }

    await context.read<AppState>().addCustomExpense(
          _expenseNameController.text.trim(),
          amount,
          _expenseDate,
          _expenseCategory,
        );

    if (!mounted) {
      return;
    }

    _expenseNameController.clear();
    _expenseAmountController.clear();
    setState(() {
      _expenseDate = DateTime.now();
      _expenseCategory = _categories.first;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Despesa salva')),
    );
  }

  Future<void> _savePriority() async {
    if (!_priorityFormKey.currentState!.validate()) {
      return;
    }

    final double? amount = _parseAmount(_priorityAmountController.text);
    if (amount == null || amount <= 0) {
      return;
    }

    final int? customDay = _priorityDueType == PriorityBillDueType.customDate
        ? int.tryParse(_customDayController.text.trim())
        : null;

    await context.read<AppState>().addPriorityBill(
          name: _priorityNameController.text.trim(),
          amount: amount,
          dueType: _priorityDueType,
          customDay: customDay,
        );

    if (!mounted) {
      return;
    }

    _priorityNameController.clear();
    _priorityAmountController.clear();
    _customDayController.clear();
    setState(() {
      _priorityDueType = PriorityBillDueType.day20;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Prioridade salva')),
    );
  }

  String _dueTypeLabel(PriorityBillDueType dueType) {
    switch (dueType) {
      case PriorityBillDueType.day20:
        return 'Dia 20';
      case PriorityBillDueType.day5:
        return 'Dia 5';
      case PriorityBillDueType.customDate:
        return 'Custom';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _expenseFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nova despesa',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _expenseNameController,
                        decoration: const InputDecoration(
                          labelText: 'Nome',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe o nome';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _expenseAmountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Valor',
                        ),
                        validator: (value) {
                          final double? parsed = _parseAmount(value ?? '');
                          if (parsed == null || parsed <= 0) {
                            return 'Valor invalido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _expenseCategory,
                        decoration: const InputDecoration(
                          labelText: 'Categoria',
                        ),
                        items: _categories
                            .map(
                              (category) => DropdownMenuItem<String>(
                                value: category,
                                child: Text(category),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            _expenseCategory = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _pickExpenseDate,
                        icon: const Icon(Icons.calendar_today),
                        label: Text('Data: ${_dateFormat.format(_expenseDate)}'),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _saveExpense,
                          child: const Text('Salvar despesa'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _priorityFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nova prioridade',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _priorityNameController,
                        decoration: const InputDecoration(
                          labelText: 'Nome',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe o nome';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _priorityAmountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Valor',
                        ),
                        validator: (value) {
                          final double? parsed = _parseAmount(value ?? '');
                          if (parsed == null || parsed <= 0) {
                            return 'Valor invalido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<PriorityBillDueType>(
                        value: _priorityDueType,
                        decoration: const InputDecoration(
                          labelText: 'Vencimento',
                        ),
                        items: PriorityBillDueType.values
                            .map(
                              (dueType) =>
                                  DropdownMenuItem<PriorityBillDueType>(
                                value: dueType,
                                child: Text(_dueTypeLabel(dueType)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            _priorityDueType = value;
                          });
                        },
                      ),
                      if (_priorityDueType == PriorityBillDueType.customDate) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _customDayController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Dia custom (1-31)',
                          ),
                          validator: (value) {
                            if (_priorityDueType !=
                                PriorityBillDueType.customDate) {
                              return null;
                            }
                            final int? day = int.tryParse(value?.trim() ?? '');
                            if (day == null || day < 1 || day > 31) {
                              return 'Dia invalido';
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _savePriority,
                          child: const Text('Salvar prioridade'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

