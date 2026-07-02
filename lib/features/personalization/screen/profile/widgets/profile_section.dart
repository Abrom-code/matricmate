import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/image_string.dart';
import 'package:matricmate/utils/constants/sizes.dart';

class ProfileSection extends StatelessWidget {
  const ProfileSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Obx(() {
          final user = UserController.instance.user.value;
          return _StatusAvatar(status: user.status);
        }),
        const SizedBox(height: AppSizes.spaceBtwItems),

        Obx(() {
          final controller = UserController.instance;

          if (controller.userFetching.value) {
            return const CircularProgressIndicator();
          }

          final user = controller.user.value;

          if (user.id.isEmpty) {
            return const Text(
              'No user data',
              style: TextStyle(color: Colors.grey),
            );
          }

          return Column(
            children: [
              Text(
                '${user.firstName} ${user.lastName}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                user.email,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          );
        }),
      ],
    );
  }
}

class _StatusAvatar extends StatelessWidget {
  const _StatusAvatar({required this.status});
  final String status;

  // Ring gradient colours per status (matches AppbarStatusTitle palette)
  List<Color> get _ringColors {
    switch (status) {
      case 'active':
        return [const Color(0xFF1DE9B6), const Color(0xFF76FF03)];
      case 'pending':
        return [const Color(0xFFFFD54F), const Color(0xFFFF8F00)];
      default: // inactive / free
        return [AppColors.grey, AppColors.darkGrey];
    }
  }

  // Badge label & colours
  String get _badgeLabel {
    switch (status) {
      case 'active':  return 'PREMIUM';
      case 'pending': return 'PENDING';
      default:        return 'FREE';
    }
  }

  Color get _badgeBg {
    switch (status) {
      case 'active':  return const Color(0xFFD4F542);
      case 'pending': return const Color(0xFFFFD54F);
      default:        return AppColors.grey;
    }
  }

  Color get _badgeText {
    switch (status) {
      case 'active':  return const Color(0xFF2E5A00);
      case 'pending': return const Color(0xFF6B3A00);
      default:        return AppColors.darkerGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    const double avatarSize = 100;
    const double ringWidth  = 4;
    const double gapWidth   = 3;
    const double totalSize  = avatarSize + (ringWidth + gapWidth) * 2;

    return SizedBox(
      width: totalSize,
      height: totalSize + 14, // extra room for the badge overlap
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Gradient ring
          CustomPaint(
            size: const Size(totalSize, totalSize),
            painter: _GradientRingPainter(
              colors: _ringColors,
              ringWidth: ringWidth,
              gap: gapWidth,
            ),
          ),

          // Avatar clipped to circle, inset by ring + gap
          Positioned(
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

          // Badge overlapping the bottom
          Positioned(
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              decoration: BoxDecoration(
                color: _badgeBg,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                _badgeLabel,
                style: TextStyle(
                  color: _badgeText,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Draws a gradient arc ring around the avatar with a small white gap.
class _GradientRingPainter extends CustomPainter {
  const _GradientRingPainter({
    required this.colors,
    required this.ringWidth,
    required this.gap,
  });

  final List<Color> colors;
  final double ringWidth;
  final double gap;

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
        startAngle: 0,
        endAngle: 3.14159 * 2,
      ).createShader(rect);

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_GradientRingPainter old) =>
      old.colors != colors || old.ringWidth != ringWidth;
}
