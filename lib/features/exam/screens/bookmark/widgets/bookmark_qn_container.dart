import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/common/widgets/exam/question_detail_box.dart';
import 'package:matricmate/features/exam/controllers/bookmark_controller.dart';
import 'package:matricmate/features/exam/models/question_model.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class BookmarkedQnContainer extends GetView<BookmarkController> {
  const BookmarkedQnContainer({super.key, required this.qn});
  final QuestionModel qn;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Scaffold(
      backgroundColor: dark ? AppColors.dark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: Appbar.toolbarHeight(context),
        leading: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: IconButton(
            onPressed: Get.back,
            tooltip: 'Back',
            icon: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ),
        title: const Text(
          'Bookmarked Question',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 18.5,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => AppHelperFunctions.showAppDialog(
              context,
              'Remove bookmark?',
              'This question will be removed from your saved list.',
              () async {
                Get.back();
                Get.back();
                await controller.removeFromBookmark(qn.id);
              },
            ),
            tooltip: 'Remove bookmark',
            icon: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.bookmark_remove_rounded,
                  size: 18,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                controller.subject(qn.subjectId).toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            headerRight: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF10B981),
                    size: 14,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'ANSWER SHOWN',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 0.2,
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
