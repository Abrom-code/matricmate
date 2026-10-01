import 'package:flutter/material.dart';
import 'package:matricmate/common/widgets/exam/question_content_renderer.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class QuestionSection extends StatelessWidget {
  const QuestionSection({super.key, required this.examQn, this.qnNumber});

  final int? qnNumber;
  final String examQn;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    final baseStyle = TextStyle(
      fontSize: 16.5,
      fontWeight: FontWeight.w400,
      height: 1.55,
      letterSpacing: 0.1,
      color: dark ? AppColors.textWhite : AppColors.textPrimary,
    );

    final numberStyle = baseStyle.copyWith(
      fontSize: 17,
      fontWeight: FontWeight.w700,
      color: dark ? AppColors.white : AppColors.primary,
    );

    return QuestionContentRenderer(
      text: examQn,
      qnNumber: qnNumber,
      baseStyle: baseStyle,
      numberStyle: numberStyle,
    );
  }
}

