import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/common/widgets/helpers/badges.dart';
import 'package:matricmate/features/exam/models/result_model.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class ResultScreen extends GetView<ResultController> {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final result = controller.result;
    final dark = AppHelperFunctions.isDark(context);
    final examBadge = ExamBadgeHelper.getBadge(
      result.correctAnswers / result.testQuestions.length,
    );
    return Scaffold(
      appBar: Appbar(
        title: Text(
          'Your Result',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium!.apply(color: AppColors.white),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.defaultSpace),
          child: Column(
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(150),
                  color: dark
                      ? const Color.fromARGB(119, 79, 79, 79)
                      : const Color(0xFFe7eae7),
                ),

                child: Stack(
                  children: [
                    Positioned(
                      top: 10,
                      right: 30,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(70),
                          color: Colors.yellow,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 10,
                      child: Container(
                        width: 15,
                        height: 15,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.greenAccent,
                        ),
                      ),
                    ),
                    Center(
                      child: Icon(
                        examBadge.icon,
                        color: examBadge.color,
                        size: 100,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.spaceBtwSections),

              Text(
                'TEST RESULT',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSizes.spaceBtwItems / 2),

              Text(
                '${result.correctAnswers}/${result.testQuestions.length}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSizes.spaceBtwSections),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      Get.toNamed(Routes.review, arguments: result),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 10,
                    children: [
                      const Icon(
                        Iconsax.search_status_1_copy,
                        color: AppColors.white,
                      ),
                      Text(
                        'Review Answers',
                        style: Theme.of(
                          context,
                        ).textTheme.titleSmall!.apply(color: AppColors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.spaceBtwItems),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Get.back(),
                  child: Row(
                    spacing: 10,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.arrow_left, color: AppColors.primary),
                      Text(
                        'Back to Tests',
                        style: Theme.of(
                          context,
                        ).textTheme.titleSmall!.apply(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ResultController extends GetxController {
  static ResultController get instance => Get.find();

  late ResultModel result;

  @override
  void onInit() {
    result = Get.arguments['result'];
    super.onInit();
  }
}
