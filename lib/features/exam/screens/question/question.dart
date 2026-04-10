import 'package:flutter/material.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/features/exam/screens/question/widgets/normal_questions_section.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class QuestionScreen extends StatelessWidget {
  const QuestionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFuntions.isDark(context);
    final examQn = 10;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // Call your static method here
        AppHelperFuntions.showExitDialog(context);
      },
      child: Scaffold(
        appBar: Appbar(
          leadingIcon: Icons.close,
          leadingIconColor: !dark ? AppColors.dark : AppColors.light,
          leadingOnPressed: () => AppHelperFuntions.showExitDialog(context),
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
