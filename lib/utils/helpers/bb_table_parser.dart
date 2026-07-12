/// BBTableParser
///
/// Parses [table][row][cell]...[/cell][/row][/table] blocks from
/// explanation / question text that comes from Supabase.
///
/// Design constraints:
///  - No nested tables.
///  - No cell attributes.
///  - First [row] is always the header row.
///  - Language-agnostic — cell content is passed through as-is.
///  - Graceful degradation: malformed / unclosed tags → treated as plain text.
class BBTableParser {
  BBTableParser._();

  // ── Regexes ───────────────────────────────────────────────────────────────

  /// Matches a full [table]...[/table] block (non-greedy, case-insensitive).
  static final _tableBlockRe = RegExp(
    r'\[table\](.*?)\[/table\]',
    caseSensitive: false,
    dotAll: true,
  );

  /// Matches a [row]...[/row] block inside a table.
  static final _rowRe = RegExp(
    r'\[row\](.*?)\[/row\]',
    caseSensitive: false,
    dotAll: true,
  );

  /// Matches a [cell]...[/cell] block inside a row.
  static final _cellRe = RegExp(
    r'\[cell\](.*?)\[/cell\]',
    caseSensitive: false,
    dotAll: true,
  );

  // ── Public API ────────────────────────────────────────────────────────────

  /// Returns `true` if [text] contains at least one [table] block.
  static bool containsTable(String text) => _tableBlockRe.hasMatch(text);

  /// Parses all [table] blocks in [text].
  ///
  /// Returns a list of tables; each table is a `List<List<String>>`
  /// (rows of cell-content strings). Cell content retains any inner
  /// BBCode tags (e.g. [b]) so the caller can pass them to RichTextParser.
  ///
  /// Malformed / unclosed tags produce an empty list for that table.
  static List<List<List<String>>> parseTables(String text) {
    final tables = <List<List<String>>>[];

    for (final tableMatch in _tableBlockRe.allMatches(text)) {
      final tableContent = tableMatch.group(1) ?? '';
      final rows = <List<String>>[];

      for (final rowMatch in _rowRe.allMatches(tableContent)) {
        final rowContent = rowMatch.group(1) ?? '';
        final cells = _cellRe
            .allMatches(rowContent)
            .map((m) => (m.group(1) ?? '').trim())
            .toList();

        if (cells.isNotEmpty) rows.add(cells);
      }

      tables.add(rows);
    }

    return tables;
  }

  /// Returns a list of [_TextOrTable] segments representing the text split
  /// around all [table] blocks, in order.
  ///
  /// Use [splitSegments] to interleave plain-text and table data so the UI
  /// can render them in sequence:
  ///
  /// ```dart
  /// for (final seg in BBTableParser.splitSegments(text)) {
  ///   if (seg.isTable) {
  ///     BBTableWidget(rows: seg.tableRows!)
  ///   } else {
  ///     Text.rich(RichTextParser.parse(seg.text!, baseStyle))
  ///   }
  /// }
  /// ```
  static List<BBSegment> splitSegments(String text) {
    final segments = <BBSegment>[];
    int cursor = 0;

    for (final tableMatch in _tableBlockRe.allMatches(text)) {
      // Text before this table block
      if (tableMatch.start > cursor) {
        final before = text.substring(cursor, tableMatch.start).trim();
        if (before.isNotEmpty) segments.add(BBSegment.text(before));
      }

      // The table itself
      final tableContent = tableMatch.group(1) ?? '';
      final rows = <List<String>>[];
      for (final rowMatch in _rowRe.allMatches(tableContent)) {
        final rowContent = rowMatch.group(1) ?? '';
        final cells = _cellRe
            .allMatches(rowContent)
            .map((m) => (m.group(1) ?? '').trim())
            .toList();
        if (cells.isNotEmpty) rows.add(cells);
      }
      segments.add(BBSegment.table(rows));

      cursor = tableMatch.end;
    }

    // Remaining text after the last table (or the whole string if no tables)
    if (cursor < text.length) {
      final after = text.substring(cursor).trim();
      if (after.isNotEmpty) segments.add(BBSegment.text(after));
    }

    return segments;
  }

  /// Strips all [table]...[/table] blocks from [text] and returns the
  /// remaining string (trimmed). Useful if you want just the surrounding text.
  static String stripTables(String text) =>
      text.replaceAll(_tableBlockRe, '').trim();
}

// ── Segment model ─────────────────────────────────────────────────────────────

/// Represents either a plain-text chunk or a parsed table within a larger
/// explanation string.
class BBSegment {
  BBSegment._({
    required this.isTable,
    this.text,
    this.tableRows,
  });

  factory BBSegment.text(String text) =>
      BBSegment._(isTable: false, text: text);

  factory BBSegment.table(List<List<String>> rows) =>
      BBSegment._(isTable: true, tableRows: rows);

  /// `true` → this segment is a table; `false` → plain text.
  final bool isTable;

  /// Non-null when [isTable] is `false`.
  final String? text;

  /// Non-null when [isTable] is `true`. First element is the header row.
  final List<List<String>>? tableRows;
}
