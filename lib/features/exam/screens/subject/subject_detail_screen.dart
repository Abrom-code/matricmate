import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/appbar/modern_appbar.dart';
import 'package:matricmate/features/exam/controllers/subjects_controller.dart';
import 'package:matricmate/features/exam/models/subject_model.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class SubjectDetailScreen extends StatelessWidget {
  const SubjectDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    final ctrl = SubjectsController.instance;
    final args = Get.arguments as Map<String, dynamic>? ?? {};

    final subjectId = args['id'] as int? ?? 0;
    final subjectTitle = args['title'] as String? ?? 'Subject';

    return Scaffold(
      appBar: ModernAppbar(
        title: subjectTitle,
        subtitle: 'Choose learning mode',
        showBackArrow: true,
      ),
      body: Obx(() {
        // Find reactive subject model from SubjectsController
        final subjectList = ctrl.subjects.where((s) => s.id == subjectId);
        final subject = subjectList.isNotEmpty
            ? subjectList.first
            : SubjectModel(
                id: subjectId,
                name: subjectTitle,
                isNatural: true,
                isDownloaded: false,
                isEntranceDownloaded: false,
              );

        final entranceCount = ctrl.entranceTestNumbers[subjectId] ?? 0;
        final modelCount = ctrl.modelTestNumbers[subjectId] ?? 0;
        final totalMockExams = entranceCount + modelCount;

        final isStudyDownloading =
            ctrl.downloadingMap[subject.name] ?? false;
        final studyProgress =
            ctrl.subjectDownloadProgress[subject.name];

        final entranceStep = ctrl.entranceDownloadStep[subject.id];
        final entranceProgress = ctrl.entranceDownloadProgress[subject.id];
        final isEntranceDownloading = entranceStep != null;

        final stream = UserController.instance.user.value.stream;
        final streamLabel = stream.isNotEmpty
            ? '${stream[0].toUpperCase()}${stream.substring(1)} Stream'
            : 'Secondary Stream';

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Hero Subject Header Card ────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: dark ? AppColors.darkCard : AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: dark ? AppColors.darkBorder : AppColors.borderPrimary,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: dark ? 0.25 : 0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Subject artwork frame
                    Container(
                      width: 72,
                      height: 72,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: dark
                            ? AppColors.darkSurface
                            : AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Image.asset(
                        AppHelperFunctions.getSubjectImage(subject.name),
                        fit: BoxFit.contain,
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject.name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                              color: dark
                                  ? AppColors.textWhite
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(
                                alpha: dark ? 0.2 : 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              streamLabel,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── 2. "What do you want to practice?" Title ────────────
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  'What do you want to practice?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: dark ? AppColors.textWhite : AppColors.textPrimary,
                  ),
                ),
              ),

              // ── 3. Primary Destination 1: Tests ─────────────────────
              _PrimaryDestinationCard(
                dark: dark,
                icon: Iconsax.book_1_copy,
                iconGradient: const [AppColors.primary, Color(0xFF00796B)],
                title: 'Tests',
                subtitle: subject.isCommon
                    ? 'Section and practice tests'
                    : 'Chapter and grade based tests',
                chips: subject.isCommon
                    ? const ['All Sections', 'Section Tests']
                    : const ['Grades 9 – 12', 'Chapter Tests'],
                isDownloaded: subject.isDownloaded,
                isDownloading: isStudyDownloading,
                progress: studyProgress,
                downloadButtonLabel: 'Download Tests',
                onDownload: () =>
                    ctrl.downloadSubject(subject.name, subject.id),
                onTap: subject.isDownloaded
                    ? () => Get.toNamed(
                          Routes.chapter,
                          arguments: {
                            'title': subject.name,
                            'id': subject.id,
                            'is_common': subject.isCommon,
                          },
                        )
                    : () => ctrl.downloadSubject(subject.name, subject.id),
              ),

              const SizedBox(height: 16),

              // ── 4. Primary Destination 2: Exams ────────────────────
              _PrimaryDestinationCard(
                dark: dark,
                icon: Icons.military_tech_rounded,
                iconGradient: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                title: 'Exams',
                subtitle: 'Entrance and model exams',
                chips: totalMockExams > 0
                    ? [
                        '$entranceCount Entrance Papers',
                        if (modelCount > 0) '$modelCount Model Tests',
                      ]
                    : ['Coming soon'],
                isDownloaded: subject.isEntranceDownloaded,
                isDownloading: isEntranceDownloading,
                progress: entranceProgress,
                isComingSoon: totalMockExams == 0,
                downloadButtonLabel: 'Download Exams',
                onDownload: totalMockExams > 0
                    ? () => ctrl.downloadEntranceExams(subject)
                    : null,
                onTap: totalMockExams == 0
                    ? null
                    : (subject.isEntranceDownloaded
                        ? () => Get.toNamed(
                              Routes.entranceExams,
                              arguments: {
                                'subject_id': subject.id,
                                'subject': subject.name,
                              },
                            )
                        : () => ctrl.downloadEntranceExams(subject)),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ── Destination Card Widget ──────────────────────────────────────────────────

class _PrimaryDestinationCard extends StatelessWidget {
  const _PrimaryDestinationCard({
    required this.dark,
    required this.icon,
    required this.iconGradient,
    required this.title,
    required this.subtitle,
    required this.chips,
    required this.isDownloaded,
    required this.isDownloading,
    this.progress,
    this.isComingSoon = false,
    required this.downloadButtonLabel,
    this.onDownload,
    this.onTap,
  });

  final bool dark;
  final IconData icon;
  final List<Color> iconGradient;
  final String title, subtitle;
  final List<String> chips;
  final bool isDownloaded, isDownloading, isComingSoon;
  final double? progress;
  final String downloadButtonLabel;
  final VoidCallback? onDownload, onTap;

  @override
  Widget build(BuildContext context) {
    final cardBg = dark ? AppColors.darkCard : AppColors.white;
    final borderColor = isDownloading
        ? iconGradient.first
        : (dark ? AppColors.darkBorder : AppColors.borderPrimary);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: borderColor,
          width: isDownloading ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Icon Squircle ─────────────────────────────────
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: iconGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: iconGradient.first.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(icon, color: AppColors.white, size: 26),
                      ),
                    ),

                    const SizedBox(width: 14),

                    // ── Title + Subtitle ──────────────────────────────
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                    color: dark
                                        ? AppColors.textWhite
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (isDownloaded)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(
                                      alpha: dark ? 0.2 : 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle_rounded,
                                        size: 12,
                                        color: AppColors.success,
                                      ),
                                      SizedBox(width: 3),
                                      Text(
                                        'Ready',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.success,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else if (isComingSoon)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: dark
                                        ? AppColors.darkSurface
                                        : AppColors.lightGrey,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Soon',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: dark
                                          ? AppColors.darkGrey
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: dark
                                  ? AppColors.darkGrey
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // ── Chevron ───────────────────────────────────────
                    if (!isComingSoon && isDownloaded)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 24,
                          color: dark ? AppColors.darkGrey : AppColors.grey,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 14),

                // ── Info Chips ────────────────────────────────────────
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: chips.map((chip) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: dark
                            ? AppColors.darkSurface
                            : AppColors.lightGrey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        chip,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: dark
                              ? AppColors.darkGrey
                              : AppColors.textSecondary,
                        ),
                      ),
                    );
                  }).toList(),
                ),

                // ── Download Button or Live Progress ──────────────────
                if (!isDownloaded && !isComingSoon) ...[
                  const SizedBox(height: 14),
                  if (isDownloading) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 5,
                              backgroundColor: iconGradient.first.withValues(
                                alpha: 0.15,
                              ),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                iconGradient.first,
                              ),
                            ),
                          ),
                        ),
                        if (progress != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${(progress! * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: iconGradient.first,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ] else ...[
                    GestureDetector(
                      onTap: onDownload,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: iconGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: iconGradient.first.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.cloud_download_rounded,
                              color: AppColors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              downloadButtonLabel,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
