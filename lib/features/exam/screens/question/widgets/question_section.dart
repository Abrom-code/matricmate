import 'package:flutter/material.dart';
import 'package:matricmate/common/widgets/exam/bb_table_widget.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/bb_table_parser.dart';
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

    final numberStyle = baseStyle.copyWith(
      fontSize: 17,
      fontWeight: FontWeight.w600,
    );

    // ── No table: original single Text.rich with prepended number ─────
    if (!BBTableParser.containsTable(examQn)) {
      return Text.rich(
        TextSpan(
          children: [
            if (qnNumber != null)
              TextSpan(text: '$qnNumber. ', style: numberStyle),
            RichTextParser.parse(examQn, baseStyle),
          ],
        ),
        textAlign: TextAlign.left,
      );
    }

    // ── Has table: Column of segments, number prepended to first text ──
    final segments = BBTableParser.splitSegments(examQn);
    final widgets = <Widget>[];
    bool numberPrepended = false;

    for (final seg in segments) {
      if (seg.isTable) {
        widgets.add(const SizedBox(height: 8));
        widgets.add(BBTableWidget(rows: seg.tableRows!, baseStyle: baseStyle));
        widgets.add(const SizedBox(height: 8));
      } else {
        // Prepend "N. " to the very first text segment only
        final textSpan = numberPrepended || qnNumber == null
            ? RichTextParser.parse(seg.text!, baseStyle)
            : TextSpan(children: [
                TextSpan(text: '$qnNumber. ', style: numberStyle),
                RichTextParser.parse(seg.text!, baseStyle),
              ]);
        numberPrepended = true;
        widgets.add(Text.rich(textSpan, textAlign: TextAlign.left));
      }
    }

    // Edge case: text was only a table (no text segments) — number floats above
    if (!numberPrepended && qnNumber != null) {
      widgets.insert(
        0,
        Text('$qnNumber.', style: numberStyle, textAlign: TextAlign.left),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}
