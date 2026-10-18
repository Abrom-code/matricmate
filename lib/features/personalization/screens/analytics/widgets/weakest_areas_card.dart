import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/controllers/navigation_controller.dart';
import 'package:matricmate/features/exam/controllers/subjects_controller.dart';
import 'package:matricmate/features/exam/models/subject_model.dart';
import 'package:matricmate/features/exam/screens/subject/widgets/subject_mode_modal.dart';
import 'package:matricmate/features/personalization/controllers/analytics_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class WeakestAreasCard extends StatelessWidget {
  const WeakestAreasCard({super.key, required this.controller});
  final AnalyticsController controller;

  static const double targetScore = 75.0;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    final areas = controller.weakestAreas;

    if (areas.isEmpty) return const SizedBox.shrink();

    // Deep amber & warm gold palette
    final alertColor = dark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
    final alertBorderColor = dark ? const Color(0xFFF59E0B) : const Color(0xFFD97706);
    final alertBadgeBg = dark
        ? const Color(0xFFF59E0B).withValues(alpha: 0.20)
        : const Color(0xFFF59E0B).withValues(alpha: 0.12);
    final alertLinkColor = dark ? const Color(0xFFFDE68A) : const Color(0xFFB45309);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: alertBorderColor.withValues(alpha: dark ? 0.35 : 0.22),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: alertBorderColor.withValues(alpha: dark ? 0.12 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Row ────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: alertBorderColor.withValues(
                    alpha: dark ? 0.22 : 0.12,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(
                    Iconsax.radar_copy,
                    color: alertColor,
                    size: 19,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Priority Focus Alert',
                          style: TextStyle(
                            color: alertColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: alertBadgeBg,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            '${areas.length} Focus',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: alertColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Close the score gap to reach the 75% exam readiness target',
                      style: TextStyle(
                        color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Subject Gap List ──────────────────────────────────────────────
          ...areas.map((area) {
            final gap = (targetScore - area.avgScore).clamp(0.0, 100.0);
            final currentPct = area.avgScore.clamp(0.0, 100.0);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: dark
                    ? Colors.white.withValues(alpha: 0.02)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: dark
                      ? AppColors.darkBorder
                      : const Color(0xFFE2E8F0),
                  width: 0.8,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Subject Initial Avatar
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: alertBadgeBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            area.name.isNotEmpty ? area.name[0] : 'S',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: alertColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Subject Name & Practice Count
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              area.name,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: dark ? AppColors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              '${area.testsCount > 0 ? "${area.testsCount} tests completed" : "Requires practice"}',
                              style: TextStyle(
                                fontSize: 11,
                                color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Gap Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: alertBadgeBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '-${gap.toStringAsFixed(0)}% Gap',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: alertColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Quick Practice Button
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          SubjectModel? targetSubject;
                          final subjectsCtrl =
                              Get.isRegistered<SubjectsController>()
                                  ? SubjectsController.instance
                                  : Get.put(SubjectsController());
                          final subjects = subjectsCtrl.subjects;
                          targetSubject = subjects.firstWhereOrNull(
                            (s) =>
                                (area.subjectId != null &&
                                    s.id == area.subjectId) ||
                                s.name.trim().toLowerCase() ==
                                    area.name.trim().toLowerCase(),
                          );

                          if (targetSubject != null) {
                            SubjectModeModal.show(context, targetSubject);
                          } else {
                            Get.until((route) => route.isFirst);
                            if (Get.isRegistered<NavigationController>()) {
                              NavigationController.instance.changePage(0);
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(
                              alpha: dark ? 0.2 : 0.08,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Practice',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 13,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Progress Bar + Accuracy Label
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: currentPct / 100,
                      minHeight: 6,
                      backgroundColor: dark
                          ? Colors.white.withValues(alpha: 0.07)
                          : const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        dark ? const Color(0xFFF59E0B) : const Color(0xFFD97706),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Accuracy: ${currentPct.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: alertColor,
                        ),
                      ),
                      Text(
                        'Target: 75%',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),

          // ── Bottom Link ───────────────────────────────────────────────────
          InkWell(
            onTap: () {
              Get.until((route) => route.isFirst);
              if (Get.isRegistered<NavigationController>()) {
                NavigationController.instance.changePage(0);
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Practice subjects & take tests',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: alertLinkColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 13,
                    color: alertLinkColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
