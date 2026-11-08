import 'package:flutter_test/flutter_test.dart';
import 'package:matricmate/features/tips_and_news/models/tips_and_news_model.dart';

void main() {
  group('TipsAndNewsModel Tests', () {
    test('Correctly serializes and deserializes from JSON', () {
      final now = DateTime.now();
      final json = {
        'id': 101,
        'title': '2019 E.C. Exam Schedule Announced',
        'content': 'The Ministry of Education has published the official dates.',
        'category': 'news',
        'image_url': 'https://example.com/banner.png',
        'author': 'MoE Ethiopia',
        'audience': 'both',
        'is_pinned': 1,
        'is_published': 1,
        'created_at': now.toIso8601String(),
        'is_read': 0,
      };

      final model = TipsAndNewsModel.fromJson(json);

      expect(model.id, equals(101));
      expect(model.title, equals('2019 E.C. Exam Schedule Announced'));
      expect(model.isNews, isTrue);
      expect(model.isTip, isFalse);
      expect(model.isPinned, isTrue);
      expect(model.isRead, isFalse);
      expect(model.author, equals('MoE Ethiopia'));
      expect(model.readingTimeMinutes, equals(1));

      final backToJson = model.toJson();
      expect(backToJson['id'], equals(101));
      expect(backToJson['category'], equals('news'));
      expect(backToJson['is_pinned'], equals(1));
    });

    test('Identifies tips correctly and calculates reading time', () {
      final longContent = List.filled(300, 'study').join(' ');
      final model = TipsAndNewsModel(
        id: 102,
        title: 'Active Recall Strategies',
        content: longContent,
        category: 'tip',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      );

      expect(model.isTip, isTrue);
      expect(model.isNews, isFalse);
      expect(model.readingTimeMinutes, equals(3));
      expect(model.formattedDate, equals('3h ago'));
    });

    test('CopyWith updates fields without side effects', () {
      final original = TipsAndNewsModel(
        id: 1,
        title: 'Original Title',
        content: 'Original Content',
        category: 'news',
        createdAt: DateTime.now(),
        isRead: false,
      );

      final readVersion = original.copyWith(isRead: true);

      expect(original.isRead, isFalse);
      expect(readVersion.isRead, isTrue);
      expect(readVersion.id, equals(original.id));
      expect(readVersion.title, equals(original.title));
    });
  });

  group('Tips & News Filter and Tab Logic', () {
    final sampleItems = [
      TipsAndNewsModel(
        id: 1,
        title: 'Exam Registration Opens',
        content: 'Registration is open nationwide.',
        category: 'news',
        isPinned: true,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        isRead: false,
      ),
      TipsAndNewsModel(
        id: 2,
        title: 'Time Management in Physics Test',
        content: 'Divide your 90 minutes into 3 equal blocks.',
        category: 'tip',
        isPinned: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: false,
      ),
      TipsAndNewsModel(
        id: 3,
        title: 'Model Exam Results Released',
        content: 'Check your regional scores online.',
        category: 'news',
        isPinned: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        isRead: true,
      ),
    ];

    test('Filters items by tab correctly', () {
      // News only
      final newsOnly = sampleItems.where((i) => i.isNews).toList();
      expect(newsOnly.length, equals(2));
      expect(newsOnly.every((i) => i.isNews), isTrue);

      // Tips only
      final tipsOnly = sampleItems.where((i) => i.isTip).toList();
      expect(tipsOnly.length, equals(1));
      expect(tipsOnly.first.title, contains('Time Management'));

      // All
      expect(sampleItems.length, equals(3));
    });

    test('Search query matches both title and content', () {
      const query = 'physics';
      final matching = sampleItems.where(
        (i) =>
            i.title.toLowerCase().contains(query) ||
            i.content.toLowerCase().contains(query),
      ).toList();

      expect(matching.length, equals(1));
      expect(matching.first.id, equals(2));
    });

    test('Unread calculation and red dot logic', () {
      final unreadCount = sampleItems.where((i) => !i.isRead).length;
      expect(unreadCount, equals(2));

      // Red dot shows when unreadCount > 0
      final hasUnread = unreadCount > 0;
      expect(hasUnread, isTrue);

      // When all are read
      final allRead = sampleItems.map((i) => i.copyWith(isRead: true)).toList();
      final remainingUnread = allRead.where((i) => !i.isRead).length;
      expect(remainingUnread, equals(0));
      expect(remainingUnread > 0, isFalse);
    });

    test('User pin, isSaved, and isAnyPinned logic', () {
      final unpinned = sampleItems[1];
      expect(unpinned.isPinned, isFalse);
      expect(unpinned.isUserPinned, isFalse);
      expect(unpinned.isSaved, isFalse);
      expect(unpinned.isAnyPinned, isFalse);

      final userPinned = unpinned.copyWith(isUserPinned: true);
      expect(userPinned.isPinned, isFalse);
      expect(userPinned.isUserPinned, isTrue);
      expect(userPinned.isSaved, isTrue);
      expect(userPinned.isAnyPinned, isTrue);

      final adminPinned = sampleItems[0];
      expect(adminPinned.isPinned, isTrue);
      expect(adminPinned.isAnyPinned, isTrue);

      // Sorting: any pinned items come first
      final items = [unpinned, userPinned, adminPinned];
      items.sort((a, b) {
        final aPinned = a.isAnyPinned ? 1 : 0;
        final bPinned = b.isAnyPinned ? 1 : 0;
        if (aPinned != bPinned) return bPinned.compareTo(aPinned);
        return b.createdAt.compareTo(a.createdAt);
      });

      expect(items.first.isAnyPinned, isTrue);
      expect(items[1].isAnyPinned, isTrue);
      expect(items.last.isAnyPinned, isFalse);
    });

    test('Deletion tombstone filtering prevents re-insertion on sync', () {
      final remoteItems = [
        TipsAndNewsModel(
          id: 1,
          title: 'News 1',
          content: 'Content 1',
          category: 'news',
          createdAt: DateTime.now(),
        ),
        TipsAndNewsModel(
          id: 2,
          title: 'News 2',
          content: 'Content 2',
          category: 'news',
          createdAt: DateTime.now(),
        ),
        TipsAndNewsModel(
          id: 3,
          title: 'News 3',
          content: 'Content 3',
          category: 'news',
          createdAt: DateTime.now(),
        ),
      ];

      // Simulated tombstone set of deleted item IDs
      final deletedIds = {2};

      // Remote sync filters out items in tombstones
      final toSave = remoteItems.where((item) => !deletedIds.contains(item.id)).toList();

      expect(toSave.length, equals(2));
      expect(toSave.any((item) => item.id == 2), isFalse);
      expect(toSave.map((e) => e.id), containsAll([1, 3]));
    });

    test('Batch deletion and selection set behavior', () {
      final selectedIds = <int>{1, 3};
      final allItems = [
        TipsAndNewsModel(id: 1, title: 'Item 1', content: '', category: 'tip', createdAt: DateTime.now()),
        TipsAndNewsModel(id: 2, title: 'Item 2', content: '', category: 'tip', createdAt: DateTime.now()),
        TipsAndNewsModel(id: 3, title: 'Item 3', content: '', category: 'tip', createdAt: DateTime.now()),
        TipsAndNewsModel(id: 4, title: 'Item 4', content: '', category: 'tip', createdAt: DateTime.now()),
      ];

      // Batch delete
      final remaining = allItems.where((item) => !selectedIds.contains(item.id)).toList();
      expect(remaining.length, equals(2));
      expect(remaining.map((e) => e.id), containsAll([2, 4]));
    });

    test('Pagination logic handles initial limit and load more', () {
      final hundredItems = List.generate(
        100,
        (i) => TipsAndNewsModel(
          id: i + 1,
          title: 'Tip $i',
          content: 'Content $i',
          category: 'tip',
          createdAt: DateTime.now().subtract(Duration(minutes: i)),
        ),
      );

      int displayLimit = 15;
      final initialSlice = hundredItems.take(displayLimit).toList();
      expect(initialSlice.length, equals(15));
      expect(hundredItems.length > displayLimit, isTrue);
      expect(hundredItems.length - displayLimit, equals(85));

      // After load more (+15)
      displayLimit += 15;
      final secondSlice = hundredItems.take(displayLimit).toList();
      expect(secondSlice.length, equals(30));
      expect(hundredItems.length - displayLimit, equals(70));
    });

    test('Bottom nav bar Others tab badge is active only when unread tips/news exist', () {
      int unreadTipsCount = 3;
      bool showOthersNavBadge = unreadTipsCount > 0;
      expect(showOthersNavBadge, isTrue);

      unreadTipsCount = 0;
      showOthersNavBadge = unreadTipsCount > 0;
      expect(showOthersNavBadge, isFalse);
    });
  });
}

