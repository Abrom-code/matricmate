import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/features/personalization/controllers/profile_controller.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/image_string.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class ProfileSection extends StatelessWidget {
  const ProfileSection({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Obx(() {
      final user = UserController.instance.user.value;
      final controller = Get.find<ProfileController>();

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: dark ? AppColors.darkCard : AppColors.white,
          borderRadius: BorderRadius.circular(AppSizes.lg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 16,
              spreadRadius: -2,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Top row: avatar + info ──────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _StatusAvatar(status: user.status),
                const SizedBox(width: AppSizes.md),

                // Name / badge / stream
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName.isEmpty ? '—' : user.fullName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      _StatusBadge(status: user.status),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Iconsax.book_1_copy,
                            size: 13,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              user.stream.isNotEmpty
                                  ? '${user.stream[0].toUpperCase()}${user.stream.substring(1)} Science'
                                  : 'Stream not set',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Iconsax.sms_copy,
                            size: 13,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              user.email,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSizes.spaceBtwItems),
            Divider(
              height: 1,
              color: dark
                  ? AppColors.darkerGrey.withValues(alpha: 0.5)
                  : AppColors.grey,
            ),
            const SizedBox(height: AppSizes.spaceBtwItems),

            // ── Stats row ──────────────────────────────────────────
            Obx(
              () => Row(
                children: [
                  _StatItem(
                    value: '${controller.completedTest.value}',
                    label: 'TESTS',
                    icon: Iconsax.task_square_copy,
                    iconColor: AppColors.primary,
                  ),
                  _VerticalDivider(dark: dark),
                  _StatItem(
                    value:
                        '${controller.avgScorePct.value.toStringAsFixed(0)}%',
                    label: 'AVG SCORE',
                    icon: Iconsax.chart_copy,
                    iconColor: AppColors.info,
                  ),
                  _VerticalDivider(dark: dark),
                  _StatItem(
                    value: '${controller.bookmarkCount.value}',
                    label: 'BOOKMARKS',
                    icon: Iconsax.archive_tick_copy,
                    iconColor: AppColors.warning,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ── Status ring avatar (same painter as before, smaller) ────────────────────

class _StatusAvatar extends StatelessWidget {
  const _StatusAvatar({required this.status});
  final String status;

  List<Color> get _ringColors {
    switch (status) {
      case 'active':
        return [const Color(0xFF1DE9B6), const Color(0xFF76FF03)];
      case 'pending':
        return [const Color(0xFFFFD54F), const Color(0xFFFF8F00)];
      default:
        return [AppColors.grey, AppColors.darkGrey];
    }
  }

  @override
  Widget build(BuildContext context) {
    const double avatarSize = 78;
    const double ringWidth = 3.5;
    const double gapWidth = 2.5;
    const double totalSize = avatarSize + (ringWidth + gapWidth) * 2;

    return SizedBox(
      width: totalSize,
      height: totalSize,
      child: Stack(
        children: [
          CustomPaint(
            size: const Size(totalSize, totalSize),
            painter: _GradientRingPainter(
              colors: _ringColors,
              ringWidth: ringWidth,
            ),
          ),
          const Positioned(
            top: ringWidth + gapWidth,
            left: ringWidth + gapWidth,
            child: const ClipOval(
              child: Image(
                image: AssetImage(AppImages.unknownUser),
                width: avatarSize,
                height: avatarSize,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Inline status badge ──────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  String get _label {
    switch (status) {
      case 'active':
        return 'PREMIUM';
      case 'pending':
        return 'PENDING';
      default:
        return 'FREE';
    }
  }

  Color get _bg {
    switch (status) {
      case 'active':
        return const Color(0xFFD4F542);
      case 'pending':
        return const Color(0xFFFFD54F);
      default:
        return AppColors.grey;
    }
  }

  Color get _fg {
    switch (status) {
      case 'active':
        return const Color(0xFF2E5A00);
      case 'pending':
        return const Color(0xFF6B3A00);
      default:
        return AppColors.darkerGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: _fg,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

// ── Single stat cell ─────────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 0.8,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider({required this.dark});
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: dark
          ? AppColors.darkerGrey.withValues(alpha: 0.5)
          : AppColors.grey,
    );
  }
}

// ── Gradient ring painter ────────────────────────────────────────────────────

class _GradientRingPainter extends CustomPainter {
  const _GradientRingPainter({required this.colors, required this.ringWidth});
  final List<Color> colors;
  final double ringWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - ringWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth
      ..shader = SweepGradient(
        colors: [...colors, colors.first],
      ).createShader(rect);

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_GradientRingPainter old) =>
      old.colors != colors || old.ringWidth != ringWidth;
}
