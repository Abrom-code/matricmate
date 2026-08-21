import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/features/exam/screens/subject/widgets/status_badge.dart';
import 'package:matricmate/features/personalization/controllers/profile_controller.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/app_images.dart';
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
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: dark ? AppColors.darkCard : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? 0.2 : 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
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
                const SizedBox(width: 16),

                // Name / badge / stream
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName.isEmpty ? '—' : user.fullName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: dark
                              ? AppColors.white
                              : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      StatusBadge(status: user.status),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Icon(
                            Iconsax.book_1_copy,
                            size: 13.5,
                            color: dark
                                ? AppColors.darkGrey
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              user.stream.isNotEmpty
                                  ? '${user.stream[0].toUpperCase()}${user.stream.substring(1)} Science'
                                  : 'Stream not set',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: dark
                                    ? AppColors.darkGrey
                                    : AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Iconsax.sms_copy,
                            size: 13.5,
                            color: dark
                                ? AppColors.darkGrey
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              user.email,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: dark
                                    ? AppColors.darkGrey
                                    : AppColors.textSecondary,
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

            const SizedBox(height: 16),
            Divider(
              height: 1,
              thickness: 0.8,
              color: dark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFF1F5F9),
            ),
            const SizedBox(height: 14),

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
                    iconColor: const Color(0xFF0284C7),
                  ),
                  _VerticalDivider(dark: dark),
                  _StatItem(
                    value: '${controller.bookmarkCount.value}',
                    label: 'BOOKMARKS',
                    icon: Iconsax.archive_tick_copy,
                    iconColor: const Color(0xFFF59E0B),
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
    final dark = AppHelperFunctions.isDark(context);
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: dark ? 0.22 : 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(icon, color: iconColor, size: 16),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: dark ? AppColors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: dark ? AppColors.darkGrey : AppColors.textSecondary,
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
      height: 44,
      color: dark
          ? Colors.white.withValues(alpha: 0.08)
          : const Color(0xFFF1F5F9),
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
