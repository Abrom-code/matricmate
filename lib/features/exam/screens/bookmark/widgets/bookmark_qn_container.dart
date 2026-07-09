import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/common/widgets/exam/question_detail_box.dart';
import 'package:matricmate/features/exam/controllers/bookmark_controller.dart';
import 'package:matricmate/features/exam/models/question_model.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';

class BookmarkedQnContainer extends GetView<BookmarkController> {
  const BookmarkedQnContainer({super.key, required this.qn});
  final QuestionModel qn;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Appbar(
        showBackArrow: true,
        title: Text(
          'Bookmarked Question',
          style: Theme.of(context).textTheme.headlineSmall!.apply(
                color: AppColors.white,
              ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.defaultSpace / 2),
        child: Obx(() {
          final passageExpanded = controller.isPassageExpanded[qn.id] ?? false;
          final passage = qn.passageId != null
              ? controller.passages[qn.passageId]
              : null;
          final explanationExpanded = controller.isExpanded[qn.id] ?? false;

          return QuestionDetailBox(
            question: qn,
            selectedAnswerIndex: qn.correctOptionIndex,
            // ── Header ─────────────────────────────────────────────────
            headerLeft: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.lg),
              ),
              child: Text(
                controller.subject(qn.subjectId).toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            headerRight: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.xs,
              ),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSizes.lg),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.tick_circle_copy, color: Colors.green, size: 14),
                  SizedBox(width: AppSizes.xs),
                  Text(
                    'Answer shown',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // ── Passage ────────────────────────────────────────────────
            passageTitle: passage?.title,
            passageContent: passage?.content,
            passageExpanded: passageExpanded,
            onPassageToggle: () => controller.togglePassage(qn.id),
            // ── Explanation ────────────────────────────────────────────
            explanationExpanded: explanationExpanded,
            onExplanationToggle: () => controller.toggleExpanded(qn.id),
            languageSelected: controller.languageSelected,
            onLanguageChange: (v) => controller.languageSelected.value = v,
          );
        }),
      ),
    );
  }
}
