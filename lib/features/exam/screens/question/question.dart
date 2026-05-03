import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
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
        final bool hasData = controller.testQuestions.isNotEmpty;
        final currentQ = hasData
            ? controller.testQuestions[controller.currentIndex.value]
            : null;

        return Scaffold(
          appBar: Appbar(
            leadingIcon: Icons.close,
            leadingIconColor: !dark ? AppColors.dark : AppColors.light,
            leadingOnPressed: () => AppHelperFuntions.showAppDialog(
              context,
              "Want to Exit?",
              "Your progress will not be saved.",
              () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),

            title: (currentQ != null && currentQ.passageId != null)
                ? PassageLayoutCtrl(controller: controller)
                : Text(
                    hasData
                        ? "${controller.currentIndex.value + 1} of ${controller.testQuestions.length} ${controller.isTimed ? '(${controller.formattedTime(controller.remainingSeconds.value)})' : ''}"
                        : "Loading...",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
            centerTitle: true,
            actions: [
              if (currentQ != null)
                Obx(() {
                  final isSaved = controller.isBookmarked(currentQ.id);
                  return IconButton(
                    onPressed: isSaved
                        ? () =>
                              bookmarkController.removeFromBookmark(currentQ.id)
                        : () => bookmarkController.addToBookmark(currentQ.id),
                    icon: Icon(
                      isSaved
                          ? Iconsax.archive_minus
                          : Iconsax.archive_add_copy,
                      color: isSaved ? AppColors.primary : null,
                    ),
                  );
                }),
            ],
            backgroundColor: Colors.transparent,
          ),

          body:
              (controller.isLoading.value || controller.isPassageLoading.value)
              ? const AppCircularLoading()
              : SingleChildScrollView(
                  controller: pageScrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// PASSAGE SECTION
                      if (currentQ?.passageId != null) ...[
                        PassageContainer(controller: controller),
                      ],

                      /// QUESTION SECTION
                      if (currentQ != null) ...[
                        QuesitonSection(question: currentQ),
                      ],
                    ],
                  ),
                ),
        );
      }),
    );
  }
}
