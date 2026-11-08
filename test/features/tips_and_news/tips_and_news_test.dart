import 'package:flutter_test/flutter_test.dart';
import 'package:matricmate/features/tips_and_news/models/tips_and_news_model.dart';
import 'package:matricmate/features/tips_and_news/controllers/tips_and_news_controller.dart';

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
  });
}

