import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/features/exam/controllers/review_controller.dart';
import 'package:matricmate/features/exam/screens/result/widgets/review_qn_container.dart';
import 'package:matricmate/utils/constants/colors.dart';

class TestReviewScreen extends GetView<ReviewController> {
  const TestReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final result = controller.result;
    final examQn = result.testQuestions;

    return Scaffold(
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
          'Review Answers',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 18.5,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, _) {
          final isLandscape =
              MediaQuery.orientationOf(context) == Orientation.landscape;
          final list = ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: examQn.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: ReviewContainer(qn: examQn[i], result: result),
            ),
          );
          if (!isLandscape) return list;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: list,
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Get.back();
                Get.back();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 15,
                color: AppColors.white,
              ),
              label: const Text(
                'Back to Tests',
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
