import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/features/exam/controllers/subjects_controller.dart';
import 'package:matricmate/features/exam/models/subject_model.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';

class SubjectModeModal extends StatelessWidget {
  const SubjectModeModal({super.key, required this.subject});

  final SubjectModel subject;

  static Future<void> show(BuildContext context, SubjectModel subject) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => SubjectModeModal(subject: subject),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    final ctrl = SubjectsController.instance;

    final entranceCount = ctrl.entranceTestNumbers[subject.id] ?? 0;
    final modelCount = ctrl.modelTestNumbers[subject.id] ?? 0;
    final totalMockExams = entranceCount + modelCount;

    final stream = UserController.instance.user.value.stream;
    final streamLabel = stream.isNotEmpty
        ? '${stream[0].toUpperCase()}${stream.substring(1)} Stream'
        : 'Secondary Stream';

    final notesSubtitle = subject.isCommon
        ? 'Section summaries, revision guides & formula sheets'
        : 'Chapter notes & summaries for Grades 9 – 12';

    final testsSubtitle = subject.isCommon
        ? 'Section-by-section practice tests and timed quizzes'
        : 'Chapter and full-grade tests for Grades 9 – 12';

    final String examSubtitle;
    if (totalMockExams == 0) {
      examSubtitle = 'National entrance and model exams coming soon';
    } else if (entranceCount > 0 && modelCount > 0) {
      examSubtitle =
          'Past years $entranceCount entrance and $modelCount model exams';
    } else if (entranceCount > 0) {
      examSubtitle =
          'Practice with $entranceCount past national entrance exam papers';
    } else {
      examSubtitle = 'Practice with $modelCount model exam papers';
    }

    final screenHeight = MediaQuery.sizeOf(context).height;
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    final notesTile = _ModeOptionTile(
      dark: dark,
      isLandscape: isLandscape,
      icon: Iconsax.document_text_copy,
      iconGradient: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
      title: 'Notes',
      subtitle: notesSubtitle,
      onTap: () {
        Navigator.of(context).pop();
        Get.toNamed(
          Routes.notes,
          arguments: {
            'title': subject.name,
            'id': subject.id,
            'is_common': subject.isCommon,
          },
        );
      },
    );

    final testsTile = _ModeOptionTile(
      dark: dark,
      isLandscape: isLandscape,
      icon: Iconsax.book_1_copy,
      iconGradient: const [AppColors.primary, Color(0xFF00796B)],
      title: 'Tests',
      subtitle: testsSubtitle,
      onTap: () {
        Navigator.of(context).pop();
        Get.toNamed(
          Routes.chapter,
          arguments: {
            'title': subject.name,
            'id': subject.id,
            'is_common': subject.isCommon,
          },
        );
      },
    );

    final examsTile = _ModeOptionTile(
      dark: dark,
      isLandscape: isLandscape,
      icon: Icons.military_tech_rounded,
      iconGradient: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
      title: 'Exams',
      subtitle: examSubtitle,
      isDisabled: totalMockExams == 0,
      onTap: () {
        if (totalMockExams == 0) {
          ToastHelper.info(
            'Exams for ${subject.name} are coming soon!',
          );
          return;
        }
        Navigator.of(context).pop();
        Get.toNamed(
          Routes.entranceExams,
          arguments: {
            'subject_id': subject.id,
            'subject': subject.name,
          },
        );
      },
    );

