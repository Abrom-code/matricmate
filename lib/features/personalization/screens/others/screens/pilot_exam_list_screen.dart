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
  DateTime _lastTapTime = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<PilotExamController>()
        ? Get.find<PilotExamController>()
        : Get.put(PilotExamController());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.pilotExams.isEmpty) {
        controller.loadPilotExams();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Scaffold(
      backgroundColor: dark ? AppColors.dark : const Color(0xFFF8FAFC),
      appBar: ModernAppbarWithBuilder(
        title: 'Pilot Exams',
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
                      color: dark
                          ? AppColors.darkGrey
                          : AppColors.textSecondary,
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
                final user = UserController.instance.user.value;
                final isFreeUser = !user.isActive;
                final progress = controller.getProgressForExam(exam.id);
                return _PilotExamCard(
                  exam: exam,
                  progress: progress,
                  dark: dark,
                  isFreeUser: isFreeUser,
                  onTap: () {
                    final now = DateTime.now();
                    if (now.difference(_lastTapTime).inMilliseconds < 600) {
                      return;
                    }
                    _lastTapTime = now;
                    HapticFeedback.lightImpact();
                    controller.selectExam(exam);
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
    this.isFreeUser = false,
    required this.onTap,
  });

  final PilotExamModel exam;
  final PilotExamProgress progress;
  final bool dark;
  final bool isFreeUser;
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
                // Title & Navigation Arrow Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        exam.title,
                        style: TextStyle(
                          fontSize: 17.5,
                          fontWeight: FontWeight.w800,
                          color: dark
                              ? Colors.white
                              : AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: dark
                          ? AppColors.darkGrey
                          : AppColors.textSecondary,
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Description
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

                // Progress Bar & Percentage
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
                            : progress.isStarted
                            ? const Color(0xFF0284C7)
                            : dark
                            ? AppColors.darkGrey
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Bottom Action Pill Bar with short text
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isFreeUser
                        ? Colors.amber.withValues(
                            alpha: dark ? 0.22 : 0.12,
                          )
                        : progress.isCompleted
                        ? const Color(
                            0xFF10B981,
                          ).withValues(alpha: dark ? 0.2 : 0.1)
                        : progress.isStarted
                        ? const Color(
                            0xFF0284C7,
                          ).withValues(alpha: dark ? 0.2 : 0.1)
                        : dark
                        ? const Color(0xFF0F766E).withValues(alpha: 0.2)
                        : const Color(0xFFF0FDFA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isFreeUser
                          ? Colors.amber.withValues(alpha: 0.4)
                          : progress.isCompleted
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
                        isFreeUser
                            ? Icons.lock_rounded
                            : progress.isCompleted
                            ? Iconsax.tick_circle_copy
                            : progress.isStarted
                            ? Iconsax.play_copy
                            : Iconsax.timer_1_copy,
                        size: 16,
                        color: isFreeUser
                            ? Colors.amber
                            : progress.isCompleted
                            ? const Color(0xFF10B981)
                            : progress.isStarted
                            ? const Color(0xFF0284C7)
                            : const Color(0xFF0D9488),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isFreeUser
                            ? 'Start Exam'
                            : progress.isCompleted
                            ? 'Review Answers'
                            : progress.isStarted
                            ? 'Resume Exam'
                            : 'Start Exam',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isFreeUser
                              ? Colors.amber
                              : progress.isCompleted
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
