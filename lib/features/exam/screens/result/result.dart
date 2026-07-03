import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/common/widgets/helpers/badges.dart';
import 'package:matricmate/features/exam/models/result_model.dart';
import 'package:matricmate/navigation_menu.dart';
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
    final ratio = result.testQuestions.isEmpty
        ? 0.0
        : result.correctAnswers / result.testQuestions.length;
    final examBadge = ExamBadgeHelper.getBadge(ratio);

    return Scaffold(
      appBar: Appbar(
        title: Text(
          'Your Result',
          style: Theme.of(context)
              .textTheme
              .headlineMedium!
              .apply(color: AppColors.white),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.defaultSpace),
          child: Column(
            children: [
              // ── Badge circle ────────────────────────────────────────
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

              Text('TEST RESULT',
                  style: Theme.of(context).textTheme.titleLarge),
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

              // ── Review Answers — primary filled ─────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      Get.toNamed(Routes.review, arguments: result),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.borderRadiusLg),
                    ),
                  ),
                  icon: const Icon(Iconsax.search_status_1_copy, size: 20),
                  label: const Text(
                    'Review Answers',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.spaceBtwItems),

              // ── Back to Tests + Back to Home — side by side ──────────
              Row(
                children: [
                  // Back to Tests — outlined
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side:
                            const BorderSide(color: AppColors.primary),
                        padding:
                            const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              AppSizes.borderRadiusLg),
                        ),
                      ),
                      icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 16),
                      label: const Text(
                        'Back',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.spaceBtwItems),

                  // Back to Home — filled teal
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Result was pushed via Get.offNamed inside the nested
                        // navigator, so the stack is: [result]. We need to
                        // replace it with home and reset the tab index.
                        final navCtrl = NavigationController.instance;
                        navCtrl.selectedIdx.value = 0;
                        navCtrl.navigatorKey.currentState
                            ?.pushNamedAndRemoveUntil(
                          Routes.home,
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.12),
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        padding:
                            const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              AppSizes.borderRadiusLg),
                          side: BorderSide(
                            color: AppColors.primary
                                .withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.home_outlined, size: 18),
                      label: const Text(
                        'Home',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
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
    super.onInit();
    final args = Get.arguments;
    if (args == null || args is! Map || args['result'] is! ResultModel) {
      Get.back();
      return;
    }
    result = args['result'] as ResultModel;
  }
}
