import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/appbar/modern_appbar.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/exam/controllers/pilot_exam_controller.dart';
import 'package:matricmate/features/exam/models/pilot_exam_model.dart';
import 'package:matricmate/features/exam/models/result_model.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/formatter/formatter.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:matricmate/utils/helpers/test_access_helper.dart';

class PilotExamSubjectsScreen extends StatefulWidget {
  const PilotExamSubjectsScreen({super.key});

  @override
  State<PilotExamSubjectsScreen> createState() =>
      _PilotExamSubjectsScreenState();
}

class _PilotExamSubjectsScreenState extends State<PilotExamSubjectsScreen> {
  PilotExamController get controller => PilotExamController.instance;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    final user = UserController.instance.user.value;
    final stream = user.stream.isNotEmpty
        ? '${user.stream[0].toUpperCase()}${user.stream.substring(1)} Stream'
        : 'National Stream';

    return Scaffold(
      backgroundColor: dark ? AppColors.dark : const Color(0xFFF8FAFC),
      appBar: ModernAppbar(
        title: controller.selectedExam.value?.title ?? 'Pilot Exam',
        subtitle: '$stream • 6 Subjects Simulation',
        showBackArrow: true,
        actions: [
          Obx(() {
            final isAdmin = UserController.instance.isAdmin.value;
            final isDraft = controller.selectedExam.value?.isDraft == true;
            if (!isAdmin || !isDraft) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: IconButton(
                tooltip: 'Verify & Publish Pilot Exam',
                onPressed: () {
                  final exam = controller.selectedExam.value;
                  if (exam == null) return;
                  AppHelperFunctions.showAppDialog(
                    context,
                    'Publish Pilot Exam?',
                    'This pilot exam and its subjects will be verified and published nationwide for all students.',
                    () async {
                      Get.back();
                      await controller.verifyAndPublishPilotExam(exam.id);
                    },
                    okText: 'Publish Now',
                    cancelText: 'Cancel',
                    icon: Icons.verified_rounded,
                    iconColor: AppColors.primary,
                  );
                },
                icon: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.verified_rounded,
                      color: Colors.amberAccent,
                      size: 17,
                    ),
                  ),
                ),
              ),
            );
          }),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: 'Refresh',
              onPressed: () => controller.loadSubjectsForSelectedExam(),
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
        if (controller.isLoadingSubjects.value) {
          return const AppCircularLoading(title: 'Loading exam subjects...');
        }

        final user = UserController.instance.user.value;
        final isLocked = !user.isActive;

        final subjects = controller.examSubjects;
        final completedCount = controller.completedSubjectsCount;
        final grandTotal = controller.grandTotalScore;
        final compositePct = controller.compositePercentage;

        if (subjects.isEmpty) {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: controller.loadSubjectsForSelectedExam,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.5,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Iconsax.book_1_copy,
                            size: 48,
                            color: dark
                                ? AppColors.darkGrey
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No Subjects Available',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: dark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'The subjects for this pilot exam will appear here once configured.',
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
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: controller.loadSubjectsForSelectedExam,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.paddingOf(context).bottom + 40,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Composite Scorecard Hero ───────────────────────────────
                _CompositeScorecardCard(
                  dark: dark,
                  completedCount: completedCount,
                  totalSubjects: subjects.length,
                  grandTotal: grandTotal,
                  compositePct: compositePct,
                ),

                const SizedBox(height: 22),

                // ── Section Title Row with Download Action Icon ───────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Exam Subjects',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: dark ? Colors.white : AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Tooltip(
                      message: isLocked
                          ? 'Premium feature • Tap to unlock'
                          : controller.isBulkDownloading.value
                              ? 'Downloading exam (${(controller.bulkDownloadProgress.value * 100).toInt()}%)\nTap to view progress'
                              : (controller.isAllSubjectsDownloaded
                                  ? 'Delete downloaded exam'
                                  : 'Download all subjects for offline use'),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: controller.isDeletingDownloads.value
                            ? null
                            : (controller.isBulkDownloading.value
                                ? () => controller
                                    .showActiveDownloadProgressDialog()
                                : (isLocked
                                    ? () {
                                        HapticFeedback.lightImpact();
                                        TestAccessHelper.openPremiumSheet(
                                          user: user,
                                        );
                                      }
                                    : (controller.isAllSubjectsDownloaded
                                        ? () => _confirmDeleteExamDownloads(
                                              context,
                                              controller,
                                              dark,
                                            )
                                        : controller.downloadAllSubjects))),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isLocked
                                ? Colors.amber.withValues(
                                    alpha: dark ? 0.2 : 0.1,
                                  )
                                : controller.isAllSubjectsDownloaded
                                    ? const Color(
                                        0xFFEF4444,
                                      ).withValues(alpha: dark ? 0.2 : 0.1)
                                    : AppColors.primary.withValues(
                                        alpha: dark ? 0.22 : 0.1,
                                      ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isLocked
                                  ? Colors.amber.withValues(alpha: 0.35)
                                  : controller.isAllSubjectsDownloaded
                                      ? const Color(
                                          0xFFEF4444,
                                        ).withValues(alpha: 0.35)
                                      : AppColors.primary
                                          .withValues(alpha: 0.35),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: isLocked
                                ? const Icon(
                                    Icons.lock_rounded,
                                    size: 18,
                                    color: Colors.amber,
                                  )
                                : controller.isBulkDownloading.value ||
                                        controller.isDeletingDownloads.value
                                    ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          value: controller
                                                      .isBulkDownloading
                                                      .value &&
                                                  controller
                                                          .bulkDownloadProgress
                                                          .value >
                                                      0
                                              ? controller
                                                  .bulkDownloadProgress.value
                                              : null,
                                          strokeWidth: 2.2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            controller.isDeletingDownloads.value
                                                ? const Color(0xFFEF4444)
                                                : AppColors.primary,
                                          ),
                                        ),
                                      )
                                    : Icon(
                                        controller.isAllSubjectsDownloaded
                                            ? Icons.delete_outline_rounded
                                            : Icons.download_rounded,
                                        size: 20,
                                        color: controller
                                                .isAllSubjectsDownloaded
                                            ? const Color(0xFFEF4444)
                                            : AppColors.primary,
                                      ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── 6 Subject Cards List ───────────────────────────────────
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: subjects.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final subject = subjects[index];
                    final isCompleted = controller.isSubjectCompleted(
                      subject.testId,
                    );
                    final isInProgress = controller.isSubjectInProgress(
                      subject.testId,
                    );
                    final draft = controller.testResults[subject.testId];
                    final isDownloaded = controller.isSubjectDownloaded(
                      subject.testId,
                    );
                    final isDownloading =
                        controller.isSubjectDownloading[subject.testId] == true;
                    final score100 = controller.getSubjectScoreOutOf100(
                      subject.testId,
                      subject.questionCount,
                    );
                    final correctAnswers = controller.getSubjectCorrectAnswers(
                      subject.testId,
                    );
                    final totalQuestions = controller.getSubjectTotalQuestions(
                      subject.testId,
                      subject.questionCount,
                    );

                    final downloadProgress = controller
                        .subjectDownloadProgress[subject.testId];

                    return _SubjectExamTile(
                      dark: dark,
                      subject: subject,
                      isLocked: isLocked,
                      isCompleted: isCompleted,
                      isInProgress: isInProgress,
                      draft: draft,
                      isDownloaded: isDownloaded,
                      isDownloading: isDownloading,
                      downloadProgress: downloadProgress,
                      scoreOutOf100: score100,
                      correctAnswers: correctAnswers,
                      totalQuestions: totalQuestions,
                      onDownload: () {
                        HapticFeedback.lightImpact();
                        if (isLocked) {
                          TestAccessHelper.openPremiumSheet(user: user);
                        } else {
                          controller.downloadSubject(subject);
                        }
                      },
                      onTap: () {
                        HapticFeedback.lightImpact();
                        if (isLocked) {
                          TestAccessHelper.openPremiumSheet(user: user);
                        } else if (isCompleted) {
                          controller.openSubjectReview(subject);
                        } else if (!isDownloaded) {
                          controller.downloadSubject(subject);
                        } else {
                          controller.startSubjectExam(subject, user);
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  void _confirmDeleteExamDownloads(
    BuildContext context,
    PilotExamController controller,
    bool dark,
  ) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: dark ? AppColors.darkCard : AppColors.white,
          elevation: 16,
          shadowColor: Colors.black.withValues(alpha: dark ? 0.5 : 0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
          ),
          insetPadding: EdgeInsets.symmetric(
            horizontal: 24,
            vertical: isLandscape ? 12 : 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 380,
              maxHeight: isLandscape ? screenHeight * 0.94 : screenHeight * 0.85,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(22, isLandscape ? 16 : 28, 22, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(
                        alpha: dark ? 0.15 : 0.1,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(
                            alpha: dark ? 0.25 : 0.16,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.delete_outline_rounded,
                            color: Color(0xFFEF4444),
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Delete Downloaded Exam?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: dark ? AppColors.textWhite : AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'This will remove all downloaded questions and offline data for this pilot exam from your device. You can download them again anytime.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color:
                          dark ? AppColors.darkGrey : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                dark ? AppColors.white : AppColors.textPrimary,
                            side: BorderSide(
                              color: dark
                                  ? AppColors.darkBorder
                                  : const Color(0xFFCBD5E1),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            controller.deleteAllExamDownloads();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Delete All',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Composite Scorecard Card ─────────────────────────────────────────────────

class _CompositeScorecardCard extends StatelessWidget {
  const _CompositeScorecardCard({
    required this.dark,
    required this.completedCount,
    required this.totalSubjects,
    required this.grandTotal,
    required this.compositePct,
  });

  final bool dark;
  final int completedCount;
  final int totalSubjects;
  final double grandTotal;
  final double compositePct;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: dark
              ? [
                  const Color(0xFF0F766E),
                  const Color(0xFF115E59),
                  const Color(0xFF042F2C),
                ]
              : [
                  const Color(0xFF0D9488),
                  const Color(0xFF0F766E),
                  const Color(0xFF134E4A),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D9488).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Circular percentage indicator
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  value: completedCount > 0
                      ? (compositePct / 100.0).clamp(0.0, 1.0)
                      : 0.0,
                  strokeWidth: 6.5,
                  strokeCap: StrokeCap.round,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF34D399),
                  ),
                ),
              ),
              Text(
                completedCount > 0
                    ? '${compositePct.toStringAsFixed(0)}%'
                    : '0%',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(width: 18),

          // Score details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Grand Total Score',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFCCFBF1),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: grandTotal.toStringAsFixed(0),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),
                      const TextSpan(
                        text: ' / 600',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF99F6E4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$completedCount of $totalSubjects subjects completed',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFFE6FFFA),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Subject Exam Tile ────────────────────────────────────────────────────────

class _SubjectExamTile extends StatelessWidget {
  const _SubjectExamTile({
    required this.dark,
    required this.subject,
    this.isLocked = false,
    required this.isCompleted,
    this.isInProgress = false,
    this.draft,
    required this.isDownloaded,
    required this.isDownloading,
    this.downloadProgress,
    required this.scoreOutOf100,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.onDownload,
    required this.onTap,
  });

  final bool dark;
  final PilotExamSubjectModel subject;
  final bool isLocked;
  final bool isCompleted;
  final bool isInProgress;
  final ResultModel? draft;
  final bool isDownloaded;
  final bool isDownloading;
  final double? downloadProgress;
  final double scoreOutOf100;
  final int correctAnswers;
  final int totalQuestions;
  final VoidCallback onDownload;
  final VoidCallback onTap;

  IconData _getSubjectIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('math')) return Iconsax.math_copy;
    if (lower.contains('physic')) return Iconsax.radar_copy;
    if (lower.contains('chem')) return Iconsax.bubble_copy;
    if (lower.contains('bio')) return Iconsax.heart_copy;
    if (lower.contains('eng')) return Iconsax.language_square_copy;
    if (lower.contains('hist')) return Iconsax.book_copy;
    if (lower.contains('geo')) return Iconsax.global_copy;
    if (lower.contains('econ')) return Iconsax.chart_copy;
    return Iconsax.note_2_copy;
  }

  Color _getSubjectColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('math')) return const Color(0xFF2563EB);
    if (lower.contains('physic')) return const Color(0xFF7C3AED);
    if (lower.contains('chem')) return const Color(0xFF0D9488);
    if (lower.contains('bio')) return const Color(0xFF059669);
    if (lower.contains('eng')) return const Color(0xFFEA580C);
    if (lower.contains('hist')) return const Color(0xFFD97706);
    if (lower.contains('geo')) return const Color(0xFF0284C7);
    if (lower.contains('econ')) return const Color(0xFF4F46E5);
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getSubjectColor(subject.subjectName);
    final icon = _getSubjectIcon(subject.subjectName);

    return Container(
      decoration: BoxDecoration(
        color: dark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isLocked
              ? Colors.amber.withValues(alpha: dark ? 0.40 : 0.28)
              : isCompleted
                  ? const Color(0xFF10B981).withValues(alpha: dark ? 0.35 : 0.25)
                  : isInProgress
                      ? const Color(0xFFF59E0B).withValues(alpha: dark ? 0.5 : 0.35)
                      : (dark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
          width: isLocked ? 1.3 : (isInProgress ? 1.4 : 1.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Subject Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isLocked
                        ? Colors.amber.withValues(alpha: dark ? 0.20 : 0.12)
                        : color.withValues(alpha: dark ? 0.22 : 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: isLocked
                        ? Border.all(
                            color: Colors.amber.withValues(alpha: 0.35),
                            width: 1,
                          )
                        : null,
                  ),
                  child: Center(
                    child: isLocked
                        ? const Icon(
                            Icons.lock_rounded,
                            color: Colors.amber,
                            size: 22,
                          )
                        : Icon(icon, color: color, size: 22),
                  ),
                ),
                const SizedBox(width: 14),

                // Name & Meta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject.subjectName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: dark ? Colors.white : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      if (isLocked) ...[
                        Text(
                          '${subject.timeMinutes} mins • ${subject.questionCount} questions',
                          style: TextStyle(
                            fontSize: 12,
                            color: dark
                                ? AppColors.darkGrey
                                : AppColors.textSecondary,
                          ),
                        ),
                      ] else if (isCompleted) ...[
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Score: $correctAnswers/$totalQuestions',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                              TextSpan(
                                text:
                                    ' (${scoreOutOf100.toStringAsFixed(0)}%) • Tap to review',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: dark
                                      ? AppColors.darkGrey
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ] else if (isInProgress && draft != null) ...[
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                text: 'Paused • ',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFF59E0B),
                                ),
                              ),
                              TextSpan(
                                text:
                                    '${draft!.selectedAnswers.length}/$totalQuestions answered',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: dark
                                      ? Colors.white70
                                      : AppColors.textPrimary,
                                ),
                              ),
                              if (draft!.remainingSeconds > 0)
                                TextSpan(
                                  text:
                                      ' • ${AppFormatter.formattedTime(draft!.remainingSeconds)} left',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: dark
                                        ? AppColors.darkGrey
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              const TextSpan(
                                text: ' • Tap to resume',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFF59E0B),
                                ),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ] else ...[
                        Text(
                          isDownloading
                              ? (downloadProgress != null &&
                                      downloadProgress! > 0
                                  ? 'Downloading questions (${(downloadProgress! * 100).toInt()}%)...'
                                  : 'Downloading questions…')
                              : (!isDownloaded
                                  ? '${subject.timeMinutes} mins • Tap to download'
                                  : '${subject.timeMinutes} mins • ${subject.questionCount} questions • Ready'),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDownloading
                                ? AppColors.primary
                                : (dark
                                    ? AppColors.darkGrey
                                    : AppColors.textSecondary),
                            fontWeight: isDownloading
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Right Action / Status (Note-style circular download or lock)
                if (isLocked) ...[
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(
                        alpha: dark ? 0.18 : 0.10,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.lock_rounded,
                        size: 16,
                        color: Colors.amber,
                      ),
                    ),
                  ),
                ] else if (isDownloading) ...[
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: downloadProgress,
                          strokeWidth: 2.5,
                          color: AppColors.primary,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.15),
                        ),
                        if (downloadProgress != null && downloadProgress! > 0)
                          Text(
                            '${(downloadProgress! * 100).toInt()}',
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                              height: 1.0,
                            ),
                          )
                        else
                          const Icon(
                            Icons.arrow_downward_rounded,
                            size: 12,
                            color: AppColors.primary,
                          ),
                      ],
                    ),
                  ),
                ] else if (!isDownloaded && !isCompleted) ...[
                  GestureDetector(
                    onTap: onDownload,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(
                          alpha: dark ? 0.2 : 0.08,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_downward_rounded,
                          size: 17,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ] else if (isInProgress) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(
                        alpha: dark ? 0.22 : 0.12,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_arrow_rounded,
                          size: 16,
                          color: Color(0xFFF59E0B),
                        ),
                        SizedBox(width: 3),
                        Text(
                          'Resume',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: isCompleted
                        ? const Color(0xFF10B981)
                        : (dark ? AppColors.darkGrey : AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
