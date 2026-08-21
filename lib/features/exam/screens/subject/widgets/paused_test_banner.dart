import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/exam/controllers/subjects_controller.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

/// A sleek, high-polish banner shown when the student has in-progress / paused tests.
class PausedTestBanner extends StatelessWidget {
  const PausedTestBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = SubjectsController.instance;
    final isDark = AppHelperFunctions.isDark(context);

    return Obx(() {
      final paused = controller.pausedTests;
      if (paused.isEmpty) return const SizedBox.shrink();

      final count = paused.length;
      final latest = paused.first;
      final subjectName =
          latest.subjectName.isNotEmpty ? latest.subjectName : 'Test';
      final testTitle = latest.testTitle.isNotEmpty
          ? latest.testTitle
          : 'In-Progress Exam';

      final cardBg = isDark
          ? const LinearGradient(
              colors: [Color(0xFF151922), Color(0xFF1E2433)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : const LinearGradient(
              colors: [Color(0xFFF0F5FF), Color(0xFFE2ECFD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            );

      final borderColor = isDark
          ? const Color(0xFF2C354D)
          : const Color(0xFFBFD5FB);

      return Container(
        margin: const EdgeInsets.only(top: 6, bottom: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              gradient: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6)
                      .withValues(alpha: isDark ? 0.16 : 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Get.toNamed(Routes.pausedTests),
                child: Stack(
                  children: [
                    // Subtle ambient radial glow in top-right
                    Positioned(
                      right: -24,
                      top: -24,
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF3B82F6)
                                  .withValues(alpha: isDark ? 0.25 : 0.15),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          // ── Icon squircle with active green pulse ──
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF3B82F6),
                                      Color(0xFF1D4ED8),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF3B82F6)
                                          .withValues(alpha: 0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark
                                          ? const Color(0xFF151922)
                                          : Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(width: 14),

                          // ── Text details ──
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF3B82F6)
                                            .withValues(
                                              alpha: isDark ? 0.25 : 0.15,
                                            ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        subjectName.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.4,
                                          color: Color(0xFF3B82F6),
                                        ),
                                      ),
                                    ),
                                    if (count > 1) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        '+${count - 1} more',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? AppColors.darkGrey
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  testTitle,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                    color: isDark
                                        ? AppColors.textWhite
                                        : AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Continue where you left off',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // ── Large Right Chevron Icon ──
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 28,
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
