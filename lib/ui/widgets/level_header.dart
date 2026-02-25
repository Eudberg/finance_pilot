import 'package:flutter/material.dart';
import 'package:finance_pilot/ui/widgets/stat_card.dart';

class LevelHeader extends StatelessWidget {
  const LevelHeader({
    super.key,
    required this.level,
    required this.xp,
    required this.nextLevelXp,
    required this.progress,
  });

  final int level;
  final int xp;
  final int nextLevelXp;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Nivel',
                    value: '$level',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    label: 'XP',
                    value: '$xp / $nextLevelXp',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              minHeight: 12,
            ),
          ],
        ),
      ),
    );
  }
}
