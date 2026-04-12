import 'package:flutter/material.dart';

class ExamBadge {
  final IconData icon;
  final String label;
  final Color color;

  ExamBadge({required this.icon, required this.label, required this.color});
}

class ExamBadgeHelper {
  static ExamBadge getBadge(double score) {
    final s = score.clamp(0.0, 1.0);

    if (s >= 0.9) {
      return ExamBadge(
        icon: Icons.emoji_events,
        label: "Top Scorer",
        color: Colors.amber,
      );
    } else if (s >= 0.8) {
      return ExamBadge(
        icon: Icons.military_tech,
        label: "Distinction",
        color: Colors.orange,
      );
    } else if (s >= 0.7) {
      return ExamBadge(
        icon: Icons.workspace_premium,
        label: "Excellent",
        color: Colors.blue,
      );
    } else if (s >= 0.6) {
      return ExamBadge(
        icon: Icons.stars,
        label: "Very Good",
        color: Colors.green,
      );
    } else {
      return ExamBadge(icon: Icons.grade, label: "Good", color: Colors.grey);
    }
  }
}
