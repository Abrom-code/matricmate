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
      textAlign: TextAlign.justify,
      TextSpan(
        children: [
          TextSpan(
            text: '$qnNumber. ',
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
              fontSize: 17,
              color: dark ? AppColors.grey : AppColors.darkerGrey,
            ),
          ),
          TextSpan(
            text: examQn,
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
              fontSize: 17,
              color: dark ? AppColors.grey : AppColors.darkerGrey,
            ),
          ),
        ],
      ),
    );
  }
}