    return Dialog(
      backgroundColor: dark ? AppColors.darkCard : AppColors.white,
      elevation: 16,
      shadowColor: Colors.black.withValues(alpha: dark ? 0.45 : 0.18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: dark ? AppColors.darkBorder : AppColors.borderPrimary,
          width: 1.2,
        ),
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: isLandscape ? 8 : 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isLandscape ? 660 : 440,
          maxHeight: isLandscape ? screenHeight * 0.94 : screenHeight * 0.85,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.all(isLandscape ? 14 : 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Subject Header ────────────────────────────────────────
              Row(
                children: [
                  // Artwork Thumbnail
                  Container(
                    width: isLandscape ? 38 : 50,
                    height: isLandscape ? 38 : 50,
                    padding: EdgeInsets.all(isLandscape ? 4 : 6),
                    decoration: BoxDecoration(
                      color: dark
                          ? AppColors.darkSurface
                          : AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(isLandscape ? 10 : 14),
                    ),
                    child: Image.asset(
                      AppHelperFunctions.getSubjectImage(subject.name),
                      fit: BoxFit.contain,
                    ),
                  ),

                  SizedBox(width: isLandscape ? 10 : 14),

                  // Title + Stream
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject.name,
                          style: TextStyle(
                            fontSize: isLandscape ? 16 : 18.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                            color: dark
                                ? AppColors.textWhite
                                : AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: isLandscape ? 1 : 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(
                              alpha: dark ? 0.2 : 0.1,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            streamLabel,
                            style: TextStyle(
                              fontSize: isLandscape ? 9.5 : 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Close Button
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: dark
                            ? AppColors.darkSurface
                            : AppColors.lightGrey,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: isLandscape ? 16 : 18,
                        color: dark
                            ? AppColors.darkGrey
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: isLandscape ? 10 : 18),

              // ── Subtitle ──────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.only(left: 2, bottom: isLandscape ? 8 : 12),
                child: Text(
                  'Choose Study & Practice Mode',
                  style: TextStyle(
                    fontSize: isLandscape ? 12 : 13.5,
                    fontWeight: FontWeight.w700,
                    color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                    letterSpacing: 0.1,
                  ),
                ),
              ),

              // ── Options (Side-by-side in landscape, stacked in portrait) ──
              if (isLandscape) ...[
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: notesTile),
                      const SizedBox(width: 10),
                      Expanded(child: testsTile),
                      const SizedBox(width: 10),
                      Expanded(child: examsTile),
                    ],
                  ),
                ),
              ] else ...[
                notesTile,
                const SizedBox(height: 12),
                testsTile,
                const SizedBox(height: 12),
                examsTile,
              ],
            ],
          ),
        ),
      ),
    );
  }

  static void confirmDelete(
    BuildContext context,
    SubjectModel subject, {
    bool closeModal = false,
  }) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final dark = AppHelperFunctions.isDark(context);

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
            vertical: isLandscape ? 10 : 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isLandscape ? 440 : 380,
              maxHeight: isLandscape ? screenHeight * 0.94 : screenHeight * 0.85,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(22, isLandscape ? 14 : 28, 22, isLandscape ? 14 : 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Layered Danger Icon Badge ─────────────────────────
                  Container(
                    width: isLandscape ? 44 : 64,
                    height: isLandscape ? 44 : 64,
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFFEF4444,
                      ).withValues(alpha: dark ? 0.14 : 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: isLandscape ? 32 : 48,
                        height: isLandscape ? 32 : 48,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFEF4444,
                          ).withValues(alpha: dark ? 0.22 : 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.delete_outline_rounded,
                            color: const Color(0xFFEF4444),
                            size: isLandscape ? 18 : 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: isLandscape ? 10 : 18),

                  // ── Title ─────────────────────────────────────────────
                  Text(
                    'Delete ${subject.name}?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isLandscape ? 17 : 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                      color: dark ? AppColors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: isLandscape ? 4 : 8),

                  // ── Subtitle ──────────────────────────────────────────
                  Text(
                    'This will remove all downloaded chapters, tests, exams, and notes for ${subject.name} from your device. You can download it again anytime.',
                    textAlign: TextAlign.center,
                    maxLines: isLandscape ? 2 : null,
                    overflow: isLandscape ? TextOverflow.ellipsis : null,
                    style: TextStyle(
                      fontSize: isLandscape ? 12 : 13.5,
                      height: 1.35,
                      color: dark
                          ? AppColors.darkGrey
                          : AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: isLandscape ? 14 : 24),

                  // ── Action Buttons ────────────────────────────────────
                  Row(
                    children: [
                      // Cancel Button
                      Expanded(
                        child: SizedBox(
                          height: isLandscape ? 40 : 46,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(
                                color: dark
                                    ? AppColors.darkInputBorder
                                    : const Color(0xFFCBD5E1),
                                width: 1.2,
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                height: 1.0,
                                color: dark
                                    ? AppColors.white
                                    : const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Delete Button
                      Expanded(
                        child: SizedBox(
                          height: isLandscape ? 40 : 46,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              if (closeModal) {
                                Navigator.of(context).pop();
                              }
                              SubjectsController.instance.deleteSubject(
                                subject,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              backgroundColor: const Color(0xFFEF4444),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.delete_outline_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Delete',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    height: 1.0,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
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

// ── Private Mode Option Tile ──────────────────────────────────────────────────

class _ModeOptionTile extends StatelessWidget {
  const _ModeOptionTile({
    required this.dark,
    required this.isLandscape,
    required this.icon,
    required this.iconGradient,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDisabled = false,
  });

  final bool dark;
  final bool isLandscape;
  final IconData icon;
  final List<Color> iconGradient;
  final String title, subtitle;
  final VoidCallback onTap;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: dark ? AppColors.darkSurface : AppColors.white,
        borderRadius: BorderRadius.circular(isLandscape ? 14 : 18),
        border: Border.all(
          color: dark ? AppColors.darkBorder : AppColors.borderPrimary,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(isLandscape ? 14 : 18),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isLandscape ? 12 : 14,
              vertical: isLandscape ? 10 : 14,
            ),
            child: isLandscape
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDisabled
                                    ? [AppColors.grey, AppColors.darkGrey]
                                    : iconGradient,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: isDisabled
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: iconGradient.first
                                            .withValues(alpha: 0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: Center(
                              child: Icon(
                                icon,
                                color: AppColors.white,
                                size: 18,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: dark ? AppColors.darkGrey : AppColors.grey,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          color: dark
                              ? AppColors.textWhite
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          height: 1.25,
                          color: dark
                              ? AppColors.darkGrey
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      // ── Gradient Icon Squircle ──────────────────────────
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDisabled
                                ? [AppColors.grey, AppColors.darkGrey]
                                : iconGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: isDisabled
                              ? null
                              : [
                                  BoxShadow(
                                    color: iconGradient.first
                                        .withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: Center(
                          child: Icon(icon, color: AppColors.white, size: 24),
                        ),
                      ),

                      const SizedBox(width: 14),

                      // ── Title & Subtitle ────────────────────────────────
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                                color: dark
                                    ? AppColors.textWhite
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                height: 1.35,
                                color: dark
                                    ? AppColors.darkGrey
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // ── Trailing Chevron ────────────────────────────────
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 22,
                        color: dark ? AppColors.darkGrey : AppColors.grey,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
