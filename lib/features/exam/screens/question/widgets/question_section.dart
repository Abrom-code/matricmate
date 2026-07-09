import 'package:flutter/material.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:matricmate/utils/helpers/rich_text_parser.dart';

class QuestionSection extends StatelessWidget {
  const QuestionSection({super.key, required this.examQn, this.qnNumber});

  final int? qnNumber;
  final String examQn;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    final baseStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.6,
      letterSpacing: 0.1,
      color: dark ? AppColors.grey : AppColors.darkerGrey,
    );

    final numberSpan = TextSpan(
      text: qnNumber != null ? '$qnNumber. ' : '',
      style: baseStyle.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    );

    // Parse the question text for rich tags, then prepend the number span
    final parsedQuestion = RichTextParser.parse(examQn, baseStyle);

    return Text.rich(
      TextSpan(
        children: [
          numberSpan,
          parsedQuestion,
        ],
      ),
      textAlign: TextAlign.left,
    );
  }
}
