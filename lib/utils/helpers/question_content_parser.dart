/// Segment types recognized in question content.
enum ContentSegmentType {
  text,
  table,
  blockMath,
}

/// Represents an individual parsed chunk of question content.
class ContentSegment {
  const ContentSegment._({
    required this.type,
    this.text,
    this.tableRows,
    this.mathTex,
    this.mathRaw,
  });

  factory ContentSegment.text(String text) =>
      ContentSegment._(type: ContentSegmentType.text, text: text);

  factory ContentSegment.table(List<List<String>> rows) =>
      ContentSegment._(type: ContentSegmentType.table, tableRows: rows);

  factory ContentSegment.blockMath({
    required String tex,
    required String raw,
  }) =>
      ContentSegment._(
        type: ContentSegmentType.blockMath,
        mathTex: tex,
        mathRaw: raw,
      );

  final ContentSegmentType type;
  final String? text;
  final List<List<String>>? tableRows;
  final String? mathTex;
  final String? mathRaw;

  bool get isText => type == ContentSegmentType.text;
  bool get isTable => type == ContentSegmentType.table;
  bool get isBlockMath => type == ContentSegmentType.blockMath;
}

/// Centralized parser for question content.
/// Splits raw strings into sequential segments:
/// - Plain text / markup / inline math
/// - Block tables
/// - Block math equations
class QuestionContentParser {
  QuestionContentParser._();

  static final _tableRe = RegExp(
    r'\[table\]([\s\S]*?)\[/table\]',
    caseSensitive: false,
  );

  static final _rowRe = RegExp(
    r'\[row\]([\s\S]*?)\[/row\]',
    caseSensitive: false,
  );

  static final _cellRe = RegExp(
    r'\[cell\]([\s\S]*?)\[/cell\]',
    caseSensitive: false,
  );

  static final _blockMathBracketRe = RegExp(
    r'\\{1,2}\[([\s\S]*?)\\{1,2}\]',
  );

  static final _blockMathDollarRe = RegExp(
    r'\$\$([\s\S]*?)\$\$',
  );

  /// Quick check if content has any block-level elements (tables or block math).
  static bool hasBlockElements(String text) {
    if (text.isEmpty) return false;
    final lower = text.toLowerCase();
    if (lower.contains('[table]') && lower.contains('[/table]')) return true;
    if (text.contains(r'\[') || text.contains(r'\\[')) return true;
    if (text.contains(r'$$')) return true;
    return false;
  }

  /// Splits [text] into sequential [ContentSegment]s: text, table, or blockMath.
  static List<ContentSegment> splitSegments(String text) {
    if (!hasBlockElements(text)) {
      final trimmed = text.trim();
      return trimmed.isEmpty ? [] : [ContentSegment.text(trimmed)];
    }

    final matches = <_BlockMatch>[];

    // 1. Tables
    for (final m in _tableRe.allMatches(text)) {
      final content = m.group(1) ?? '';
      final rows = <List<String>>[];
      for (final rowMatch in _rowRe.allMatches(content)) {
        final rowContent = rowMatch.group(1) ?? '';
        final cells = _cellRe
            .allMatches(rowContent)
            .map((c) => (c.group(1) ?? '').trim())
            .toList();
        if (cells.isNotEmpty) rows.add(cells);
      }
      matches.add(_BlockMatch(
        start: m.start,
        end: m.end,
        segment: ContentSegment.table(rows),
      ));
    }

    // 2. Block LaTeX \[ ... \]
    for (final m in _blockMathBracketRe.allMatches(text)) {
      final tex = (m.group(1) ?? '').trim();
      matches.add(_BlockMatch(
        start: m.start,
        end: m.end,
        segment: ContentSegment.blockMath(
          tex: tex,
          raw: m.group(0) ?? '',
        ),
      ));
    }

    // 3. Block LaTeX $$ ... $$
    for (final m in _blockMathDollarRe.allMatches(text)) {
      final tex = (m.group(1) ?? '').trim();
      matches.add(_BlockMatch(
        start: m.start,
        end: m.end,
        segment: ContentSegment.blockMath(
          tex: tex,
          raw: m.group(0) ?? '',
        ),
      ));
    }

    // Sort matches chronologically by their appearance in the text
    matches.sort((a, b) => a.start.compareTo(b.start));

    // Filter out any overlapping ranges
    final nonOverlapping = <_BlockMatch>[];
    int lastEnd = 0;
    for (final m in matches) {
      if (m.start >= lastEnd) {
        nonOverlapping.add(m);
        lastEnd = m.end;
      }
    }

    final segments = <ContentSegment>[];
    int cursor = 0;

    for (final m in nonOverlapping) {
      if (m.start > cursor) {
        final chunk = text.substring(cursor, m.start).trim();
        if (chunk.isNotEmpty) {
          segments.add(ContentSegment.text(chunk));
        }
      }
      segments.add(m.segment);
      cursor = m.end;
    }

    if (cursor < text.length) {
      final chunk = text.substring(cursor).trim();
      if (chunk.isNotEmpty) {
        segments.add(ContentSegment.text(chunk));
      }
    }

    return segments;
  }
}

class _BlockMatch {
  final int start;
  final int end;
  final ContentSegment segment;

  _BlockMatch({
    required this.start,
    required this.end,
    required this.segment,
  });
}
