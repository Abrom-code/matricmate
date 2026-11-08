import 'package:flutter_test/flutter_test.dart';
import 'package:matricmate/features/notes/models/note_model.dart';

void main() {
  group('NoteModel.fromMap resilience tests', () {
    test('parses standard integer types correctly', () {
      final map = {
        'id': 101,
        'subject_id': 2,
        'chapter_id': 5,
        'grade': 11,
        'chapter_number': 3,
        'title': 'Organic Chemistry',
        'file_key': 'chem/g11_c3.pdf',
        'file_type': 'pdf',
        'file_size_bytes': 1048576,
        'page_count': 12,
        'is_premium': 1,
        'order_index': 1,
        'created_at': '2026-11-08T12:00:00Z',
      };

      final note = NoteModel.fromMap(map);
      expect(note.id, 101);
      expect(note.subjectId, 2);
      expect(note.chapterId, 5);
      expect(note.grade, 11);
      expect(note.chapterNumber, 3);
      expect(note.title, 'Organic Chemistry');
      expect(note.fileSizeBytes, 1048576);
      expect(note.pageCount, 12);
      expect(note.isPremium, true);
    });

    test('safely parses string values entered manually in Supabase', () {
      final map = {
        'id': '202',
        'subject_id': '4',
        'chapter_id': '8',
        'grade': '12',
        'chapter_number': '2',
        'title': 'Calculus Notes',
        'file_key': 'math/g12_c2.pdf',
        'file_size_bytes': '2097152',
        'page_count': '25',
        'is_premium': '1',
        'order_index': '0',
      };

      final note = NoteModel.fromMap(map);
      expect(note.id, 202);
      expect(note.subjectId, 4);
      expect(note.chapterId, 8);
      expect(note.grade, 12);
      expect(note.chapterNumber, 2);
      expect(note.title, 'Calculus Notes');
      expect(note.fileSizeBytes, 2097152);
      expect(note.pageCount, 25);
      expect(note.isPremium, true);
    });

    test('safely handles missing or null optional fields', () {
      final map = {
        'id': 303,
        'title': 'General Study Guide',
        'file_key': 'general_guide.pdf',
      };

      final note = NoteModel.fromMap(map);
      expect(note.id, 303);
      expect(note.subjectId, 0);
      expect(note.chapterId, isNull);
      expect(note.grade, 9);
      expect(note.chapterNumber, 1);
      expect(note.pageCount, 0);
      expect(note.fileSizeBytes, 0);
    });
  });
}

