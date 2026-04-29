import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/exam/controllers/question_controller.dart';
import 'package:matricmate/features/exam/screens/ready/widgets/attribute_box.dart';
import 'package:matricmate/features/exam/screens/ready/widgets/timer_container.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class ReadyDialog extends StatelessWidget {
  const ReadyDialog({
    super.key,
    required this.qnCount,
    required this.time,
    required this.testId,
  });
  final int qnCount, time, testId;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFuntions.isDark(context);

    return Dialog(
      backgroundColor: dark ? AppColors.dark : AppColors.light,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Stack(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 600),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: AppSizes.defaultSpace,
                vertical: AppSizes.defaultSpace / 2,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSizes.spaceBtwItems),

                  Text(
                    "Ready To Start?",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSizes.spaceBtwItems),

                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: AppSizes.defaultSpace / 2,
                      runSpacing: AppSizes.defaultSpace,
                      runAlignment: WrapAlignment.center,
                      children: [
                        AttributeBox(
                          icon: Icons.quiz,
                          value: qnCount,
                          label: 'questions',
                        ),
                        AttributeBox(
                          icon: Icons.timer,
                          value: time,
                          label: 'minutes',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSizes.spaceBtwSections),

                  TimerContainer(time: time),

                  const SizedBox(height: AppSizes.spaceBtwSections),

                  /// Start Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Get.offNamed(
                          Routes.questions,
                          arguments: {'test_id': testId},
                        );
                        Get.delete<QuestionController>();
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
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
                          Icon(
                            Icons.start_rounded,
                            size: 20,
                            color: AppColors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.defaultSpace / 2),
                ],
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,

            child: IconButton(
              onPressed: () => Get.back(),
              icon: Icon(Icons.close, color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
