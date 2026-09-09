import 'package:caminhandojuntos/theme/app_theme.dart';
import 'package:flutter/material.dart';

class StepProgressWidget extends StatelessWidget {
  final int steps;
  final int goalSteps;
  final double progress;

  const StepProgressWidget({
    super.key,
    required this.steps,
    required this.goalSteps,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 220,
          height: 220,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 16,
            backgroundColor: const Color(0xFFE1E8FD),
            color: AppTheme.primaryContainer,
            strokeCap: StrokeCap.round,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.directions_walk,
              color: AppTheme.primaryContainer,
              size: 32,
            ),
            const SizedBox(height: 4),
            Text(
              steps.toString(),
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onSurface,
                  ),
            ),
            Text(
              "de $goalSteps passos",
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 16,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFB1F1C5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "${(progress * 100).toInt()}% concluído",
                style: const TextStyle(
                  color: AppTheme.primaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
