import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/features/exam/controllers/review_controller.dart';
import 'package:matricmate/features/exam/screens/result/widgets/review_qn_container.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';

class TestReviewScreen extends GetView<ReviewController> {
  const TestReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final result = controller.result;
    final examQn = result.testQuestions;
    return Scaffold(
      appBar: Appbar(
        showBackArrow: true,
        title: Text(
          'Review Answers',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall!.apply(color: AppColors.white),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppSizes.defaultSpace / 2),
        itemCount: examQn.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.spaceBtwItems),
          child: ReviewContainer(qn: examQn[i], result: result),
        ),
      ),
      bottomNavigationBar: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            Get.back();
            Get.back();
          },
          child: Row(
            spacing: 10,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.arrow_left, color: AppColors.grey),
              Text(
                'Back to Tests',
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
