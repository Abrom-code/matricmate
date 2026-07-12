import 'package:flutter/material.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:matricmate/utils/helpers/rich_text_parser.dart';

/// Renders a parsed BBCode table as a Flutter [Table] widget.
///
/// - First row is treated as the header: bold text, teal-tinted background.
/// - Body rows have alternating-subtle background and grey dividers.
/// - Wraps in a [SingleChildScrollView] (horizontal) to prevent overflow on
///   narrow screens.
/// - Cell content is passed through [RichTextParser] so inline tags like
///   [b], [i], [c=…] still work inside cells.
class BBTableWidget extends StatelessWidget {
  const BBTableWidget({super.key, required this.rows, this.baseStyle});

  /// Parsed rows — `rows[0]` is the header row.
  final List<List<String>> rows;

  /// Optional override for the body text style. When null the widget derives
  /// a sensible default from the current [Theme].
  final TextStyle? baseStyle;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();

    final dark = AppHelperFunctions.isDark(context);

    // Derive column count from the widest row so ragged tables don't crash.
    final colCount = rows.map((r) => r.length).reduce((a, b) => a > b ? a : b);
    if (colCount == 0) return const SizedBox.shrink();

    final effectiveBaseStyle =
        baseStyle ??
        TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: dark
              ? AppColors.white.withValues(alpha: 0.85)
              : AppColors.darkerGrey,
        );

    final headerStyle = effectiveBaseStyle.copyWith(
      fontWeight: FontWeight.w700,
      color: AppColors.primary,
    );

    final headerBg = dark
        ? AppColors.primary.withValues(alpha: 0.18)
        : Colors.teal.shade50;

    final borderSide = BorderSide(color: Colors.grey.shade300, width: 0.8);
    final tableBorder = TableBorder(
      top: borderSide,
      bottom: borderSide,
      left: borderSide,
      right: borderSide,
      horizontalInside: borderSide,
      verticalInside: borderSide,
    );

    // Build TableRow list
    final tableRows = <TableRow>[];
    for (int i = 0; i < rows.length; i++) {
      final isHeader = i == 0;
      final row = rows[i];

      final cells = List.generate(colCount, (col) {
        final content = col < row.length ? row[col] : '';
        final style = isHeader ? headerStyle : effectiveBaseStyle;

        return TableCell(
          child: Container(
            color: isHeader
                ? headerBg
                : (i.isEven && !isHeader)
                ? (dark
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.grey.shade50)
                : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            // Constrains each cell to a max width so long text wraps,
            // while still shrinking to fit shorter content.
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: Text.rich(RichTextParser.parse(content, style)),
            ),
          ),
        );
      });

      tableRows.add(TableRow(children: cells));
    }

    final screenWidth = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: screenWidth - 48),
        child: Table(
          border: tableBorder,
          // IntrinsicColumnWidth sizes each column to its content,
          // but maxWidth caps it so overly long text wraps rather than
          // stretching the column indefinitely.
          defaultColumnWidth: const IntrinsicColumnWidth(),
          children: tableRows,
        ),
      ),
    );
  }
}
