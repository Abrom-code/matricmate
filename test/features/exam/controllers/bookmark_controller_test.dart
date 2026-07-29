import 'package:flutter_test/flutter_test.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/data/repositories/exam/bookmark_repository.dart';
import 'package:matricmate/data/repositories/exam/question_repository.dart';
import 'package:matricmate/features/exam/controllers/bookmark_controller.dart';

void main() {
  group('BookmarkController local interaction state', () {
    late BookmarkController controller;

    setUp(() {
      final database = DatabaseService();
      controller = BookmarkController(
        repository: BookmarkRepository(databaseService: database),
        questionRepository: QuestionRepository(databaseService: database),
      );
    });

    test('toggles an individual bookmarked question preview', () {
      controller.toggleExpanded(11);
      expect(controller.isExpanded[11], isTrue);

      controller.toggleExpanded(11);
      expect(controller.isExpanded[11], isFalse);
    });

    test('toggles a passage independently from the question preview', () {
      controller.toggleExpanded(11);
      controller.togglePassage(11);

      expect(controller.isExpanded[11], isTrue);
      expect(controller.isPassageExpanded[11], isTrue);
    });

    test('uses an unknown test type until bookmark metadata is loaded', () {
      expect(controller.testType(99), 'Unknown');
    });
  });
}
