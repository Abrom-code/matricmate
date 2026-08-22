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

    double maxScore = 0;
    if (points.isNotEmpty) {
      maxScore = points.map((p) => p.score).reduce((a, b) => a > b ? a : b);
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header & Peak Badge ─────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Score Trajectory',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: dark ? AppColors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Performance progression across attempts',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (points.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(
                      alpha: dark ? 0.22 : 0.1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.trending_up_rounded,
                        size: 15,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Peak: ${maxScore.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),

          // ── Chart Canvas ────────────────────────────────────────────
          SizedBox(
            height: 140,
            child: points.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withValues(
                              alpha: dark ? 0.15 : 0.08,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.show_chart_rounded,
                              size: 22,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Complete tests to view your score trajectory',
                          style: TextStyle(
                            color: dark
                                ? AppColors.darkGrey
                                : AppColors.textSecondary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : CustomPaint(
                    size: const Size(double.infinity, 140),
                    painter: _LinePainter(points: points, dark: dark),
                  ),
          ),

          if (points.isNotEmpty) ...[
            const SizedBox(height: 10),
            // X-axis Timeline Labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'FIRST ATTEMPT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                  ),
                ),
                if (points.length > 2)
                  Text(
                    'RECENT ${points.length} TESTS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color:
                          dark ? AppColors.darkGrey : AppColors.textSecondary,
                    ),
                  ),
                Text(
                  'LATEST TEST',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
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
  final bool dark;

  _LinePainter({required this.points, required this.dark});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final minScore = points.map((p) => p.score).reduce((a, b) => a < b ? a : b);
    final maxScore = points.map((p) => p.score).reduce((a, b) => a > b ? a : b);
    final range = (maxScore - minScore).clamp(5.0, 100.0);

    Offset toOffset(TrendPoint p) {
      final x = p.index / (points.length - 1) * size.width;
      final y =
          size.height -
          ((p.score - minScore) / range * (size.height * 0.75) +
              size.height * 0.12);
      return Offset(x, y);
    }

    // Grid baseline lines (2 horizontal guidelines)
    final gridPaint = Paint()
      ..color = dark
          ? Colors.white.withValues(alpha: 0.05)
          : const Color(0xFFE2E8F0)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height * 0.25),
      Offset(size.width, size.height * 0.25),
      gridPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.75),
      Offset(size.width, size.height * 0.75),
      gridPaint,
    );

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
          AppColors.primary.withValues(alpha: dark ? 0.35 : 0.22),
          AppColors.primary.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    // Draw Smooth Line
    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3.0
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
        fillPath.cubicTo(cpx, prev.dy, cpx, o.dy, o.dx, o.dy);
        linePath.cubicTo(cpx, prev.dy, cpx, o.dy, o.dx, o.dy);
      }
    }
    canvas.drawPath(linePath, linePaint);

    // Draw dots for intermediate and latest point
    final pointPaint = Paint()..color = AppColors.primary;
    final centerPaint = Paint()..color = Colors.white;

    for (int i = 0; i < points.length; i++) {
      final o = toOffset(points[i]);
      if (i == points.length - 1) {
        // Glowing halo on latest attempt
        canvas.drawCircle(
          o,
          9,
          Paint()..color = AppColors.primary.withValues(alpha: 0.25),
        );
        canvas.drawCircle(o, 6, pointPaint);
        canvas.drawCircle(o, 3.5, centerPaint);
      } else if (points.length <= 8) {
        canvas.drawCircle(o, 3.5, pointPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.points != points || old.dark != dark;
}
