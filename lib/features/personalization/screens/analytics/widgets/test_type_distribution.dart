import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:matricmate/features/personalization/controllers/analytics_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class TestTypeDistribution extends StatelessWidget {
  const TestTypeDistribution({super.key, required this.controller});
  final AnalyticsController controller;

  static const _typeColors = {
    'chapter': AppColors.primary,
    'entrance': AppColors.info,
    'model': AppColors.success,
    'grade': AppColors.warning,
  };

  static const _typeLabels = {
    'chapter': 'Chapter',
    'entrance': 'Entrance',
    'model': 'Model',
    'grade': 'Grade',
  };

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    final dist = controller.typeDistribution;

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            spreadRadius: -2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Test type distribution',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSizes.spaceBtwItems),
          if (dist.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No data yet', style: TextStyle(color: AppColors.textSecondary)),
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
                const SizedBox(width: AppSizes.spaceBtwItems),
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
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                label,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Text(
                              '${pct.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
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
