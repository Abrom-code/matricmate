import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/bindings/question_binding.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/common/widgets/tiles/test_tile.dart';
import 'package:matricmate/features/exam/controllers/test_controller.dart';
import 'package:matricmate/features/exam/screens/question/question.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class TestListScreen extends GetView<TestController> {
  const TestListScreen({
    super.key,
    required this.subject,
    required this.chapter,
    this.chapterId,
    this.chapterNumber,
    this.grade,
  });
  final String subject, chapter;
  final int? chapterId;
  final int? chapterNumber, grade;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Appbar(
        showBackArrow: true,
        title: Text(
          '$subject - $chapter'.toUpperCase(),
          style: Theme.of(
            context,
          ).textTheme.titleSmall!.apply(color: AppColors.white),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.more_vert, color: AppColors.white),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.defaultSpace),
        child: Obx(() {
          final tests = controller.getTestsByGradeAndChapter(grade, chapterId);

          if (tests.isEmpty) {
            return const Center(child: Text("No Tests Found"));
          }

          return ListView.builder(
            itemCount: tests.length,
            itemBuilder: (context, index) {
              final test = tests[index];

              final hasQn = controller.testHasQuestions[test.id] ?? false;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.spaceBtwItems),
                child: TestTile(
                  testName: test.title,
                  onTap: () {
                    if (!hasQn) {
                      AppHelperFuntions.showAlert(
                        "No Questions",
                        "This test has no questions",
                      );
                      return;
                    }

                    AppHelperFuntions.showAppDialog(
                      context,
                      "Want to take a test?",
                      "You will be redirected to questions section.",
                      () => Get.off(
                        () => QuestionScreen(
                          testId: test.id,
                          subject: subject,
                          title: test.title,
                          type: test.type,
                          subjectId: test.subjectId,
                        ),
                        binding: QuestionBinding(),
                      ),
                    );
                  },
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
