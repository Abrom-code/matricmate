import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/appbar/modern_appbar.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/exam/controllers/pilot_exam_controller.dart';
import 'package:matricmate/features/exam/models/pilot_exam_model.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/features/personalization/screens/others/screens/pilot_exam_subjects_screen.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class PilotExamListScreen extends StatefulWidget {
  const PilotExamListScreen({super.key});

  @override
  State<PilotExamListScreen> createState() => _PilotExamListScreenState();
}

class _PilotExamListScreenState extends State<PilotExamListScreen> {
  late final PilotExamController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<PilotExamController>()
        ? Get.find<PilotExamController>()
        : Get.put(PilotExamController());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadPilotExams();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Scaffold(
      backgroundColor: dark ? AppColors.dark : const Color(0xFFF8FAFC),
      appBar: ModernAppbarWithBuilder(
        title: 'Pilot Exam Simulator',
        subtitleBuilder: (_) => Obx(() {
          final stream = UserController.instance.user.value.stream;
          final streamLabel = stream.isNotEmpty
              ? '${stream[0].toUpperCase()}${stream.substring(1)} Stream'
              : 'National Mock Standard';
          return Text(
              streamLabel,
            style: const TextStyle(
              color: Color(0xFFD1FAE5),
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          );
        }),
        showBackArrow: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: 'Refresh Exams',
              onPressed: () => controller.loadPilotExams(),
              icon: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Iconsax.refresh_copy,
                    size: 17,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const AppCircularLoading(title: 'Loading pilot exams...');
        }

        if (controller.pilotExams.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Iconsax.document_text_copy,
                    size: 48,
                    color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No Pilot Exams Available',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: dark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Upcoming national matric pilot exams will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: controller.loadPilotExams,
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.paddingOf(context).bottom + 40,
            ),
            itemCount: controller.pilotExams.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final exam = controller.pilotExams[index];
              return Obx(() {
                final progress = controller.getProgressForExam(exam.id);
                return _PilotExamCard(
                  exam: exam,
                  progress: progress,
                  dark: dark,
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    await controller.selectExam(exam);
                    Get.to(() => const PilotExamSubjectsScreen());
                  },
                );
              });
            },
          ),
        );
      }),
    );
  }
}

class _PilotExamCard extends StatelessWidget {
  const _PilotExamCard({
    required this.exam,
    required this.progress,
    required this.dark,
    required this.onTap,
  });

  final PilotExamModel exam;
  final PilotExamProgress progress;
  final bool dark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: dark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: progress.isCompleted
              ? const Color(0xFF10B981).withValues(alpha: dark ? 0.4 : 0.6)
              : dark
                  ? AppColors.darkBorder
                  : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.25 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Tag Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: dark ? 0.22 : 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        exam.edition,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    if (exam.isPremium) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: dark ? 0.22 : 0.14),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                            width: 0.8,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Iconsax.crown_1_copy,
                              size: 11,
                              color: Color(0xFFD97706),
                            ),
                            SizedBox(width: 3),
                            Text(
                              'PRO',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFD97706),
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),

                    // Progress / Status Badge
                    if (progress.isCompleted) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: dark ? 0.2 : 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'COMPLETED • ${progress.totalScore.toInt()}/600 PTS',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF10B981),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ] else if (progress.isStarted) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: dark ? 0.2 : 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${progress.completedSubjects}/6 DONE • ${progress.totalScore.toInt()}/600',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0284C7),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: dark
                              ? Colors.white.withValues(alpha: 0.08)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '6 SUBJECTS • 600 PTS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0D9488),
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],

                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Title & Description
                Text(
                  exam.title,
                  style: TextStyle(
                    fontSize: 17.5,
                    fontWeight: FontWeight.w800,
                    color: dark ? Colors.white : AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  exam.description.isNotEmpty
                      ? exam.description
                      : 'Authentic 6-subject simulation matching national matric exam criteria.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),

                // Mini Progress Bar if started
                if (progress.isStarted) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress.progressFraction,
                            minHeight: 6,
                            backgroundColor: dark
                                ? Colors.white.withValues(alpha: 0.08)
                                : const Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progress.isCompleted
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF0284C7),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${(progress.progressFraction * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: progress.isCompleted
                              ? const Color(0xFF10B981)
                              : const Color(0xFF0284C7),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // Bottom Action Pill Bar
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  decoration: BoxDecoration(
                    color: progress.isCompleted
                        ? const Color(0xFF10B981).withValues(alpha: dark ? 0.2 : 0.1)
                        : progress.isStarted
                            ? const Color(0xFF0284C7).withValues(alpha: dark ? 0.2 : 0.1)
                            : dark
                                ? const Color(0xFF0F766E).withValues(alpha: 0.2)
                                : const Color(0xFFF0FDFA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: progress.isCompleted
                          ? const Color(0xFF10B981).withValues(alpha: 0.3)
                          : progress.isStarted
                              ? const Color(0xFF0284C7).withValues(alpha: 0.3)
                              : const Color(0xFF0D9488).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        progress.isCompleted
                            ? Iconsax.tick_circle_copy
                            : progress.isStarted
                                ? Iconsax.play_copy
                                : Iconsax.timer_1_copy,
                        size: 16,
                        color: progress.isCompleted
                            ? const Color(0xFF10B981)
                            : progress.isStarted
                                ? const Color(0xFF0284C7)
                                : const Color(0xFF0D9488),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        progress.isCompleted
                            ? 'Review Scorecard & Results'
                            : progress.isStarted
                                ? 'Resume Simulation (${progress.completedSubjects}/6 Done)'
                                : 'Start 6-Subject Simulation',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: progress.isCompleted
                              ? const Color(0xFF10B981)
                              : progress.isStarted
                                  ? const Color(0xFF0284C7)
                                  : const Color(0xFF0D9488),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

