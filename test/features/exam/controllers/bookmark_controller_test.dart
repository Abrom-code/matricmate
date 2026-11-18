import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/data/repositories/exam/bookmark_repository.dart';
import 'package:matricmate/data/repositories/exam/question_repository.dart';
import 'package:matricmate/features/exam/controllers/bookmark_controller.dart';
import 'package:matricmate/features/exam/models/bookmark_model.dart';
import 'package:matricmate/features/exam/models/question_model.dart';
import 'package:matricmate/features/authentication/models/user_model.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';

class _FakeUserController extends GetxController implements UserController {
  @override
  final Rx<UserModel> user = UserModel(
    id: 'test-user-id',
    firstName: 'Test',
    lastName: 'User',
    email: 'test@example.com',
    stream: 'natural',
  ).obs;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeBookmarkRepo extends BookmarkRepository {
  _FakeBookmarkRepo(DatabaseService db) : super(databaseService: db);

  List<BookmarkModel> fakeBookmarks = [];
  List<QuestionModel> fakeQuestions = [];

  @override
  Future<List<BookmarkModel>> loadBookmarks(String userId) async => fakeBookmarks;

  @override
  Future<List<QuestionModel>> getBookmarkedQuestions(String userId) async =>
      fakeQuestions;
}

void main() {
  group('BookmarkController local interaction state', () {
    late BookmarkController controller;
    late DatabaseService database;

    setUp(() {
      Get.reset();
      database = DatabaseService();
      Get.put<DatabaseService>(database);
      Get.put<UserController>(_FakeUserController());
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

    test('loadBookmarks populates questions directly without dumping all questions table', () async {
      final fakeRepo = _FakeBookmarkRepo(database);
      fakeRepo.fakeBookmarks = [
        BookmarkModel(userId: 'test-user-id', questionId: 42, savedAt: 1000),
      ];
      fakeRepo.fakeQuestions = [
        QuestionModel(
          id: 42,
          subjectId: 1,
          grade: 12,
          testId: 5,
          questionText: 'What is 2+2?',
          options: ['3', '4', '5'],
          correctOptionIndex: 1,
        ),
      ];

      final customCtrl = BookmarkController(
        repository: fakeRepo,
        questionRepository: QuestionRepository(databaseService: database),
      );

      await customCtrl.loadBookmarks();

      expect(customCtrl.bookmarkedIds.contains(42), isTrue);
      expect(customCtrl.bookmarkedQuestions.length, equals(1));
      expect(customCtrl.bookmarkedQuestions.first.questionText, equals('What is 2+2?'));
    });
  });
}
