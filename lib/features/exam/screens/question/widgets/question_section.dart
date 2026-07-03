import 'package:flutter/material.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class QuestionSection extends StatelessWidget {
  const QuestionSection({super.key, required this.examQn, this.qnNumber});

  final int? qnNumber;
  final String examQn;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    return Text.rich(
      textAlign: TextAlign.left,
      TextSpan(
        children: [
          TextSpan(
            text: '$qnNumber. ',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.6,
              color: dark ? AppColors.grey : AppColors.darkerGrey,
            ),
          ),
          TextSpan(
            text: examQn,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.6,
              letterSpacing: 0.1,
              color: dark ? AppColors.grey : AppColors.darkerGrey,
            ),
          ),
        ],
      ),
    );
  }
}
