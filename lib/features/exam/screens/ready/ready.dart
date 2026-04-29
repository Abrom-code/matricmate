import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/features/exam/screens/ready/widgets/attribute_box.dart';
import 'package:matricmate/features/exam/screens/ready/widgets/instruction_box.dart';
import 'package:matricmate/features/exam/screens/ready/widgets/timer_container.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class ReadyScreen extends GetView<ReadyController> {
  const ReadyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFuntions.isDark(context);
    return Scaffold(
      appBar: Appbar(
        showBackArrow: true,
        title: Text("Start Exam", style: TextStyle(color: AppColors.white)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Ready To Start?",
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: AppSizes.spaceBtwItems / 2),

            Text(
              controller.title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge!.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: AppSizes.spaceBtwSections),

            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSizes.defaultSpace / 2,
                runSpacing: AppSizes.defaultSpace,
                runAlignment: WrapAlignment.center,
                children: [
                  AttributeBox(icon: Icons.quiz, value: controller.qnCount, label: 'questions'),
                  AttributeBox(icon: Icons.timer, value: controller.time, label: 'minutes'),
                  AttributeBox(
                    icon: Icons.military_tech,
                    value: controller.point,
                    label: 'points',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.spaceBtwSections),

            TimerContainer(time: controller.time),
            const SizedBox(height: AppSizes.spaceBtwSections),

            Text(
              "Instructions".toUpperCase(),
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                color: dark ? AppColors.darkGrey : AppColors.darkerGrey,
              ),
            ),
            const SizedBox(height: AppSizes.spaceBtwItems),

            InstructionBox(
              text: "You cannot pause the exam once started",
              icon: Icons.pause_circle_outline,
            ),
            const SizedBox(height: AppSizes.spaceBtwItems),
            InstructionBox(
              text: 'You can review your answers after completed',
              icon: Icons.rate_review_outlined,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SizedBox(
        width: double.infinity,
        child: Container(
          padding: EdgeInsets.all(AppSizes.defaultSpace / 2),
          child: ElevatedButton(
            onPressed: () => Get.offNamed(
              Routes.questions,
              arguments: {'test_id': controller.testId},
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Start Exam",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                    fontSize: 19,
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Icon(Icons.start_rounded, size: 20, color: AppColors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ReadyController extends GetxController {
  static ReadyController get intstance => Get.find();

  late int testId, point, qnCount, time;
  late String title;
  @override
  void onInit() {
    final argument = Get.arguments;
    testId = argument['test_id'];
    point = argument['point'];
    qnCount = argument['qn_count'];
    time = argument['time'];
    title = argument['title'];
    super.onInit();
  }
}
