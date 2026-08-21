import 'package:flutter/material.dart';
import 'package:matricmate/features/personalization/controllers/analytics_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class ScoreTrendChart extends StatelessWidget {
  const ScoreTrendChart({super.key, required this.controller});
  final AnalyticsController controller;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    final points = controller.trendPoints;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Score Trend',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              if (points.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(
                      alpha: dark ? 0.2 : 0.1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Avg: ${controller.avgScorePct.value.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 130,
            child: points.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.show_chart_rounded,
                          size: 32,
                          color: dark
                              ? AppColors.darkGrey
                              : const Color(0xFFCBD5E1),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Complete tests to see your score trajectory',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : CustomPaint(
                    size: const Size(double.infinity, 130),
                    painter: _LinePainter(points: points),
                  ),
          ),
          if (points.isNotEmpty) ...[
            const SizedBox(height: 8),
            // X-axis labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TEST 1',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                  ),
                ),
                if (points.length > 2)
                  Text(
                    'LAST ${points.length} TESTS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color:
                          dark ? AppColors.darkGrey : AppColors.textSecondary,
                    ),
                  ),
                Text(
                  'TEST ${points.length}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
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
      final y =
          size.height -
          ((p.score - minScore) / range * (size.height * 0.85) +
              size.height * 0.05);
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
