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

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      behavior: HitTestBehavior.opaque,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        elevation: 0,
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent card taps from bubbling up to dismiss
            behavior: HitTestBehavior.opaque,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                decoration: BoxDecoration(
                  color: dark ? AppColors.darkCard : AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: dark ? AppColors.darkBorder : AppColors.borderPrimary,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: dark ? 0.45 : 0.18),
                      blurRadius: 28,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // ── Subject Header ────────────────────────────────────────
                Row(
                  children: [
                    // Artwork Thumbnail
                    Container(
                      width: 50,
                      height: 50,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: dark
                            ? AppColors.darkSurface
                            : AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Image.asset(
                        AppHelperFunctions.getSubjectImage(subject.name),
                        fit: BoxFit.contain,
                      ),
                    ),

                    const SizedBox(width: 14),

                    // Title + Stream
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject.name,
                            style: TextStyle(
                              fontSize: 18.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                              color: dark
                                  ? AppColors.textWhite
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(
                                alpha: dark ? 0.2 : 0.1,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              streamLabel,
                              style: const TextStyle(
                                fontSize: 10.5,
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
                          size: 18,
                          color: dark
                              ? AppColors.darkGrey
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // ── Subtitle ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 12),
                  child: Text(
                    'Choose Practice Mode',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),

                // ── Option 1: Study & Practice ────────────────────────────
                _ModeOptionTile(
                  dark: dark,
                  icon: Iconsax.book_1_copy,
                  iconGradient: const [AppColors.primary, Color(0xFF00796B)],
                  title: 'Study & Practice',
                  subtitle: 'Learn by grade, chapter and topic',
                  chips: const ['Grades 9 – 12', 'Chapter Tests'],
                  onTap: () {
                    Navigator.of(context).pop();
                    Get.toNamed(
                      Routes.chapter,
                      arguments: {
                        'title': subject.name,
                        'id': subject.id,
                      },
                    );
                  },
                ),

                const SizedBox(height: 12),

                // ── Option 2: Exams ──────────────────────────────────────
                _ModeOptionTile(
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
                ),

                const SizedBox(height: 14),

                // ── Remove from Device Button ──────────────────────────────
                InkWell(
                  onTap: () => confirmDelete(context, subject, closeModal: true),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                          color: AppColors.error.withValues(alpha: 0.85),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Remove from device',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
    final dark = AppHelperFunctions.isDark(context);
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: dark ? AppColors.darkCard : AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.error,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Delete ${subject.name}?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: dark ? AppColors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This will remove all downloaded chapters, questions, and exams for ${subject.name} from your device. You can download it again anytime.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: dark ? Colors.white60 : AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                              color: dark
                                  ? AppColors.darkBorder
                                  : AppColors.borderPrimary,
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: dark
                                  ? AppColors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            if (closeModal) {
                              Navigator.of(context).pop();
                            }
                            SubjectsController.instance.deleteSubject(subject);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Delete',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
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
    required this.icon,
    required this.iconGradient,
    required this.title,
    required this.subtitle,
    required this.chips,
    required this.onTap,
    this.isDisabled = false,
  });

  final bool dark;
  final IconData icon;
  final List<Color> iconGradient;
  final String title, subtitle;
  final List<String> chips;
  final VoidCallback onTap;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: dark ? AppColors.darkSurface : AppColors.white,
        borderRadius: BorderRadius.circular(18),
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
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
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
                              color: iconGradient.first.withValues(alpha: 0.3),
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

                // ── Title & Subtitle & Chips ────────────────────────
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
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: dark
                              ? AppColors.darkGrey
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: chips.map((chip) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: dark
                                  ? AppColors.darkCard
                                  : AppColors.lightGrey,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              chip,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: dark
                                    ? AppColors.darkGrey
                                    : AppColors.textSecondary,
                              ),
                            ),
                          );
                        }).toList(),
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
