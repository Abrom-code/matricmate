import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/features/exam/controllers/bookmark_controller.dart';
import 'package:matricmate/features/exam/controllers/question_controller.dart';
import 'package:matricmate/features/exam/screens/question/widgets/normal_questions_section.dart';
import 'package:matricmate/features/exam/screens/question/widgets/passage_container.dart';
import 'package:matricmate/features/exam/screens/question/widgets/passage_layout_ctrl.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class QuestionScreen extends GetView<QuestionController> {
  const QuestionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookmarkController = Get.find<BookmarkController>();
    final dark = AppHelperFuntions.isDark(context);
    final ScrollController pageScrollController = ScrollController();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        AppHelperFuntions.showAppDialog(
          context,
          "Want to Exit?",
          "Your progress will be saved.",
          () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
        );
      },
      child: Obx(() {
        if (controller.isLoading.value || controller.isPassageLoading.value) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (controller.blocks.isEmpty) {
          return const Scaffold(
            body: Center(child: Text("No Questions Available")),
          );
        }

        final currentQ =
            controller.testQuestions[controller.currentIndex.value];

        final block = controller.blocks[controller.currentBlockIndex.value];
        return Scaffold(
          appBar: Appbar(
            leadingIcon: Icons.close,
            leadingIconColor: !dark ? AppColors.dark : AppColors.light,
            leadingOnPressed: () => AppHelperFuntions.showAppDialog(
              context,
              "Want to Exit?",
              "Your progress will not saved.",
              () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
            title: currentQ.passageId != null
                ? PassageLayoutCtrl(controller: controller)
                : Text(
                    "Question ${controller.currentIndex.value + 1} of ${controller.testQuestions.length}",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
            centerTitle: true,
            actions: [
              Obx(() {
                final currentQ =
                    controller.testQuestions[controller.currentIndex.value];

                final isSaved = controller.isBookmarked(currentQ.id);

                return IconButton(
                  onPressed: isSaved
                      ? () => bookmarkController.removeFromBookmark(currentQ.id)
                      : () => bookmarkController.addToBookmark(currentQ.id),
                  icon: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_outline,
                    color: isSaved ? AppColors.primary : null,
                  ),
                );
              }),
            ],
            backgroundColor: Colors.transparent,
          ),
          body: SingleChildScrollView(
            controller: pageScrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// PASSAGE
                if (currentQ.passageId != null) ...[
                  PassageContainer(controller: controller, block: block),
                ],

                ///  ONLY ONE QUESTION
                QuesitonSection(question: currentQ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
