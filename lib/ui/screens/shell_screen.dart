import 'package:flutter/material.dart';
import 'package:finance_pilot/ui/screens/cycle_checklist_screen.dart';
import 'package:finance_pilot/ui/screens/off_days_calendar_screen.dart';
import 'package:finance_pilot/ui/screens/settings_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens = [
    const _HomeTab(),
    const CycleChecklistScreen(),
    const _ObjectivesTab(),
    const _DebtTab(),
    const OffDaysCalendarScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.checklist),
            label: 'Prioridades',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.flag), label: 'Objetivos'),
          BottomNavigationBarItem(
            icon: Icon(Icons.credit_card),
            label: 'Dívidas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendário',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Config'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: const Center(child: Text('Home')),
    );
  }
}

class _ObjectivesTab extends StatelessWidget {
  const _ObjectivesTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Objetivos')),
      body: const Center(child: Text('Objetivos')),
    );
  }
}

class _DebtTab extends StatelessWidget {
  const _DebtTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dívidas')),
      body: const Center(child: Text('Dívidas')),
    );
  }
}
