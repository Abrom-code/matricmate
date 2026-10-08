import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:matricmate/utils/constants/colors.dart';

/// Parses lightweight markup tags ([b], [i], [u], [c=...], markdown, and HTML) and LaTeX into a [TextSpan] tree.
class RichTextParser {
  RichTextParser._();

  // Single regex that captures either a tag or plain text (case-insensitive)
  static final _tagRe = RegExp(
    r'\[([a-zA-Z]+(?:=#[0-9a-fA-F]{3,8})?)\]|\[/([a-zA-Z]+)\]',
    caseSensitive: false,
  );

  static final Map<String, String> _preprocessCache = {};
  static final Map<int, TextSpan> _spanCache = {};

  /// Fast non-regex check to see if text contains any characters that might trigger markup.
  static bool _hasMarkupTriggers(String s) {
    for (int i = 0; i < s.length; i++) {
      final code = s.codeUnitAt(i);
      // Check for: [ (91), < (60), & (38), * (42), _ (95), ~ (126), \ (92), # (35), \r (13), $ (36)
      if (code == 91 ||
          code == 60 ||
          code == 38 ||
          code == 42 ||
          code == 95 ||
          code == 126 ||
          code == 92 ||
          code == 35 ||
          code == 13 ||
          code == 36) {
        return true;
      }
    }
    return false;
  }

  /// Preprocesses HTML tags, entities, and Markdown syntax into normalized BBCode.
  static String _preprocessText(String raw) {
    final cached = _preprocessCache[raw];
    if (cached != null) return cached;

    if (!_hasMarkupTriggers(raw)) {
      if (_preprocessCache.length > 500) _preprocessCache.clear();
      _preprocessCache[raw] = raw;
      return raw;
    }

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

    if (_preprocessCache.length > 500) {
      _preprocessCache.clear();
    }
    _preprocessCache[raw] = text;
    return text;
  }

  /// Parses [text] into styled [TextSpan] with [baseStyle] fallback.
  static TextSpan parse(String text, TextStyle baseStyle) {
    if (text.isEmpty) return const TextSpan();

    final cacheKey = Object.hash(
      text,
      baseStyle.fontSize,
      baseStyle.fontWeight,
      baseStyle.fontStyle,
      baseStyle.color?.toARGB32(),
      baseStyle.letterSpacing,
      baseStyle.height,
    );

    final cached = _spanCache[cacheKey];
    if (cached != null) return cached;

    if (!_hasMarkupTriggers(text)) {
      final span = TextSpan(text: text, style: baseStyle);
      if (_spanCache.length > 1000) _spanCache.clear();
      _spanCache[cacheKey] = span;
      return span;
    }

    // 1. Extract LaTeX formulas into sentinels before preprocessing
    final (textWithSentinels, mathTokens) = _extractMathTokens(text);
    final normalized = _preprocessText(textWithSentinels);

    // If normalized text still doesn't contain any BBCode tags, avoid running _tagRe
    if (!normalized.contains('[')) {
      if (mathTokens.isEmpty) {
        final span = TextSpan(text: normalized, style: baseStyle);
        if (_spanCache.length > 1000) _spanCache.clear();
        _spanCache[cacheKey] = span;
        return span;
      }
      final spans = <InlineSpan>[];
      _appendSpanWithMath(normalized, baseStyle, mathTokens, spans);
      final span = TextSpan(children: spans);
      if (_spanCache.length > 1000) _spanCache.clear();
      _spanCache[cacheKey] = span;
      return span;
    }

    final spans = <InlineSpan>[];
    _parse(normalized, 0, normalized.length, baseStyle, spans, mathTokens);
    final result = TextSpan(children: spans);

    if (_spanCache.length > 1000) _spanCache.clear();
    _spanCache[cacheKey] = result;
    return result;
  }

  /// Convenience: wraps [parse] in a [Text.rich].
  static Widget widget(
    String text, {
    required TextStyle baseStyle,
    TextAlign textAlign = TextAlign.start,
  }) {
    return Text.rich(parse(text, baseStyle), textAlign: textAlign);
  }

  // ── Math Token extraction & Span building ──────────────────────────────────

