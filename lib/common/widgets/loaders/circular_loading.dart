import 'package:flutter/material.dart';
import 'package:matricmate/utils/constants/colors.dart';

// ── Full-screen / in-page loader ─────────────────────────────────────────────

class AppCircularLoading extends StatelessWidget {
  const AppCircularLoading({super.key, this.title = 'Loading...'});
  final String title;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppPulsingDots(
              dotSize: 9,
              dotSpacing: 5,
              color: AppColors.primary,
            ),
            if (title.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                  color: dark
                      ? AppColors.white.withValues(alpha: 0.75)
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Pulsing 3 dots (reusable) ──────────────────────────────────────────────────

class AppPulsingDots extends StatefulWidget {
  const AppPulsingDots({
    super.key,
    this.dotSize = 8,
    this.dotSpacing = 4,
    this.color = AppColors.primary,
  });

  final double dotSize;
  final double dotSpacing;
  final Color color;

  @override
  State<AppPulsingDots> createState() => _AppPulsingDotsState();
}

class _AppPulsingDotsState extends State<AppPulsingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final delay = i * 0.2;
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final t = ((_ctrl.value - delay) % 1.0 + 1.0) % 1.0;
            final progress = t < 0.4
                ? (t / 0.4)
                : t < 0.8
                    ? 1.0 - ((t - 0.4) / 0.4)
                    : 0.0;
            final scale = 0.75 + (progress * 0.45);
            final alpha = 0.25 + (progress * 0.75);

            return Transform.scale(
              scale: scale,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: widget.dotSpacing),
                width: widget.dotSize,
                height: widget.dotSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: alpha),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

// ── Small inline button loader ────────────────────────────────────────────────

class AppCircularButtonLoading extends StatelessWidget {
  const AppCircularButtonLoading({
    super.key,
    this.color = Colors.white,
    this.title = 'Loading...',
  });
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppPulsingDots(dotSize: 6, dotSpacing: 3, color: color);
  }
}
