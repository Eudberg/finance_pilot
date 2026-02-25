import 'package:flutter/material.dart';
import 'package:finance_pilot/data/local/hive_store.dart';
import 'package:finance_pilot/state/app_state.dart';
import 'package:finance_pilot/theme/app_theme.dart';
import 'package:finance_pilot/ui/screens/cycle_checklist_screen.dart';
import 'package:finance_pilot/ui/widgets/level_header.dart';
import 'package:finance_pilot/ui/widgets/primary_button.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveStore.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppState>(
      create: (_) => AppState()..load(),
      child: MaterialApp(
        title: 'Finance Pilot',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const CycleChecklistScreen(),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    const int level = 7;
    const int xp = 350;
    const int nextLevelXp = 500;
    const double progress = xp / nextLevelXp;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance Pilot'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LevelHeader(
              level: level,
              xp: xp,
              nextLevelXp: nextLevelXp,
              progress: progress,
            ),
            const SizedBox(height: 20),
            Text(
              'Badges',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('Iniciante')),
                Chip(label: Text('Meta 7 dias')),
                Chip(label: Text('Foco total')),
              ],
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Continuar',
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
