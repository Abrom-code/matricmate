import 'package:flutter/material.dart';
import 'package:matricmate/utils/constants/colors.dart';

/// Parses a lightweight tag format into a [TextSpan] tree.
///
/// Supported tags:
///   [b]bold[/b]
///   [i]italic[/i]
///   [u]underline[/u]
///   [s]strikethrough[/s]
///   [bi]bold + italic[/bi]
///   [sup]superscript[/sup]  — rendered as smaller raised text
///   [sub]subscript[/sub]    — rendered as smaller lowered text
///   [h]highlight[/h]        — yellow background
///   [c=#RRGGBB]color[/c]    — e.g. [c=#FF0000]red[/c]
///
/// All other text is rendered with the provided [baseStyle].
/// Tags can be nested.
class RichTextParser {
  RichTextParser._();

  // Single regex that captures either a tag or plain text
  static final _tagRe = RegExp(
    r'\[([a-z]+(?:=#[0-9a-fA-F]{3,8})?)\]|\[/([a-z]+)\]',
  );

  /// Parses [text] and returns a [TextSpan] with [baseStyle] applied to
  /// plain segments. Inline tags override specific style properties.
  static TextSpan parse(String text, TextStyle baseStyle) {
    final spans = <InlineSpan>[];
    _parse(text, 0, text.length, baseStyle, spans);
    return TextSpan(children: spans);
  }

  /// Convenience: wraps [parse] in a [Text.rich].
  static Widget widget(
    String text, {
    required TextStyle baseStyle,
    TextAlign textAlign = TextAlign.start,
  }) {
    return Text.rich(
      parse(text, baseStyle),
      textAlign: textAlign,
    );
  }

  // ── Core recursive parser ─────────────────────────────────────────────────

  static void _parse(
    String text,
    int start,
    int end,
    TextStyle style,
    List<InlineSpan> out,
  ) {
    int cursor = start;

    for (final match in _tagRe.allMatches(text, start)) {
      if (match.start >= end) break;

      // plain text before this tag
      if (match.start > cursor) {
        out.add(TextSpan(text: text.substring(cursor, match.start), style: style));
      }

      final openTag = match.group(1);
      final closeTag = match.group(2);

      if (openTag != null) {
        // Find matching close tag
        final tagName = openTag.contains('=') ? openTag.split('=')[0] : openTag;
        final closePattern = '[/$tagName]';
        final closeIdx = text.indexOf(closePattern, match.end);

        if (closeIdx == -1) {
          // No close tag — treat as plain text
          out.add(TextSpan(text: match.group(0), style: style));
          cursor = match.end;
          continue;
        }

        // Content between open and close
        final inner = text.substring(match.end, closeIdx);
        final newStyle = _applyTag(openTag, style);

        if (tagName == 'sup' || tagName == 'sub') {
          // Superscript / subscript via WidgetSpan
          final List<InlineSpan> innerSpans = [];
          _parse(inner, 0, inner.length, newStyle, innerSpans);
          out.add(WidgetSpan(
            alignment: tagName == 'sup'
                ? PlaceholderAlignment.top
                : PlaceholderAlignment.bottom,
            child: Transform.translate(
              offset: Offset(0, tagName == 'sup' ? -4 : 4),
              child: Text.rich(TextSpan(children: innerSpans)),
            ),
          ));
        } else {
          // Regular inline span — recurse for nesting
          final List<InlineSpan> innerSpans = [];
          _parse(inner, 0, inner.length, newStyle, innerSpans);
          out.addAll(innerSpans);
        }

        cursor = closeIdx + closePattern.length;
        // Skip remaining iterations that fall inside the consumed range
        // by adjusting start via the outer loop (handled by cursor check).
      } else if (closeTag != null) {
        // Orphan close tag — skip
        cursor = match.end;
      }
    }

    // Remaining plain text after all tags
    if (cursor < end) {
      out.add(TextSpan(text: text.substring(cursor, end), style: style));
    }
  }

  // ── Tag → TextStyle mapping ───────────────────────────────────────────────

  static TextStyle _applyTag(String tag, TextStyle base) {
    if (tag == 'b') {
      return base.copyWith(
        fontWeight: FontWeight.w900,
        fontSize: (base.fontSize ?? 16) * 1.05,
        color: _boldColor(base),
      );
    }
    if (tag == 'i') {
      return base.copyWith(fontStyle: FontStyle.italic);
    }
    if (tag == 'u') {
      return base.copyWith(decoration: TextDecoration.underline);
    }
    if (tag == 's') {
      return base.copyWith(decoration: TextDecoration.lineThrough);
    }
    if (tag == 'bi') {
      return base.copyWith(
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic,
        fontSize: (base.fontSize ?? 16) * 1.05,
        color: _boldColor(base),
      );
    }
    if (tag == 'sup' || tag == 'sub') {
      return base.copyWith(fontSize: (base.fontSize ?? 14) * 0.75);
    }
    if (tag == 'h') {
      return base.copyWith(
        background: Paint()..color = Colors.amber.withValues(alpha: 0.4),
      );
    }
    if (tag.startsWith('c=')) {
      final hex = tag.substring(2);
      final color = _hexColor(hex) ?? AppColors.primary;
      return base.copyWith(color: color);
    }
    return base;
  }

  /// Returns the appropriate bold text color based on the base text color.
  ///
  /// If the surrounding text is already dark (light mode), bold pops with
  /// near-black. If it is light (dark mode), bold pops with pure white.
  /// This keeps bold visually distinct without needing a BuildContext.
  static Color _boldColor(TextStyle base) {
    final baseColor = base.color ?? AppColors.darkerGrey;
    // Use perceived luminance: values above 0.5 = light text = dark mode
    final luminance = baseColor.computeLuminance();
    return luminance > 0.5
        ? const Color(0xFFFFFFFF) // dark mode  → pure white
        : const Color(0xFF0D0D0D); // light mode → near-black
  }

  static Color? _hexColor(String hex) {
    try {
      final clean = hex.replaceFirst('#', '');
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      }
      if (clean.length == 8) {
        return Color(int.parse(clean, radix: 16));
      }
    } catch (_) {}
    return null;
  }
}
