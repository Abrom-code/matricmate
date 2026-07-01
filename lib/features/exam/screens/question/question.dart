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

class QuestionScreen extends StatefulWidget {
  const QuestionScreen({super.key});

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  final ScrollController _pageScrollController = ScrollController();

  @override
  void dispose() {
    _pageScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<QuestionController>();
    final bookmarkController = Get.find<BookmarkController>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        AppHelperFunctions.showAppDialog(
          context,
          'Want to Exit?',
          'Your progress will be saved.',
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
            leadingIconColor: AppColors.error,
            leadingOnPressed: () => AppHelperFunctions.showAppDialog(
              context,
              'Want to Exit?',
              'Your progress will not be saved.',
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
                        : 'Loading...',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium!.copyWith(color: AppColors.primary),
                  ),
            centerTitle: true,
            actions: [
              if (currentQ != null)
                Obx(() {
                  final isSaved = controller.isBookmarked(currentQ.id);
                  return IconButton(
                    onPressed: isSaved
                        ? () => bookmarkController.removeFromBookmark(
                            currentQ.id)
                        : () => bookmarkController.addToBookmark(currentQ.id),
                    icon: Icon(
                      isSaved
                          ? Iconsax.archive_minus
                          : Iconsax.archive_add_copy,
                      color: AppColors.primary,
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
                  controller: _pageScrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (currentQ?.passageId != null) ...[
                        PassageContainer(controller: controller),
                      ],
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
