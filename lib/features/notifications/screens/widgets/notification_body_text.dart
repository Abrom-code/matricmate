import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:matricmate/features/notifications/services/notification_link_parser.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

/// Renders notification body text with interactive, clickable links.
///
/// Supports BBCode `[a]url[/a]`, `[a href="url"]text[/a]`, `[a]text|url[/a]`,
/// HTML `<a href="...">text</a>`, markdown `[text](url)`, and plain URLs.
/// Manages [TapGestureRecognizer] lifecycle to prevent memory and gesture leaks.
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

    final segments = NotificationLinkParser.parseSegments(
      widget.text,
      payload: widget.payload,
    );

    if (segments.isEmpty) {
      return Text(
        widget.text,
        style: baseStyle,
      );
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

        spans.add(
          TextSpan(
            text: seg.text,
            style: effectiveLinkStyle,
            recognizer: recognizer,
            mouseCursor: SystemMouseCursors.click,
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: seg.text,
            style: seg.applyFormatting(baseStyle),
          ),
        );
      }
    }

    return SelectionArea(
      child: Text.rich(
        TextSpan(children: spans),
        style: baseStyle,
      ),
    );
  }
}
