import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/features/exam/controllers/question_controller.dart';
import 'package:matricmate/features/exam/models/test_model.dart';
import 'package:matricmate/features/exam/screens/question/widgets/normal_questions_section.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class QuestionScreen extends GetView<QuestionController> {
  const QuestionScreen({super.key, required this.test});
  final TestModel test;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFuntions.isDark(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadTestQuestions(test.id);
    });

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
        if (controller.isLoading.value) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (controller.testQuestions.isEmpty) {
          return const Scaffold(
            body: Center(child: Text("No Questions Available")),
          );
        }

        return Scaffold(
          appBar: Appbar(
            leadingIcon: Icons.close,
            leadingIconColor: !dark ? AppColors.dark : AppColors.light,
            leadingOnPressed: () => AppHelperFuntions.showAppDialog(
              context,
              "Want to Exit?",
              "Your progress will be saved.",
              () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
            title: Text(
              "Question ${controller.currentIndex.value + 1} of ${controller.testQuestions.length}",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            centerTitle: true,
            actions: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.bookmark_outline),
              ),
            ],
            backgroundColor: Colors.transparent,
          ),
          body: const SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(AppSizes.defaultSpace),
              child: NormarQuesionsSection(),
            ),
          ),
        );
      }),
    );
  }
}
