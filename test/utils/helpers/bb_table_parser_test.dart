import 'package:flutter_test/flutter_test.dart';
import 'package:matricmate/utils/helpers/bb_table_parser.dart';

void main() {
  group('BBTableParser', () {
    // ── containsTable ───────────────────────────────────────────────────────

    group('containsTable', () {
      test('returns true when a [table] block is present', () {
        const text = 'Some text [table][row][cell]A[/cell][/row][/table] end.';
        expect(BBTableParser.containsTable(text), isTrue);
      });

      test('returns false when no [table] block is present', () {
        const text = 'Just plain text with [b]bold[/b] and no table.';
        expect(BBTableParser.containsTable(text), isFalse);
      });

      test('returns false for an empty string', () {
        expect(BBTableParser.containsTable(''), isFalse);
      });
    });

    // ── parseTables ─────────────────────────────────────────────────────────

    group('parseTables', () {
      test('simple 2-column, 2-row table (header + 1 body row)', () {
        const text = '''
[table]
[row][cell]Subject[/cell][cell]Score[/cell][/row]
[row][cell]Math[/cell][cell]90[/cell][/row]
[/table]
''';
        final tables = BBTableParser.parseTables(text);
        expect(tables.length, 1);

        final table = tables[0];
        expect(table.length, 2);

        expect(table[0], ['Subject', 'Score']); // header row
        expect(table[1], ['Math', '90']); // body row
      });

      test('parses multiple tables in the same text', () {
        const text = '''
[table][row][cell]A[/cell][cell]B[/cell][/row][/table]
Some text between.
[table][row][cell]C[/cell][cell]D[/cell][/row][/table]
''';
        final tables = BBTableParser.parseTables(text);
        expect(tables.length, 2);
        expect(tables[0][0], ['A', 'B']);
        expect(tables[1][0], ['C', 'D']);
      });

      test('cell content preserves inner BBCode tags', () {
        const text =
            '[table][row][cell][b]Bold header[/b][/cell][cell]Normal[/cell][/row][/table]';
        final tables = BBTableParser.parseTables(text);
        expect(tables[0][0][0], '[b]Bold header[/b]');
        expect(tables[0][0][1], 'Normal');
      });

      test('returns empty list when no table is present', () {
        const text = 'No table here, just [b]bold[/b] text.';
        expect(BBTableParser.parseTables(text), isEmpty);
      });

      test('gracefully handles missing [/table] closing tag — returns empty rows',
          () {
        // Malformed: [table] opened but never closed → regex finds no match →
        // parseTables returns an empty list (does not crash).
        const text = '[table][row][cell]Orphan[/cell][/row] no closing tag';
        final tables = BBTableParser.parseTables(text);
        expect(tables, isEmpty);
      });

      test('gracefully handles missing [/row] — cells in that row are skipped',
          () {
        // The row without [/row] is not matched; only complete rows appear.
        const text =
            '[table][row][cell]Good[/cell][/row][row][cell]Bad no close[/cell][/table]';
        final tables = BBTableParser.parseTables(text);
        // One table, but only the well-formed row makes it through.
        expect(tables.length, 1);
        expect(tables[0].length, 1);
        expect(tables[0][0], ['Good']);
      });

      test('gracefully handles missing [/cell] — that cell is skipped', () {
        const text =
            '[table][row][cell]OK[/cell][cell]No close[/row][/table]';
        final tables = BBTableParser.parseTables(text);
        // Only the properly closed cell should be present.
        expect(tables[0][0], ['OK']);
      });
    });

    // ── splitSegments ───────────────────────────────────────────────────────

    group('splitSegments', () {
      test('text with no table returns a single text segment', () {
        const text = 'Just some plain text.';
        final segs = BBTableParser.splitSegments(text);
        expect(segs.length, 1);
        expect(segs[0].isTable, isFalse);
        expect(segs[0].text, 'Just some plain text.');
      });

      test('table mixed with surrounding text produces 3 segments', () {
        const text =
            'Before text. [table][row][cell]H1[/cell][cell]H2[/cell][/row][row][cell]V1[/cell][cell]V2[/cell][/row][/table] After text.';
        final segs = BBTableParser.splitSegments(text);

        expect(segs.length, 3);

        // Segment 0: plain text before
        expect(segs[0].isTable, isFalse);
        expect(segs[0].text, contains('Before text.'));

        // Segment 1: the table
        expect(segs[1].isTable, isTrue);
        expect(segs[1].tableRows!.length, 2);
        expect(segs[1].tableRows![0], ['H1', 'H2']);
        expect(segs[1].tableRows![1], ['V1', 'V2']);

        // Segment 2: plain text after
        expect(segs[2].isTable, isFalse);
        expect(segs[2].text, contains('After text.'));
      });

      test('table-only string returns a single table segment', () {
        const text =
            '[table][row][cell]X[/cell][/row][/table]';
        final segs = BBTableParser.splitSegments(text);
        expect(segs.length, 1);
        expect(segs[0].isTable, isTrue);
      });

      test('two tables with no text between them return 2 table segments', () {
        const text =
            '[table][row][cell]A[/cell][/row][/table][table][row][cell]B[/cell][/row][/table]';
        final segs = BBTableParser.splitSegments(text);
        expect(segs.length, 2);
        expect(segs[0].isTable, isTrue);
        expect(segs[1].isTable, isTrue);
      });
    });

    // ── stripTables ─────────────────────────────────────────────────────────

    group('stripTables', () {
      test('removes table block and trims surrounding text', () {
        const text =
            'Intro. [table][row][cell]X[/cell][/row][/table] Outro.';
        final stripped = BBTableParser.stripTables(text);
        expect(stripped, contains('Intro.'));
        expect(stripped, contains('Outro.'));
        expect(stripped, isNot(contains('[table]')));
      });

      test('returns original text unchanged when no table present', () {
        const text = 'No table here.';
        expect(BBTableParser.stripTables(text), 'No table here.');
      });
    });
  });
}
