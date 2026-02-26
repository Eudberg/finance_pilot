import 'package:finance_pilot/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OffDaysCalendarScreen extends StatefulWidget {
  const OffDaysCalendarScreen({super.key});

  @override
  State<OffDaysCalendarScreen> createState() => _OffDaysCalendarScreenState();
}

class _OffDaysCalendarScreenState extends State<OffDaysCalendarScreen> {
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);

  static const List<String> _monthNames = <String>[
    'Janeiro',
    'Fevereiro',
    'Marco',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  static const List<String> _weekDays = <String>[
    'Seg',
    'Ter',
    'Qua',
    'Qui',
    'Sex',
    'Sab',
    'Dom',
  ];

  String _monthLabel(DateTime month) {
    return '${_monthNames[month.month - 1]} ${month.year}';
  }

  String _dateKey(DateTime date) {
    final String year = date.year.toString().padLeft(4, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final DateTime now = DateTime.now();
    final DateTime firstDay = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final int firstWeekdayOffset = firstDay.weekday - 1;
    final int daysInMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final int itemCount = firstWeekdayOffset + daysInMonth;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Folgas'),
      ),
      body: Consumer<AppState>(
        builder: (context, state, _) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => _changeMonth(-1),
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Expanded(
                          child: Text(
                            _monthLabel(_visibleMonth),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _changeMonth(1),
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.tips_and_updates_outlined,
                          size: 16,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text('Dica: toque no dia para marcar ou remover a folga.'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: _weekDays
                      .map(
                        (label) => Expanded(
                          child: Center(
                            child: Text(
                              label,
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: itemCount,
                    itemBuilder: (context, index) {
                      if (index < firstWeekdayOffset) {
                        return const SizedBox.shrink();
                      }

                      final int day = index - firstWeekdayOffset + 1;
                      final DateTime date = DateTime(_visibleMonth.year, _visibleMonth.month, day);
                      final bool isOffDay = state.offDays.contains(_dateKey(date));
                      final bool isToday = _isSameDay(date, now);

                      return Padding(
                        padding: const EdgeInsets.all(4),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () async {
                            await context.read<AppState>().toggleOffDay(date);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isToday ? colors.primary : colors.outlineVariant,
                              ),
                              color: isOffDay ? colors.primaryContainer : colors.surface,
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Text(
                                    day.toString(),
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: isOffDay
                                              ? colors.onPrimaryContainer
                                              : colors.onSurface,
                                        ),
                                  ),
                                ),
                                if (isOffDay)
                                  Positioned(
                                    right: 6,
                                    top: 6,
                                    child: Icon(
                                      Icons.check_circle,
                                      size: 13,
                                      color: colors.primary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
