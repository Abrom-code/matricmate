import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/features/exam/models/result_model.dart';
import 'package:matricmate/features/exam/screens/result/widgets/review_qn_container.dart';
import 'package:matricmate/features/exam/screens/subject/subjects.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';

class TestReviewScreen extends StatelessWidget {
  const TestReviewScreen({super.key, required this.result});
  final ResultModel result;

  @override
  Widget build(BuildContext context) {
    final examQn = result.testQuestions;
    return Scaffold(
      appBar: Appbar(
        showBackArrow: true,
        title: Text(
          "Review Answers",
          style: Theme.of(
            context,
          ).textTheme.headlineSmall!.apply(color: AppColors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSizes.defaultSpace),
        child: Column(
          spacing: AppSizes.spaceBtwItems,
          children: [...examQn.map((qn) => ReviewContainer(qn: qn, result : result))],
        ),
      ),
      bottomNavigationBar: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Get.offAll(() => SubjectsScreen()),
          child: Row(
            spacing: 10,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_left, color: AppColors.grey),
              Text(
                "Back to Subjects",
                style: Theme.of(
                  context,
                ).textTheme.titleSmall!.apply(color: AppColors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
