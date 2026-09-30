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
    this.icon = Icons.emoji_events,
    this.isUnlocked = false,
    this.dateUnlocked,
    this.progress = 0.0,
    this.progressText,
    this.iconBackgroundColor,
    this.iconColor,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'isUnlocked': isUnlocked,
        'dateUnlocked': dateUnlocked,
        'progress': progress,
        'progressText': progressText,
      };

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      icon: Icons.emoji_events,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      dateUnlocked: json['dateUnlocked'] as String?,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      progressText: json['progressText'] as String?,
    );
  }
}
