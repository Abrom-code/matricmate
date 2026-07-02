import 'package:flutter/material.dart';
import 'package:matricmate/features/personalization/controller/analytics_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class ScoreTrendChart extends StatelessWidget {
  const ScoreTrendChart({super.key, required this.controller});
  final AnalyticsController controller;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    final points = controller.trendPoints;

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: dark ? AppColors.black : AppColors.white,
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
            'Score trend',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSizes.spaceBtwItems),
          SizedBox(
            height: 130,
            child: points.isEmpty
                ? const Center(
                    child: Text(
                      'No data yet',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : CustomPaint(
                    size: const Size(double.infinity, 130),
                    painter: _LinePainter(points: points),
                  ),
          ),
          const SizedBox(height: AppSizes.sm),
          // X-axis labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                points.isNotEmpty ? 'TEST 1' : '',
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
              Text(
                points.length > 2 ? 'LAST ${points.length} TESTS' : '',
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
              Text(
                points.isNotEmpty ? 'TEST ${points.length}' : '',
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<TrendPoint> points;
  _LinePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final minScore = points.map((p) => p.score).reduce((a, b) => a < b ? a : b);
    final maxScore = points.map((p) => p.score).reduce((a, b) => a > b ? a : b);
    final range = (maxScore - minScore).clamp(1.0, 100.0);

    Offset toOffset(TrendPoint p) {
      final x = p.index / (points.length - 1) * size.width;
      final y = size.height - ((p.score - minScore) / range * (size.height * 0.85) + size.height * 0.05);
      return Offset(x, y);
    }

    // Fill area under line
    final fillPath = Path();
    fillPath.moveTo(0, size.height);
    for (int i = 0; i < points.length; i++) {
      final o = toOffset(points[i]);
      if (i == 0) {
        fillPath.lineTo(o.dx, o.dy);
      } else {
        final prev = toOffset(points[i - 1]);
        final cpx = (prev.dx + o.dx) / 2;
        fillPath.cubicTo(cpx, prev.dy, cpx, o.dy, o.dx, o.dy);
      }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withValues(alpha: 0.2),
          AppColors.primary.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    // Draw line
    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final linePath = Path();
    for (int i = 0; i < points.length; i++) {
      final o = toOffset(points[i]);
      if (i == 0) {
        linePath.moveTo(o.dx, o.dy);
      } else {
        final prev = toOffset(points[i - 1]);
        final cpx = (prev.dx + o.dx) / 2;
        linePath.cubicTo(cpx, prev.dy, cpx, o.dy, o.dx, o.dy);
      }
    }
    canvas.drawPath(linePath, linePaint);

    // Draw dot at last point
    final last = toOffset(points.last);
    canvas.drawCircle(last, 5, Paint()..color = AppColors.primary);
    canvas.drawCircle(last, 3, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_LinePainter old) => old.points != points;
}
