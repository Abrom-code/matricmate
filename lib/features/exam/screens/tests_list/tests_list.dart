import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/bindings/test_binding.dart';
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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSizes.defaultSpace),
        child: Obx(() {
          final test = controller.getTestsByGradeAndChapter(grade, chapterId);
          return Column(
            spacing: AppSizes.spaceBtwItems,
            children: [
              ...test.map((test) {
                final hasTests = controller.testHasQuestions[test.id] ?? false;
                return TestTile(
                  testName: test.title,
                  onTap: () {
                    if (hasTests) {
                      Get.to(
                        () => QuestionScreen(),
                        binding: TestBinding(),
                        arguments: [

                      ]);
                    } else {
                      AppHelperFuntions.showAlert("Alert", "No Question");
                    }
                  },
                );
              }),
            ],
          );
        }),
      ),
    );
  }
}
