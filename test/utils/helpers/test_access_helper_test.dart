import 'package:flutter_test/flutter_test.dart';
import 'package:matricmate/features/authentication/models/user_model.dart';
import 'package:matricmate/features/exam/models/test_model.dart';
import 'package:matricmate/features/notes/models/note_model.dart';
import 'package:matricmate/utils/helpers/test_access_helper.dart';

void main() {
  group('TestAccessHelper.canAccess', () {
    final activeUser = UserModel(
      id: 'u1',
      email: 'active@test.com',
      firstName: 'Abebe',
      lastName: 'Kebede',
      stream: 'natural',
      status: 'active',
    );

    final pendingUser = UserModel(
      id: 'u2',
      email: 'pending@test.com',
      firstName: 'Kebede',
      lastName: 'Tesfaye',
      stream: 'natural',
      status: 'pending',
    );

    final inactiveUser = UserModel(
      id: 'u3',
      email: 'inactive@test.com',
      firstName: 'Almaz',
      lastName: 'Desta',
      stream: 'natural',
      status: 'inactive',
    );

    for (final testType in ['chapter', 'grade', 'entrance', 'model']) {
      group('for $testType test type', () {
        final freeTest = TestModel(
          id: 101,
          subjectId: 1,
          questionCount: 20,
          createdAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
          type: testType,
          title: '$testType Test (Free)',
          time: 30,
          isPremium: false,
        );

        final premiumTest = TestModel(
          id: 102,
          subjectId: 1,
          questionCount: 20,
          createdAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
          type: testType,
          title: '$testType Test (Premium)',
          time: 30,
          isPremium: true,
        );

        test('free test is accessible to active, pending, and inactive users', () {
          expect(
            TestAccessHelper.canAccess(test: freeTest, user: activeUser),
            isTrue,
          );
          expect(
            TestAccessHelper.canAccess(test: freeTest, user: pendingUser),
            isTrue,
          );
          expect(
            TestAccessHelper.canAccess(test: freeTest, user: inactiveUser),
            isTrue,
          );
        });

        test('premium test is only accessible to active users', () {
          expect(
            TestAccessHelper.canAccess(test: premiumTest, user: activeUser),
            isTrue,
          );
          expect(
            TestAccessHelper.canAccess(test: premiumTest, user: pendingUser),
            isFalse,
          );
          expect(
            TestAccessHelper.canAccess(test: premiumTest, user: inactiveUser),
            isFalse,
          );
        });
      });
    }
  });

  group('TestAccessHelper.sortForUser', () {
    final activeUser = UserModel(
      id: 'u1',
      email: 'active@test.com',
      firstName: 'Abebe',
      lastName: 'Kebede',
      stream: 'natural',
      status: 'active',
    );

    final pendingUser = UserModel(
      id: 'u2',
      email: 'pending@test.com',
      firstName: 'Kebede',
      lastName: 'Tesfaye',
      stream: 'natural',
      status: 'pending',
    );

    final inactiveUser = UserModel(
      id: 'u3',
      email: 'inactive@test.com',
      firstName: 'Almaz',
      lastName: 'Desta',
      stream: 'natural',
      status: 'inactive',
    );

    final test1Premium = TestModel(
      id: 1,
      subjectId: 1,
      questionCount: 10,
      createdAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
      type: 'chapter',
      title: 'Test 1 (Premium)',
      time: 20,
      isPremium: true,
    );

    final test2Free = TestModel(
      id: 2,
      subjectId: 1,
      questionCount: 10,
      createdAt: DateTime.parse('2026-01-02T00:00:00.000Z'),
      type: 'chapter',
      title: 'Test 2 (Free)',
      time: 20,
      isPremium: false,
    );

    final test3Premium = TestModel(
      id: 3,
      subjectId: 1,
      questionCount: 10,
      createdAt: DateTime.parse('2026-01-03T00:00:00.000Z'),
      type: 'chapter',
      title: 'Test 3 (Premium)',
      time: 20,
      isPremium: true,
    );

    final test4Free = TestModel(
      id: 4,
      subjectId: 1,
      questionCount: 10,
      createdAt: DateTime.parse('2026-01-04T00:00:00.000Z'),
      type: 'chapter',
      title: 'Test 4 (Free)',
      time: 20,
      isPremium: false,
    );

    final originalList = [test1Premium, test2Free, test3Premium, test4Free];

    test('places free tests on top for inactive users while preserving relative order', () {
      final sorted = TestAccessHelper.sortForUser(originalList, inactiveUser);
      expect(sorted.map((t) => t.id).toList(), [2, 4, 1, 3]);
      expect(sorted[0].isPremium, isFalse);
      expect(sorted[1].isPremium, isFalse);
      expect(sorted[2].isPremium, isTrue);
      expect(sorted[3].isPremium, isTrue);
    });

    test('places free tests on top for pending users while preserving relative order', () {
      final sorted = TestAccessHelper.sortForUser(originalList, pendingUser);
      expect(sorted.map((t) => t.id).toList(), [2, 4, 1, 3]);
      expect(sorted[0].isPremium, isFalse);
      expect(sorted[1].isPremium, isFalse);
      expect(sorted[2].isPremium, isTrue);
      expect(sorted[3].isPremium, isTrue);
    });

    test('preserves original natural order for active subscribers', () {
      final sorted = TestAccessHelper.sortForUser(originalList, activeUser);
      expect(sorted.map((t) => t.id).toList(), [1, 2, 3, 4]);
    });

    test('handles empty test lists gracefully', () {
      final sorted = TestAccessHelper.sortForUser([], inactiveUser);
      expect(sorted, isEmpty);
    });
  });

  group('TestAccessHelper.sortNotesForUser', () {
    final activeUser = UserModel(
      id: 'u1',
      email: 'active@test.com',
      firstName: 'Abebe',
      lastName: 'Kebede',
      stream: 'natural',
      status: 'active',
    );

    final pendingUser = UserModel(
      id: 'u2',
      email: 'pending@test.com',
      firstName: 'Kebede',
      lastName: 'Tesfaye',
      stream: 'natural',
      status: 'pending',
    );

    final inactiveUser = UserModel(
      id: 'u3',
      email: 'inactive@test.com',
      firstName: 'Almaz',
      lastName: 'Desta',
      stream: 'natural',
      status: 'inactive',
    );

    const note1Premium = NoteModel(
      id: 1,
      subjectId: 1,
      grade: 9,
      chapterNumber: 1,
      title: 'Chapter 1 Notes (Premium)',
      fileKey: 'key_1',
      isPremium: true,
      orderIndex: 1,
    );

    const note2Free = NoteModel(
      id: 2,
      subjectId: 1,
      grade: 9,
      chapterNumber: 2,
      title: 'Chapter 2 Notes (Free)',
      fileKey: 'key_2',
      isPremium: false,
      orderIndex: 2,
    );

    const note3Premium = NoteModel(
      id: 3,
      subjectId: 1,
      grade: 9,
      chapterNumber: 3,
      title: 'Chapter 3 Notes (Premium)',
      fileKey: 'key_3',
      isPremium: true,
      orderIndex: 3,
    );

    const note4Free = NoteModel(
      id: 4,
      subjectId: 1,
      grade: 9,
      chapterNumber: 4,
      title: 'Chapter 4 Notes (Free)',
      fileKey: 'key_4',
      isPremium: false,
      orderIndex: 4,
    );

    final originalNotes = [note1Premium, note2Free, note3Premium, note4Free];

    test('places free notes on top for inactive users while preserving relative order', () {
      final sorted = TestAccessHelper.sortNotesForUser(originalNotes, inactiveUser);
      expect(sorted.map((n) => n.id).toList(), [2, 4, 1, 3]);
      expect(sorted[0].isPremium, isFalse);
      expect(sorted[1].isPremium, isFalse);
      expect(sorted[2].isPremium, isTrue);
      expect(sorted[3].isPremium, isTrue);
    });

    test('places free notes on top for pending users while preserving relative order', () {
      final sorted = TestAccessHelper.sortNotesForUser(originalNotes, pendingUser);
      expect(sorted.map((n) => n.id).toList(), [2, 4, 1, 3]);
      expect(sorted[0].isPremium, isFalse);
      expect(sorted[1].isPremium, isFalse);
      expect(sorted[2].isPremium, isTrue);
      expect(sorted[3].isPremium, isTrue);
    });

    test('preserves original database order for active subscribers', () {
      final sorted = TestAccessHelper.sortNotesForUser(originalNotes, activeUser);
      expect(sorted.map((n) => n.id).toList(), [1, 2, 3, 4]);
    });

    test('handles empty notes lists gracefully', () {
      final sorted = TestAccessHelper.sortNotesForUser([], inactiveUser);
      expect(sorted, isEmpty);
    });
  });
}
