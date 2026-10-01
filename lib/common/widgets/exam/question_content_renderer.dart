import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:matricmate/common/widgets/exam/bb_table_widget.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:matricmate/utils/helpers/question_content_parser.dart';
import 'package:matricmate/utils/helpers/rich_text_parser.dart';

/// Centralized question content renderer supporting:
/// - Normal text & headings
/// - Custom BBCode tags ([b], [i], [u], [s], [bi], [sup], [sub], [h], [c=#...])
/// - Markdown (**bold**, *italic*, ~~strikethrough~~)
/// - Inline mathematics: \(...\) and $...$
/// - Block mathematics: \[...\] and $$...$$ (centered, responsive, scrollable)
/// - Tables: [table][row][cell]...[/cell][/row][/table]
/// - Light & Dark themes
/// - Optional prepended question order number (e.g. "1. ")
class QuestionContentRenderer extends StatelessWidget {
  const QuestionContentRenderer({
    super.key,
    required this.text,
    this.baseStyle,
    this.qnNumber,
    this.numberStyle,
    this.textAlign = TextAlign.left,
  });

  final String text;
  final TextStyle? baseStyle;
  final int? qnNumber;
  final TextStyle? numberStyle;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();

    final dark = AppHelperFunctions.isDark(context);

    final effectiveBaseStyle = baseStyle ??
        TextStyle(
          fontSize: 16.5,
          fontWeight: FontWeight.w400,
          height: 1.55,
          letterSpacing: 0.1,
          color: dark ? AppColors.textWhite : AppColors.textPrimary,
        );

    final effectiveNumberStyle = numberStyle ??
        effectiveBaseStyle.copyWith(
          fontSize: (effectiveBaseStyle.fontSize ?? 16.5) * 1.05,
          fontWeight: FontWeight.w700,
          color: dark ? AppColors.white : AppColors.primary,
        );

    // If no block elements (tables, block math), render a single Text.rich
    if (!QuestionContentParser.hasBlockElements(text)) {
      final span = RichTextParser.parse(text, effectiveBaseStyle);
      return Text.rich(
        qnNumber != null
            ? TextSpan(
                children: [
                  TextSpan(text: '$qnNumber. ', style: effectiveNumberStyle),
                  span,
                ],
              )
            : span,
        textAlign: textAlign,
      );
    }

    final segments = QuestionContentParser.splitSegments(text);
    if (segments.isEmpty) return const SizedBox.shrink();

    final widgets = <Widget>[];
    bool numberPrepended = false;

    for (final seg in segments) {
      if (seg.isTable) {
        widgets.add(const SizedBox(height: 8));
        widgets.add(
          BBTableWidget(
            rows: seg.tableRows!,
            baseStyle: effectiveBaseStyle,
          ),
        );
        widgets.add(const SizedBox(height: 8));
      } else if (seg.isBlockMath) {
        widgets.add(
          _BlockMathWidget(
            tex: seg.mathTex ?? '',
            raw: seg.mathRaw ?? '',
            style: effectiveBaseStyle,
          ),
        );
      } else if (seg.isText) {
        final textSpan = numberPrepended || qnNumber == null
            ? RichTextParser.parse(seg.text!, effectiveBaseStyle)
            : TextSpan(
                children: [
                  TextSpan(text: '$qnNumber. ', style: effectiveNumberStyle),
                  RichTextParser.parse(seg.text!, effectiveBaseStyle),
                ],
              );
        numberPrepended = true;
        widgets.add(Text.rich(textSpan, textAlign: textAlign));
      }
    }

    // Edge case: entire content was a table or block math without any text segment
    if (!numberPrepended && qnNumber != null) {
      widgets.insert(
        0,
        Text(
          '$qnNumber.',
          style: effectiveNumberStyle,
          textAlign: textAlign,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }
}

class _BlockMathWidget extends StatelessWidget {
  const _BlockMathWidget({
    required this.tex,
    required this.raw,
    required this.style,
  });

  final String tex;
  final String raw;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fallbackColor = dark ? Colors.white : const Color(0xFF0F172A);
    final effectiveColor = style.color ?? fallbackColor;
    final effectiveStyle = style.copyWith(
      fontSize: (style.fontSize ?? 16.0) * 1.08,
      color: effectiveColor,
    );

    Widget mathWidget;
    try {
      mathWidget = Math.tex(
        tex,
        mathStyle: MathStyle.display,
        textStyle: effectiveStyle,
        onErrorFallback: (err) => Text(
          raw,
          style: effectiveStyle,
        ),
      );
    } catch (_) {
      mathWidget = Text(raw, style: effectiveStyle);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: mathWidget,
          ),
        ),
      ),
    );
  }
}
