import 'package:caminhandojuntos/theme/app_theme.dart';
import 'package:flutter/material.dart';

class DashboardStatsGrid extends StatelessWidget {
  final double distance;
  final int duration;
  final int calories;

  const DashboardStatsGrid({
    super.key,
    required this.distance,
    required this.duration,
    required this.calories,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.straighten,
              value: "${distance.toStringAsFixed(1)} km",
              label: "Distância",
            ),
          ),
          Expanded(
            child: _StatItem(
              icon: Icons.timer,
              value: "$duration min",
              label: "Tempo",
            ),
          ),
          Expanded(
            child: _StatItem(
              icon: Icons.local_fire_department,
              value: "$calories kcal",
              label: "Gasto",
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.secondaryColor, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.onSurface,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
