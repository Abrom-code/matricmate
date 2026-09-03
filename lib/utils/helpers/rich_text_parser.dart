import 'package:flutter/material.dart';
import 'package:matricmate/utils/constants/colors.dart';

/// Parses lightweight markup tags ([b], [i], [u], [c=...], markdown, and HTML) into a [TextSpan] tree.
class RichTextParser {
  RichTextParser._();

  // Single regex that captures either a tag or plain text (case-insensitive)
  static final _tagRe = RegExp(
    r'\[([a-zA-Z]+(?:=#[0-9a-fA-F]{3,8})?)\]|\[/([a-zA-Z]+)\]',
    caseSensitive: false,
  );

  /// Preprocesses HTML tags, entities, and Markdown syntax into normalized BBCode.
  static String _preprocessText(String raw) {
    var text = raw;

    // 0. Normalize BBCode tags to lowercase & trim spaces inside tags (e.g. [B], [/B], [ b ], [ /b ])
    text = text.replaceAllMapped(
      RegExp(r'\[\s*([a-zA-Z]+(?:=#[0-9a-fA-F]{3,8})?)\s*\]'),
      (m) => '[${m.group(1)!.toLowerCase()}]',
    );
    text = text.replaceAllMapped(
      RegExp(r'\[\s*/\s*([a-zA-Z]+)\s*\]'),
      (m) => '[/${m.group(1)!.toLowerCase()}]',
    );

    // 1. Literal escape characters from JSON / DB
    text = text.replaceAll(r'\r\n', '\n').replaceAll(r'\n', '\n').replaceAll('\r', '');

    // 2. Decode common HTML entities
    text = text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&#8217;', "'")
        .replaceAll('&#8216;', "'")
        .replaceAll('&#8220;', '"')
        .replaceAll('&#8221;', '"')
        .replaceAll('&#8212;', '—')
        .replaceAll('&#8211;', '–');

    // 3. HTML tags to BBCode
    // Bold: <b>, <strong>
    text = text.replaceAllMapped(
      RegExp(r'<\s*(?:strong|b)\s*>', caseSensitive: false),
      (_) => '[b]',
    );
    text = text.replaceAllMapped(
      RegExp(r'<\s*/\s*(?:strong|b)\s*>', caseSensitive: false),
      (_) => '[/b]',
    );

    // Italic: <i>, <em>
    text = text.replaceAllMapped(
      RegExp(r'<\s*(?:em|i)\s*>', caseSensitive: false),
      (_) => '[i]',
    );
    text = text.replaceAllMapped(
      RegExp(r'<\s*/\s*(?:em|i)\s*>', caseSensitive: false),
      (_) => '[/i]',
    );

    // Underline: <u>
    text = text.replaceAllMapped(
      RegExp(r'<\s*u\s*>', caseSensitive: false),
      (_) => '[u]',
    );
    text = text.replaceAllMapped(
      RegExp(r'<\s*/\s*u\s*>', caseSensitive: false),
      (_) => '[/u]',
    );

    // Strikethrough: <s>, <strike>, <del>
    text = text.replaceAllMapped(
      RegExp(r'<\s*(?:strike|del|s)\s*>', caseSensitive: false),
      (_) => '[s]',
    );
    text = text.replaceAllMapped(
      RegExp(r'<\s*/\s*(?:strike|del|s)\s*>', caseSensitive: false),
      (_) => '[/s]',
    );

    // Sub / Sup
    text = text.replaceAllMapped(
      RegExp(r'<\s*sup\s*>', caseSensitive: false),
      (_) => '[sup]',
    );
    text = text.replaceAllMapped(
      RegExp(r'<\s*/\s*sup\s*>', caseSensitive: false),
      (_) => '[/sup]',
    );
    text = text.replaceAllMapped(
      RegExp(r'<\s*sub\s*>', caseSensitive: false),
      (_) => '[sub]',
    );
    text = text.replaceAllMapped(
      RegExp(r'<\s*/\s*sub\s*>', caseSensitive: false),
      (_) => '[/sub]',
    );

    // Highlight / mark
    text = text.replaceAllMapped(
      RegExp(r'<\s*(?:mark|highlight)\s*>', caseSensitive: false),
      (_) => '[h]',
    );
    text = text.replaceAllMapped(
      RegExp(r'<\s*/\s*(?:mark|highlight)\s*>', caseSensitive: false),
      (_) => '[/h]',
    );

    // Headings: <h1> to <h6>
    text = text.replaceAllMapped(
      RegExp(r'<\s*h[1-6]\s*>(.*?)</\s*h[1-6]\s*>', caseSensitive: false, dotAll: true),
      (m) => '\n\n[b]${m.group(1)}[/b]\n',
    );

    // Line breaks & paragraphs
    text = text.replaceAll(RegExp(r'<\s*br\s*/?\s*>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'<\s*p\s*>', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'<\s*/\s*p\s*>', caseSensitive: false), '\n\n');

    // 4. Markdown syntax to BBCode
    // Bold-italic: ***text*** or ___text___
    text = text.replaceAllMapped(
      RegExp(r'\*\*\*(.*?)\*\*\*', dotAll: true),
      (m) => '[bi]${m.group(1)}[/bi]',
    );
    text = text.replaceAllMapped(
      RegExp(r'___(.*?)___', dotAll: true),
      (m) => '[bi]${m.group(1)}[/bi]',
    );

    // Bold: **text** or __text__
    text = text.replaceAllMapped(
      RegExp(r'\*\*(.*?)\*\*', dotAll: true),
      (m) => '[b]${m.group(1)}[/b]',
    );
    text = text.replaceAllMapped(
      RegExp(r'__(.*?)__', dotAll: true),
      (m) => '[b]${m.group(1)}[/b]',
    );

    // Strikethrough: ~~text~~
    text = text.replaceAllMapped(
      RegExp(r'~~(.*?)~~', dotAll: true),
      (m) => '[s]${m.group(1)}[/s]',
    );

    // Markdown Headings: # Heading
    text = text.replaceAllMapped(
      RegExp(r'(?:^|\n)#{1,6}\s+(.+?)(?=\n|$)', multiLine: true),
      (m) => '\n[b]${m.group(1)}[/b]\n',
    );

    // Italic: *text* or _text_
    text = text.replaceAllMapped(
      RegExp(r'(?<!\*)\*(?!\s|\*)([^\*\n]+?)(?<!\s|\*)\*(?!\*)'),
      (m) => '[i]${m.group(1)}[/i]',
    );
    text = text.replaceAllMapped(
      RegExp(r'(?<![a-zA-Z0-9_])_(?!\s|_)([^_\n]+?)(?<!\s|_)_(?![a-zA-Z0-9_])'),
      (m) => '[i]${m.group(1)}[/i]',
    );

    // 5. Clean up any remaining unhandled HTML tags
    text = text.replaceAll(RegExp(r'</?[a-zA-Z][^>]*>'), '');

    // 6. Normalize multiple blank lines to at most 2
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return text;
  }

  /// Parses [text] into styled [TextSpan] with [baseStyle] fallback.
  static TextSpan parse(String text, TextStyle baseStyle) {
    final normalized = _preprocessText(text);
    final spans = <InlineSpan>[];
    _parse(normalized, 0, normalized.length, baseStyle, spans);
    return TextSpan(children: spans);
  }

  /// Convenience: wraps [parse] in a [Text.rich].
  static Widget widget(
    String text, {
    required TextStyle baseStyle,
    TextAlign textAlign = TextAlign.start,
  }) {
    return Text.rich(parse(text, baseStyle), textAlign: textAlign);
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
        out.add(
          TextSpan(text: text.substring(cursor, match.start), style: style),
        );
      }

      final openTag = match.group(1);
      final closeTag = match.group(2);

      if (openTag != null) {
        // Find matching close tag
        final tagName =
            (openTag.contains('=') ? openTag.split('=')[0] : openTag)
                .toLowerCase();
        final closePattern = '[/$tagName]';
        final closeIdx = text.toLowerCase().indexOf(closePattern, match.end);

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
          out.add(
            WidgetSpan(
              alignment: tagName == 'sup'
                  ? PlaceholderAlignment.top
                  : PlaceholderAlignment.bottom,
              child: Transform.translate(
                offset: Offset(0, tagName == 'sup' ? -4 : 4),
                child: Text.rich(TextSpan(children: innerSpans)),
              ),
            ),
          );
        } else {
          // Regular inline span — recurse for nesting
          final List<InlineSpan> innerSpans = [];
          _parse(inner, 0, inner.length, newStyle, innerSpans);
          out.addAll(innerSpans);
        }

        cursor = closeIdx + closePattern.length;
        // Skip iterations falling inside the consumed range
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

  static TextStyle _applyTag(String rawTag, TextStyle base) {
    final tag = rawTag.toLowerCase();
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

  /// Returns high-contrast bold text color based on brightness.
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
