import 'package:flutter/material.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool isUnlocked;
  final String? dateUnlocked;
  final double progress;
  final String? progressText;
  final Color? iconBackgroundColor;
  final Color? iconColor;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.isUnlocked = false,
    this.dateUnlocked,
    this.progress = 0.0,
    this.progressText,
    this.iconBackgroundColor,
    this.iconColor,
  });
}
