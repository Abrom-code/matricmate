import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:matricmate/common/widgets/exam/bb_table_widget.dart';
import 'package:matricmate/features/notifications/services/notification_link_parser.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:matricmate/utils/helpers/question_content_parser.dart';
import 'package:matricmate/utils/helpers/rich_text_parser.dart';

/// Renders notification body text with interactive, clickable links and full
/// support for question and explanation formatting tags:
/// - Multiple interactive links: `[a]...[/a]`, `[a href="..."]`, `[a=...]`, `[a]text|url[/a]`
/// - LaTeX mathematics: inline (`$...$`, `\(...\)`) and block (`$$...$$`, `\[...\]`)
/// - BBCode formatting: `[b]`, `[i]`, `[u]`, `[s]`, `[bi]`, `[sup]`, `[sub]`, `[h]`, `[c=#hex]`
/// - Markdown: `**bold**`, `*italic*`, `~~strikethrough~~`, `# Heading`
/// - Data tables: `[table][row][cell]...[/cell][/row][/table]`
///
/// Manages [TapGestureRecognizer] lifecycle safely to prevent memory and gesture leaks.
class NotificationBodyText extends StatefulWidget {
  const NotificationBodyText({
    super.key,
    required this.text,
    this.payload,
    this.style,
    this.linkStyle,
    this.onLinkTap,
  });

  /// Raw notification body string.
  final String text;

  /// Optional notification payload containing deep-link data or fallback URLs.
  final Map<String, dynamic>? payload;

  /// Base style for normal text.
  final TextStyle? style;

  /// Custom styling override for interactive link text.
  final TextStyle? linkStyle;

  /// Optional callback invoked when a link is clicked. If null, navigates automatically.
  final void Function(String url)? onLinkTap;

  @override
  State<NotificationBodyText> createState() => _NotificationBodyTextState();
}

class _NotificationBodyTextState extends State<NotificationBodyText> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();

    final dark = AppHelperFunctions.isDark(context);
    final defaultColor =
        dark ? const Color(0xFFE2E8F0) : const Color(0xFF334155);

    final baseStyle = TextStyle(
      fontSize: 14.5,
      height: 1.6,
      color: defaultColor,
    ).merge(widget.style);

    final linkColor = widget.linkStyle?.color ??
        (dark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7));

    final effectiveLinkStyle = TextStyle(
      fontSize: baseStyle.fontSize,
      height: baseStyle.height,
      color: linkColor,
      fontWeight: FontWeight.w700,
      decoration: TextDecoration.underline,
      decorationColor: linkColor.withValues(alpha: 0.65),
      decorationThickness: 1.5,
    ).merge(widget.linkStyle);

    // If text contains block-level elements (tables or block equations)
    if (QuestionContentParser.hasBlockElements(widget.text)) {
      final blockSegments = QuestionContentParser.splitSegments(widget.text);
      final blockWidgets = <Widget>[];

      for (final bSeg in blockSegments) {
        if (bSeg.isTable && bSeg.tableRows != null) {
          blockWidgets.add(const SizedBox(height: 10));
          blockWidgets.add(
            BBTableWidget(
              rows: bSeg.tableRows!,
              baseStyle: baseStyle,
            ),
          );
          blockWidgets.add(const SizedBox(height: 10));
        } else if (bSeg.isBlockMath) {
          blockWidgets.add(
            _NotificationBlockMath(
              tex: bSeg.mathTex ?? '',
              raw: bSeg.mathRaw ?? '',
              style: baseStyle,
            ),
          );
        } else if (bSeg.isText && bSeg.text != null && bSeg.text!.isNotEmpty) {
          blockWidgets.add(
            _buildRichTextWidget(bSeg.text!, baseStyle, effectiveLinkStyle),
          );
        }
      }

      return SelectionArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: blockWidgets,
        ),
      );
    }

    // Default inline path (handles inline math, all BBCode/Markdown tags, and multiple links)
    return SelectionArea(
      child: _buildRichTextWidget(widget.text, baseStyle, effectiveLinkStyle),
    );
  }

  /// Builds a [Text.rich] combining interactive links and RichTextParser formatting.
  Widget _buildRichTextWidget(
    String rawChunk,
    TextStyle baseStyle,
    TextStyle linkStyle,
  ) {
    final segments = NotificationLinkParser.parseSegments(
      rawChunk,
      payload: widget.payload,
    );

    if (segments.isEmpty) {
      return Text(rawChunk, style: baseStyle);
    }

    final spans = <InlineSpan>[];
    for (final seg in segments) {
      if (seg.isLink && seg.link != null) {
        final targetUrl = seg.link!.url;
        final recognizer = TapGestureRecognizer()
          ..onTap = () {
            if (widget.onLinkTap != null) {
              widget.onLinkTap!(targetUrl);
            } else {
              NotificationLinkParser.launchLink(targetUrl);
            }
          };
        _recognizers.add(recognizer);

        // Parse inner formatting if markup present, else use direct styled TextSpan
        final hasInnerMarkup = seg.text.contains(r'$') ||
            seg.text.contains(r'\') ||
            seg.text.contains('[') ||
            seg.text.contains('*') ||
            seg.text.contains('<');

        if (hasInnerMarkup) {
          final innerLinkSpan = RichTextParser.parse(seg.text, linkStyle);
          spans.add(
            TextSpan(
              children: [innerLinkSpan],
              recognizer: recognizer,
              mouseCursor: SystemMouseCursors.click,
            ),
          );
        } else {
          spans.add(
            TextSpan(
              text: seg.text,
              style: linkStyle,
              recognizer: recognizer,
              mouseCursor: SystemMouseCursors.click,
            ),
          );
        }
      } else {
        // Parse question & explanation formatting (LaTeX math, bold, color, sub/sup, etc.)
        final richSpan = RichTextParser.parse(seg.text, baseStyle);
        spans.add(richSpan);
      }
    }

    return Text.rich(
      TextSpan(children: spans),
      style: baseStyle,
    );
  }
}

/// Responsive horizontal scrollable block math widget for display equations.
class _NotificationBlockMath extends StatelessWidget {
  const _NotificationBlockMath({
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
