import 'package:flutter/material.dart';

class BenefitCardWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color iconBackgroundColor;
  final Color iconColor;

  const BenefitCardWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.iconBackgroundColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isHighContrast = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isHighContrast ? Colors.yellow : iconBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 36,
                color: isHighContrast ? Colors.black : iconColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: isHighContrast ? FontWeight.w600 : FontWeight.normal,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
