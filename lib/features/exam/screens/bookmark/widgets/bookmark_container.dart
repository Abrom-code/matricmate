import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/features/exam/controllers/bookmark_controller.dart';
import 'package:matricmate/features/exam/models/bookmark_model.dart';
import 'package:matricmate/features/exam/models/question_model.dart';
import 'package:matricmate/features/exam/screens/bookmark/widgets/bookmark_qn_container.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/formatter/formatter.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:matricmate/utils/helpers/rich_text_parser.dart';

class BookmarkContainer extends GetView<BookmarkController> {
  const BookmarkContainer({super.key, required this.qn});

  final QuestionModel qn;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    final preview = qn.questionText.length > 120
        ? '${qn.questionText.substring(0, 120)}...'
        : qn.questionText;

    final bookmark = controller.bookmarkedQuestionIds.firstWhere(
      (b) => b.questionId == qn.id,
      orElse: () => BookmarkModel(
        userId: UserController.instance.user.value.id,
        questionId: qn.id,
        savedAt: 0,
      ),
    );

    return Obx(() {
      final subjectName = controller.subject(qn.subjectId);

      return GestureDetector(
        onTap: () => Get.to(() => BookmarkedQnContainer(qn: qn)),
        child: Container(
          decoration: BoxDecoration(
            color: dark ? AppColors.darkCard : AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: dark
                  ? Colors.white.withValues(alpha: 0.06)
                  : const Color(0xFFEAEAEA),
            ),
            boxShadow: dark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.055),
                      blurRadius: 14,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Left accent bar ───────────────────────────────────
                  Container(
                    width: 4,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF00897B), Color(0xFF4DB6AC)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),

                  // ── Card body ─────────────────────────────────────────
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Top row: subject + actions ──────────────
                          Row(
                            children: [
                              // Subject chip
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withValues(alpha: dark ? 0.18 : 0.09),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  subjectName.toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),

                              const Spacer(),

                              // Clock + date
                              const Icon(
                                Iconsax.clock,
                                size: 11,
                                color: AppColors.darkGrey,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                AppFormatter.formatDate(bookmark.savedAt),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.darkGrey,
                                ),
                              ),

                              const SizedBox(width: 8),

                              // Delete icon
                              GestureDetector(
                                onTap: () =>
                                    AppHelperFunctions.showAppDialog(
                                  context,
                                  'Remove bookmark?',
                                  'This question will be removed from your saved list.',
                                  () async {
                                    Get.back();
                                    await controller
                                        .removeFromBookmark(qn.id);
                                    FocusManager.instance.primaryFocus
                                        ?.unfocus();
                                  },
                                ),
                                child: Icon(
                                  Iconsax.archive_minus,
                                  size: 16,
                                  color: dark
                                      ? AppColors.darkGrey
                                      : const Color(0xFFAAAAAA),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 9),

                          // ── Question preview ────────────────────────
                          Text.rich(
                            RichTextParser.parse(
                              preview,
                              TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w400,
                                height: 1.6,
                                color: dark
                                    ? const Color(0xFFC8C8C8)
                                    : AppColors.darkerGrey,
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // ── Footer ──────────────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _TestTypePill(type: controller.testType(qn.testId), dark: dark),

                              // View link
                              const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'View',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  SizedBox(width: 2),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 10,
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                            ],
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
      );
    });
  }
}

// ── Test type pill ──────────────────────────────────────────────────────────
class _TestTypePill extends StatelessWidget {
  const _TestTypePill({required this.type, required this.dark});

  final String type;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final key = type.toLowerCase();

    final IconData icon;
    final String label;

    switch (key) {
      case 'entrance':
        icon = Iconsax.medal_star;
        label = 'Entrance';
        break;
      case 'model':
        icon = Iconsax.clipboard_text;
        label = 'Model';
        break;
      case 'chapter':
        icon = Iconsax.book;
        label = 'Chapter';
        break;
      case 'grade':
        icon = Iconsax.award;
        label = 'Grade';
        break;
      default:
        icon = Iconsax.info_circle;
        label = type.isEmpty ? 'Unknown' : type;
    }

    final color = AppColors.primary;
    final bg = dark
        ? AppColors.primary.withValues(alpha: 0.15)
        : AppColors.primary.withValues(alpha: 0.08);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