  static (String, List<_MathToken>) _extractMathTokens(String input) {
    if (!input.contains(r'\') && !input.contains(r'$')) {
      return (input, const []);
    }

    final tokens = <_MathToken>[];
    var text = input;

    String registerToken(String tex, String raw, bool isBlock) {
      final idx = tokens.length;
      tokens.add(_MathToken(
        index: idx,
        tex: tex,
        raw: raw,
        isBlock: isBlock,
      ));
      return '\uE000M$idx\uE001';
    }

    // 1. Block: \[ ... \] or \\[ ... \\]
    text = text.replaceAllMapped(
      RegExp(r'\\{1,2}\[([\s\S]*?)\\{1,2}\]'),
      (m) => registerToken(m.group(1)?.trim() ?? '', m.group(0) ?? '', true),
    );

    // 2. Block: $$ ... $$
    text = text.replaceAllMapped(
      RegExp(r'\$\$([\s\S]*?)\$\$'),
      (m) => registerToken(m.group(1)?.trim() ?? '', m.group(0) ?? '', true),
    );

    // 3. Inline: \( ... \) or \\( ... \\)
    text = text.replaceAllMapped(
      RegExp(r'\\{1,2}\(([\s\S]*?)\\{1,2}\)'),
      (m) => registerToken(m.group(1)?.trim() ?? '', m.group(0) ?? '', false),
    );

    // 4. Inline: $ ... $
    text = text.replaceAllMapped(
      RegExp(r'(?<!\\)\$(?!\s)([^\$\n]+?)(?<!\s|\$)\$'),
      (m) => registerToken(m.group(1)?.trim() ?? '', m.group(0) ?? '', false),
    );

    return (text, tokens);
  }

  static void _appendSpanWithMath(
    String chunk,
    TextStyle style,
    List<_MathToken> mathTokens,
    List<InlineSpan> out,
  ) {
    if (mathTokens.isEmpty || !chunk.contains('\uE000M')) {
      out.add(TextSpan(text: chunk, style: style));
      return;
    }

    final sentinelRe = RegExp(r'\uE000M(\d+)\uE001');
    int cursor = 0;

    for (final match in sentinelRe.allMatches(chunk)) {
      if (match.start > cursor) {
        out.add(TextSpan(
          text: chunk.substring(cursor, match.start),
          style: style,
        ));
      }

      final idx = int.tryParse(match.group(1) ?? '');
      if (idx != null && idx >= 0 && idx < mathTokens.length) {
        final token = mathTokens[idx];
        out.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          baseline: TextBaseline.alphabetic,
          child: MathWidget(
            tex: token.tex,
            raw: token.raw,
            style: style,
            isBlock: token.isBlock,
          ),
        ));
      } else {
        out.add(TextSpan(text: match.group(0), style: style));
      }

      cursor = match.end;
    }

