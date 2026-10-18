import 'package:flutter_test/flutter_test.dart';
import 'package:matricmate/features/notifications/services/notification_link_parser.dart';

void main() {
  group('NotificationLinkParser', () {
    // ── 1. Basic [a]url[/a] tags ──────────────────────────────────────────

    test('parses [a]https://t.me/matric_et[/a]', () {
      const text = 'Join us: [a]https://t.me/matric_et[/a]';
      final segments = NotificationLinkParser.parseSegments(text);

      expect(segments.length, 2);
      expect(segments[0].isLink, isFalse);
      expect(segments[0].text, 'Join us: ');

      expect(segments[1].isLink, isTrue);
      expect(segments[1].text, 'https://t.me/matric_et');
      expect(segments[1].link?.url, 'https://t.me/matric_et');
      expect(segments[1].link?.isTelegram, isTrue);
    });

    test('parses [a] https://t.me/matric_et [/a] with surrounding spaces', () {
      const text = 'Check [a] https://t.me/matric_et [/a] now!';
      final segments = NotificationLinkParser.parseSegments(text);

      expect(segments.length, 3);
      expect(segments[1].isLink, isTrue);
      expect(segments[1].text, 'https://t.me/matric_et');
      expect(segments[1].link?.url, 'https://t.me/matric_et');
      expect(segments[1].link?.isTelegram, isTrue);
      expect(segments[2].text, ' now!');
    });

    test('is case-insensitive for [A]...[/A]', () {
      const text = 'Check [A]https://t.me/matric_et[/A]';
      final segments = NotificationLinkParser.parseSegments(text);

      expect(segments.length, 2);
      expect(segments[1].isLink, isTrue);
      expect(segments[1].text, 'https://t.me/matric_et');
      expect(segments[1].link?.url, 'https://t.me/matric_et');
    });

    // ── 2. Tag attributes: href, url, = ────────────────────────────────────

    test('parses [a href="https://example.com"]Click Here[/a]', () {
      const text = 'Please [a href="https://example.com"]Click Here[/a] to see.';
      final segments = NotificationLinkParser.parseSegments(text);

      expect(segments.length, 3);
      expect(segments[1].isLink, isTrue);
      expect(segments[1].text, 'Click Here');
      expect(segments[1].link?.url, 'https://example.com');
      expect(segments[1].link?.isTelegram, isFalse);
      expect(segments[1].link?.actionButtonLabel, 'Click Here');
    });

    test('parses [a=https://t.me/channel]Telegram Channel[/a]', () {
      const text = '[a=https://t.me/channel]Telegram Channel[/a]';
      final segments = NotificationLinkParser.parseSegments(text);

      expect(segments.length, 1);
      expect(segments[0].isLink, isTrue);
      expect(segments[0].text, 'Telegram Channel');
      expect(segments[0].link?.url, 'https://t.me/channel');
      expect(segments[0].link?.isTelegram, isTrue);
    });

    test('parses [a url="https://matricmate.com"]Website[/a]', () {
      const text = '[a url="https://matricmate.com"]Website[/a]';
      final segments = NotificationLinkParser.parseSegments(text);

      expect(segments.length, 1);
      expect(segments[0].isLink, isTrue);
      expect(segments[0].text, 'Website');
      expect(segments[0].link?.url, 'https://matricmate.com');
    });

    // ── 3. Piped and Parentheses syntax ────────────────────────────────────

    test('parses [a]Join Telegram|https://t.me/matric_et[/a]', () {
      const text = 'News: [a]Join Telegram|https://t.me/matric_et[/a]';
      final segments = NotificationLinkParser.parseSegments(text);

      expect(segments.length, 2);
      expect(segments[1].isLink, isTrue);
      expect(segments[1].text, 'Join Telegram');
      expect(segments[1].link?.url, 'https://t.me/matric_et');
      expect(segments[1].link?.isTelegram, isTrue);
    });

    test('parses [a]https://t.me/matric_et|Join Telegram[/a] (inverted pipe)', () {
      const text = '[a]https://t.me/matric_et|Join Telegram[/a]';
      final segments = NotificationLinkParser.parseSegments(text);

      expect(segments.length, 1);
      expect(segments[0].isLink, isTrue);
      expect(segments[0].text, 'Join Telegram');
      expect(segments[0].link?.url, 'https://t.me/matric_et');
    });

    test('parses [a]Join Telegram (https://t.me/matric_et)[/a]', () {
      const text = '[a]Join Telegram (https://t.me/matric_et)[/a]';
      final segments = NotificationLinkParser.parseSegments(text);

      expect(segments.length, 1);
      expect(segments[0].isLink, isTrue);
      expect(segments[0].text, 'Join Telegram');
      expect(segments[0].link?.url, 'https://t.me/matric_et');
    });

    // ── 4. Fallback to notification payload ────────────────────────────────

    test('uses payload url when [a] contains only label', () {
      const text = 'Update available! [a]Download Now[/a]';
      final payload = {'url': 'https://matricmate.com/app'};
      final segments = NotificationLinkParser.parseSegments(
        text,
        payload: payload,
      );

      expect(segments.length, 2);
      expect(segments[1].isLink, isTrue);
      expect(segments[1].text, 'Download Now');
      expect(segments[1].link?.url, 'https://matricmate.com/app');
    });

    // ── 5. HTML and Markdown links ─────────────────────────────────────────

    test('parses HTML <a href="https://t.me/matric_et">Telegram</a>', () {
      const text = 'Check <a href="https://t.me/matric_et">Telegram</a>';
      final segments = NotificationLinkParser.parseSegments(text);

      expect(segments.length, 2);
      expect(segments[1].isLink, isTrue);
      expect(segments[1].text, 'Telegram');
      expect(segments[1].link?.url, 'https://t.me/matric_et');
    });

    test('parses Markdown [Telegram](https://t.me/matric_et)', () {
      const text = 'Check [Telegram](https://t.me/matric_et)';
      final segments = NotificationLinkParser.parseSegments(text);

      expect(segments.length, 2);
      expect(segments[1].isLink, isTrue);
      expect(segments[1].text, 'Telegram');
      expect(segments[1].link?.url, 'https://t.me/matric_et');
    });

    // ── 6. Standalone raw URLs in text ─────────────────────────────────────

    test('auto-links standalone raw URLs', () {
      const text = 'Visit https://matricmate.com for more info.';
      final segments = NotificationLinkParser.parseSegments(text);

      expect(segments.length, 3);
      expect(segments[0].text, 'Visit ');
      expect(segments[1].isLink, isTrue);
      expect(segments[1].text, 'https://matricmate.com');
      expect(segments[2].text, ' for more info.');
    });

    // ── 7. Mixed formatting: [b], [i], [u] with links ─────────────────────

    test('preserves bold, italic, and underline in surrounding text', () {
      const text = '[b]Important:[/b] Join [a]https://t.me/matric_et[/a] today!';
      final segments = NotificationLinkParser.parseSegments(text);

      expect(segments.length, 4);
      expect(segments[0].text, 'Important:');
      expect(segments[0].isBold, isTrue);

      expect(segments[1].text, ' Join ');
      expect(segments[1].isBold, isFalse);

      expect(segments[2].isLink, isTrue);
      expect(segments[2].text, 'https://t.me/matric_et');

      expect(segments[3].text, ' today!');
    });

    // ── 8. stripTags with question and explanation formatting ──────────────

    test('stripTags cleanly strips BBCode, HTML, math, and table tags', () {
      const text =
          r'[b]Q1:[/b] Solve $\Delta > 0$ with [table][row][cell]A[/cell][/row][/table] [a]https://t.me/matric_et[/a]!';
      final clean = NotificationLinkParser.stripTags(text);
      expect(clean, r'Q1: Solve \Delta > 0 with A https://t.me/matric_et!');
    });

    // ── 9. extractPrimaryLink and extractAllLinks ──────────────────────────

    test('extractPrimaryLink finds first link in text', () {
      const text = 'Updates on [a]https://t.me/matric_et[/a]!';
      final link = NotificationLinkParser.extractPrimaryLink(text);
      expect(link, isNotNull);
      expect(link?.url, 'https://t.me/matric_et');
      expect(link?.isTelegram, isTrue);
      expect(link?.actionButtonLabel, 'Join Telegram');
    });

    test('extractAllLinks finds all distinct links and deduplicates', () {
      const text =
          'Join [a]https://t.me/channel1[/a] and [a href="https://example.com"]Website[/a] or [a]https://t.me/channel1[/a]';
      final links = NotificationLinkParser.extractAllLinks(text);
      expect(links.length, 2);
      expect(links[0].url, 'https://t.me/channel1');
      expect(links[0].isTelegram, isTrue);
      expect(links[1].url, 'https://example.com');
      expect(links[1].text, 'Website');
    });

    test('extractAllLinks includes payload url if not already in text', () {
      const text = 'Check [a]https://t.me/channel[/a]';
      final payload = {'url': 'https://matricmate.com'};
      final links = NotificationLinkParser.extractAllLinks(text, payload: payload);
      expect(links.length, 2);
      expect(links[0].url, 'https://t.me/channel');
      expect(links[1].url, 'https://matricmate.com');
    });
  });
}

