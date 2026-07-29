import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:matricmate/features/exam/models/bookmark_model.dart';
import 'package:matricmate/features/exam/models/chapter_model.dart';
import 'package:matricmate/features/exam/models/passage_model.dart';
import 'package:matricmate/features/exam/models/question_block.dart';
import 'package:matricmate/features/exam/models/question_model.dart';

void main() {
  group('Exam data models', () {
    test('ChapterModel accepts numeric JSON values and round-trips', () {
      final chapter = ChapterModel.fromJson({
        'id': 3.0,
        'subject_id': 7,
        'grade': 12.0,
        'chapter_number': 2,
        'title': 'Mechanics',
      });

      expect(chapter.toMap(), {
        'id': 3,
        'subject_id': 7,
        'chapter_number': 2,
        'grade': 12,
        'title': 'Mechanics',
      });
    });

    test(
      'PassageModel defaults missing content and retains optional metadata',
      () {
        final passage = PassageModel.fromMap({
          'id': 9,
          'image_url': 'https://example.com/passage.png',
          'title': 'Read this passage',
        });

        expect(passage.content, isEmpty);
        expect(passage.toMap()['title'], 'Read this passage');
        expect(passage.toMap()['image_url'], 'https://example.com/passage.png');
      },
    );

    test(
      'QuestionModel supports SQLite JSON options and Supabase sections',
      () {
        final question = QuestionModel.fromMap({
          'id': 11,
          'subject_id': 7,
          'grade': 12,
          'test_id': 41,
          'correct_option_index': 1,
          'question_text': 'Pick one',
          'options': jsonEncode(['A', 'B']),
          'question_sections': {'title': 'Section A'},
        });

        expect(question.options, ['A', 'B']);
        expect(question.sectionTitle, 'Section A');
        expect(jsonDecode(question.toMap()['options'] as String), ['A', 'B']);
      },
    );

    test('BookmarkModel round-trips persisted bookmark data', () {
      final bookmark = BookmarkModel.fromMap({
        'question_id': 11,
        'saved_at': 1720000000,
        'user_id': 'user-1',
      });

      expect(bookmark.toMap()['question_id'], 11);
      expect(bookmark.toMap()['user_id'], 'user-1');
    });

    test('QuestionBlock identifies passage-backed question groups', () {
      final passageBlock = QuestionBlock(passageId: 9, questions: []);
      final standaloneBlock = QuestionBlock(questions: []);

      expect(passageBlock.isPassage, isTrue);
      expect(standaloneBlock.isPassage, isFalse);
    });
  });
}
