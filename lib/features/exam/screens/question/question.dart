import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/features/exam/controllers/question_controller.dart';
import 'package:matricmate/features/exam/screens/question/widgets/normal_questions_section.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class QuestionScreen extends GetView<QuestionController> {
  const QuestionScreen({
    super.key,
    required this.type,
    this.subject,
    required this.subjectId,
    this.grade,
    this.chapterId,
    required this.title,
    this.testId,
  });
  final String type;
  final String? subject;
  final int subjectId;
  final int? grade, chapterId;
  final String title;
  final int? testId;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFuntions.isDark(context);
    final examQn = 10;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // Call your static method here
        AppHelperFuntions.showAppDialog(
          context,
          "Want to Exit?",
          "Your progress will be saved.",
          () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
        );
      },
      child: Scaffold(
        appBar: Appbar(
          leadingIcon: Icons.close,
          leadingIconColor: !dark ? AppColors.dark : AppColors.light,
          leadingOnPressed: () => AppHelperFuntions.showAppDialog(
            context,
            "Want to Exit?",
            "Your progress will be saved.",
            () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
          ),
          title: Text(
            "Question 3 of 20",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          centerTitle: true,
          actions: [
            IconButton(onPressed: () {}, icon: Icon(Icons.bookmark_outline)),
          ],
          backgroundColor: Colors.transparent,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(AppSizes.defaultSpace),

            child: NormarQuesionsSection(examQn: examQn),
          ),
        ),
      ),
    );
  }
}