    if (cursor < chunk.length) {
      out.add(TextSpan(text: chunk.substring(cursor), style: style));
    }
  }

  // ── Nesting-aware close-tag finder ──────────────────────────────────────────

  /// Finds the matching close tag `[/tagName]` for the open tag at [searchFrom],
  /// correctly handling nested tags of the same type.
  /// Returns the index of the closing tag, or -1 if not found.
  static int _findCloseTag(String text, String tagName, int searchFrom, int end) {
    final openPattern = '[$tagName]';
    final closePattern = '[/$tagName]';
    final lowerText = text.toLowerCase();
    int depth = 1;
    int pos = searchFrom;

    while (pos < end) {
      final nextClose = lowerText.indexOf(closePattern, pos);
      if (nextClose == -1 || nextClose >= end) return -1; // no close tag found

      // Count any nested opens between pos and nextClose
      int searchPos = pos;
      while (true) {
        final nextOpen = lowerText.indexOf(openPattern, searchPos);
        if (nextOpen == -1 || nextOpen >= nextClose) break;
        depth++;
        searchPos = nextOpen + openPattern.length;
      }

      depth--; // account for the close tag we found
      if (depth == 0) return nextClose;
      pos = nextClose + closePattern.length;
    }
    return -1;
  }

  // ── Core recursive parser ─────────────────────────────────────────────────

  static void _parse(
    String text,
    int start,
    int end,
    TextStyle style,
    List<InlineSpan> out,
    List<_MathToken> mathTokens,
  ) {
    int cursor = start;

    for (final match in _tagRe.allMatches(text, start)) {
      if (match.start >= end) break;

      // Skip matches that fall inside an already-consumed tag range
      if (match.start < cursor) continue;

      // plain text before this tag
      if (match.start > cursor) {
        _appendSpanWithMath(
          text.substring(cursor, match.start),
          style,
          mathTokens,
          out,
        );
      }

      final openTag = match.group(1);
      final closeTag = match.group(2);

      if (openTag != null) {
        // Find matching close tag (nesting-aware)
        final tagName =
            (openTag.contains('=') ? openTag.split('=')[0] : openTag)
                .toLowerCase();
        final closeIdx = _findCloseTag(text, tagName, match.end, end);

        if (closeIdx == -1) {
          // No close tag — treat as plain text
          _appendSpanWithMath(
            match.group(0)!,
            style,
            mathTokens,
            out,
          );
          cursor = match.end;
          continue;
        }

        final closePattern = '[/$tagName]';
        // Content between open and close
        final newStyle = _applyTag(openTag, style);

        if (tagName == 'sup' || tagName == 'sub') {
          // Superscript / subscript via WidgetSpan
          final List<InlineSpan> innerSpans = [];
          _parse(text, match.end, closeIdx, newStyle, innerSpans, mathTokens);
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
          _parse(text, match.end, closeIdx, newStyle, innerSpans, mathTokens);
          out.addAll(innerSpans);
        }

        cursor = closeIdx + closePattern.length;
      } else if (closeTag != null) {
        // Orphan close tag — skip
        cursor = match.end;
      }
    }

    // Remaining plain text after all tags
    if (cursor < end) {
      _appendSpanWithMath(
        text.substring(cursor, end),
        style,
        mathTokens,
        out,
      );
    }
  }

  // ── Tag → TextStyle mapping ───────────────────────────────────────────────

  /// Combines existing and new [TextDecoration]s so both are visible.
  static TextDecoration _combineDecoration(
    TextStyle base,
    TextDecoration added,
  ) {
    final existing = base.decoration;
    if (existing == null || existing == TextDecoration.none) return added;
    return TextDecoration.combine([existing, added]);
  }

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
      return base.copyWith(
        decoration: _combineDecoration(base, TextDecoration.underline),
      );
    }
    if (tag == 's') {
      return base.copyWith(
        decoration: _combineDecoration(base, TextDecoration.lineThrough),
      );
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

class _MathToken {
  final int index;
  final String tex;
  final String raw;
  final bool isBlock;

  const _MathToken({
    required this.index,
    required this.tex,
    required this.raw,
    required this.isBlock,
  });
}

/// A responsive widget that renders LaTeX using [Math.tex] with graceful fallback.
class MathWidget extends StatelessWidget {
  const MathWidget({
    super.key,
    required this.tex,
    required this.raw,
    required this.style,
    required this.isBlock,
  });

  final String tex;
  final String raw;
  final TextStyle style;
  final bool isBlock;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fallbackColor = dark ? Colors.white : const Color(0xFF0F172A);
    final effectiveColor = style.color ?? fallbackColor;
    final effectiveStyle = style.copyWith(
      color: effectiveColor,
      fontSize: isBlock ? (style.fontSize ?? 16.0) * 1.08 : style.fontSize,
    );

    Widget mathWidget;
    try {
      mathWidget = Math.tex(
        tex,
        mathStyle: isBlock ? MathStyle.display : MathStyle.text,
        textStyle: effectiveStyle,
        onErrorFallback: (err) => Text(
          raw,
          style: effectiveStyle,
        ),
      );
    } catch (_) {
      mathWidget = Text(raw, style: effectiveStyle);
    }

    if (isBlock) {
      return Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: mathWidget,
          ),
        ),
      );
    }

    // Safeguard for inline math: bounded by screen width so wide equations
    // inserted with inline \(...\) or $...$ scroll horizontally instead of overflowing.
    return Builder(
      builder: (context) {
        final screenWidth = MediaQuery.sizeOf(context).width;
        final maxW = screenWidth > 64 ? screenWidth - 64 : screenWidth;
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: mathWidget,
          ),
        );
      },
    );
  }
}


