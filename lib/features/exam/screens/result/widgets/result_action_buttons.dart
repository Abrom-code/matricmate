import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/controllers/navigation_controller.dart';
import 'package:matricmate/features/exam/controllers/pilot_exam_controller.dart';
import 'package:matricmate/features/exam/models/pilot_exam_model.dart';
import 'package:matricmate/features/exam/models/result_model.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

/// Review Answers + Back + Home buttons shown at the bottom of the result screen.
class ResultActionButtons extends StatelessWidget {
  const ResultActionButtons({super.key, required this.result});

  final ResultModel result;

  @override
  Widget build(BuildContext context) {
    PilotExamSubjectModel? pilotSubject;
    if (Get.isRegistered<PilotExamController>()) {
      final pilotCtrl = Get.find<PilotExamController>();
      for (final s in pilotCtrl.examSubjects) {
        if (s.testId == result.testId) {
          pilotSubject = s;
          break;
        }
      }
    }

    return Column(
      children: [
        // Review Answers — primary filled
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Get.toNamed(Routes.review, arguments: result),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.fact_check_outlined, size: 20),
            label: const Text(
              'Review Answers',
              style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        if (pilotSubject != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                final subject = pilotSubject!;
                final user = UserController.instance.user.value;
                AppHelperFunctions.showAppDialog(
                  context,
                  'Redo ${subject.subjectName}?',
                  'This will reset your previous score and allow you to retake the exam from question 1 with a fresh timer.',
                  () async {
                    Navigator.of(context, rootNavigator: true).pop();
                    Get.back(); // Pop ResultScreen
                    await PilotExamController.instance.redoSubjectExam(
                      subject,
                      user,
                    );
                  },
                  okText: 'Redo Exam',
                  cancelText: 'Cancel',
                  icon: Icons.refresh_rounded,
                  iconColor: AppColors.primary,
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(
                'Redo Pilot Exam',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),

        // Back + Home — side by side
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Get.back(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 15),
                label: const Text(
                  'Back',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  NavigationController.instance.selectedIdx.value = 0;
                  Get.offAllNamed(Routes.navigationMenu);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.10),
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                icon: const Icon(Icons.home_rounded, size: 18),
                label: const Text(
                  'Home',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
