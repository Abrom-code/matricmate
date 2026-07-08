import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
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
    required this.id,
  });
  final int qnCount, time, testId, id;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    final controller = Get.put(ReadyController());
    return Dialog(
      backgroundColor: dark ? AppColors.dark : AppColors.light,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Stack(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.defaultSpace,
                vertical: AppSizes.defaultSpace / 2,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSizes.spaceBtwItems),

                  Text(
                    'Ready To Start?',
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
                          icon: Iconsax.message_question_copy,
                          value: qnCount,
                          label: 'questions',
                        ),
                        AttributeBox(
                          icon: Iconsax.timer_1_copy,
                          value: time,
                          label: 'minutes',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSizes.spaceBtwSections),

                  Obx(
                    () => TimerContainer(
                      time: time,
                      value: controller.isExamMode.value,
                      onChange: controller.changeExamMode,
                    ),
                  ),

                  const SizedBox(height: AppSizes.spaceBtwSections),

                  /// Start Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Get.offNamed(
                          Routes.questions,
                          arguments: {
                            'test_id': testId,
                            'is_timed': controller.isExamMode.value,
                            'is_exam_mode': controller.isExamMode.value,
                            'time': time,
                            'id': id,
                          },
                        );
                        Get.delete<QuestionController>();
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Start Exam',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                              fontSize: 19,
                            ),
                          ),
                          SizedBox(width: AppSizes.sm),
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
              icon: const Icon(Iconsax.close_circle_copy, color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class ReadyController extends GetxController {
  static ReadyController get instance => Get.find();
  final isExamMode = false.obs;

  void changeExamMode() {
    isExamMode.value = !isExamMode.value;
  }
}
