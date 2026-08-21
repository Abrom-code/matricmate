import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:matricmate/features/personalization/controllers/analytics_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class TestTypeDistribution extends StatelessWidget {
  const TestTypeDistribution({super.key, required this.controller});
  final AnalyticsController controller;

  static const _typeColors = {
    'chapter': AppColors.primary,
    'entrance': Color(0xFF0284C7),
    'model': Color(0xFF10B981),
    'grade': Color(0xFFF59E0B),
  };

  static const _typeLabels = {
    'chapter': 'Chapter Practice',
    'entrance': 'Entrance Exam',
    'model': 'Model Exam',
    'grade': 'Grade Exam',
  };

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    final dist = controller.typeDistribution;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Test Type Distribution',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 14),
          if (dist.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No test distribution data yet',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            Row(
              children: [
                // Donut chart
                SizedBox(
                  width: 110,
                  height: 110,
                  child: CustomPaint(
                    painter: _DonutPainter(dist: dist, colors: _typeColors),
                  ),
                ),
                const SizedBox(width: 18),
                // Legend
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _typeLabels.entries.map((entry) {
                      final key = entry.key;
                      final label = entry.value;
                      final pct = dist[key] ?? 0.0;
                      final color = _typeColors[key] ?? AppColors.grey;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3.5),
                        child: Row(
                          children: [
                            Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: dark
                                      ? AppColors.white
                                      : const Color(0xFF334155),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(
                                  alpha: dark ? 0.2 : 0.1,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${pct.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final Map<String, double> dist;
  final Map<String, Color> colors;

  _DonutPainter({required this.dist, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 18.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    double startAngle = -math.pi / 2;
    const gap = 0.03; // radians gap between segments

    final entries = dist.entries.toList();

    for (final entry in entries) {
      final pct = entry.value / 100;
      final sweep = pct * 2 * math.pi - gap;
      if (sweep <= 0) continue;

      paint.color = colors[entry.key] ?? AppColors.grey;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        paint,
      );
      startAngle += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.dist != dist;
}
