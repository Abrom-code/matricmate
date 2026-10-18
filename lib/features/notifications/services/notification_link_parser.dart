import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/personalization/utils/profile_actions_helper.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';
import 'package:url_launcher/url_launcher.dart';

/// Represents an interactive link extracted from notification text or payload.
class NotificationLink {
  const NotificationLink({
    required this.text,
    required this.url,
  });

  /// Display text for the link.
  final String text;

  /// Target URL, deep link, or in-app route.
  final String url;

  /// Whether this link points to Telegram (app or web).
  bool get isTelegram {
    final lower = url.trim().toLowerCase();
    return lower.startsWith('tg://') ||
        lower.startsWith('t.me/') ||
        lower.startsWith('https://t.me/') ||
        lower.startsWith('http://t.me/') ||
        lower.startsWith('telegram.me/') ||
        lower.startsWith('https://telegram.me/') ||
        (url.trim().startsWith('@') && !url.trim().contains(' '));
  }

  /// Context-aware label for prominent action buttons.
  String get actionButtonLabel {
    final cleanText = text.trim();
    if (cleanText.isNotEmpty &&
        cleanText.length <= 25 &&
        !cleanText.startsWith('http://') &&
        !cleanText.startsWith('https://')) {
      return cleanText;
    }
    if (isTelegram) {
      return 'Join Telegram';
    }
    return 'Open Link';
  }
}

/// Represents a parsed segment of notification text (either styled text or clickable link).
class NotificationTextSegment {
  const NotificationTextSegment({
    required this.text,
    this.isLink = false,
    this.link,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
  });

  final String text;
  final bool isLink;
  final NotificationLink? link;
  final bool isBold;
  final bool isItalic;
  final bool isUnderline;

  /// Merges base style with segment formatting (bold, italic, underline).
  TextStyle applyFormatting(TextStyle baseStyle) {
    var style = baseStyle;
    if (isBold) {
      style = style.copyWith(fontWeight: FontWeight.w700);
    }
    if (isItalic) {
      style = style.copyWith(fontStyle: FontStyle.italic);
    }
    if (isUnderline) {
      style = style.copyWith(
        decoration: TextDecoration.underline,
        decorationColor: style.color?.withValues(alpha: 0.6),
      );
    }
    return style;
  }
}

/// Robust parser and navigator for notification links, supporting:
/// - `[a]the link[/a]`
/// - `[a href="url"]text[/a]` / `[a=url]text[/a]` / `[a url="url"]text[/a]`
/// - `[a]text|url[/a]` / `[a]url|text[/a]`
/// - `[a]text (url)[/a]`
/// - `<a href="url">text</a>`
/// - `[text](url)`
/// - Raw URLs (`https://...`, `t.me/...`, `www....`)
class NotificationLinkParser {
  NotificationLinkParser._();

  // BBCode [a] anchor tags
  static final RegExp _bbcodeLinkRegex = RegExp(
    r'\[a(?:\s+href\s*=\s*["' "'" r']?([^"' "'" r'\]\s>]+)["' "'" r']?|\s+url\s*=\s*["' "'" r']?([^"' "'" r'\]\s>]+)["' "'" r']?|=\s*([^\s\]]+))?\s*\](.*?)\[/a\]',
    caseSensitive: false,
    dotAll: true,
  );

  // HTML <a href="...">text</a>
  static final RegExp _htmlLinkRegex = RegExp(
    r'<a(?:\s+[^>]*?)?href\s*=\s*["' "'" r']?([^"' "'" r'\s>]+)["' "'" r']?[^>]*>(.*?)</a>',
    caseSensitive: false,
    dotAll: true,
  );

  // Markdown [text](url)
  static final RegExp _markdownLinkRegex = RegExp(
    r'\[([^\]\r\n]+)\]\(((?:https?://|tg://|t\.me/|mailto:|tel:)[^\)\s]+)\)',
    caseSensitive: false,
  );

  // Raw URLs in plain text
  static final RegExp _rawUrlRegex = RegExp(
    r'(https?://[^\s<>"' "'" r'\]\)]+|(?<!@)(?:t\.me|telegram\.me)/[a-zA-Z0-9_+/]+|(?<![\w@])www\.[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}[^\s<>"' "'" r'\]\)]*)',
    caseSensitive: false,
  );

  // Inline formatting tags: [b], [i], [u]
  static final RegExp _inlineFormatRegex = RegExp(
    r'\[([biu])\](.*?)\[/\1\]',
    caseSensitive: false,
    dotAll: true,
  );

  /// Strips markup tags from text for clean preview tiles and push notifications.
  static String stripTags(String rawText) {
    if (rawText.isEmpty) return '';
    var text = rawText;

    // 1. Replace [a...]content[/a] with content (or label if piped)
    text = text.replaceAllMapped(_bbcodeLinkRegex, (m) {
      final inner = (m.group(4) ?? '').trim();
      if (inner.contains('|')) {
        return inner.split('|').first.trim();
      }
      return inner;
    });

    // 2. Replace <a...>content</a> with content
    text = text.replaceAllMapped(_htmlLinkRegex, (m) {
      return (m.group(2) ?? '').trim();
    });

    // 3. Replace [text](url) with text
    text = text.replaceAllMapped(_markdownLinkRegex, (m) {
      return (m.group(1) ?? '').trim();
    });

    // 4. Remove other BBCode tags like [b], [/b], [i], [u]
    text = text.replaceAll(RegExp(r'\[/?[a-zA-Z]+(?:=[^\]]+)?\]'), '');

    // 5. Remove HTML tags
    text = text.replaceAll(RegExp(r'</?[a-zA-Z]+(?:[^>]*?)>'), '');

    return text.trim();
  }

  /// Extracts the first primary link from text or payload, if available.
  static NotificationLink? extractPrimaryLink(
    String rawText, {
    Map<String, dynamic>? payload,
  }) {
    // 1. Check parsed segments from body
    final segments = parseSegments(rawText, payload: payload);
    for (final seg in segments) {
      if (seg.isLink && seg.link != null) {
        return seg.link;
      }
    }

    // 2. Fall back to payload keys
    if (payload != null) {
      final payloadUrl = payload['url'] ??
          payload['link'] ??
          payload['action_url'] ??
          payload['target_url'] ??
          payload['href'];
      if (payloadUrl != null && payloadUrl.toString().trim().isNotEmpty) {
        final urlStr = payloadUrl.toString().trim();
        return NotificationLink(
          text: payload['action_text']?.toString().trim() ?? 'Open Link',
          url: urlStr,
        );
      }
    }

    return null;
  }

  /// Parses text into styled and clickable segments.
  static List<NotificationTextSegment> parseSegments(
    String rawText, {
    Map<String, dynamic>? payload,
  }) {
    if (rawText.isEmpty) return const [];

    final matches = <_ExplicitTagMatch>[];

    // 1. Collect BBCode [a] tags
    for (final m in _bbcodeLinkRegex.allMatches(rawText)) {
      final explicitAttr = m.group(1) ?? m.group(2) ?? m.group(3);
      final innerContent = m.group(4) ?? '';
      final parsed = _resolveLinkParts(
        explicitAttr: explicitAttr,
        innerContent: innerContent,
        payload: payload,
      );
      matches.add(
        _ExplicitTagMatch(
          start: m.start,
          end: m.end,
          displayText: parsed.text,
          targetUrl: parsed.url,
        ),
      );
    }

    // 2. Collect HTML <a href="..."> tags
    for (final m in _htmlLinkRegex.allMatches(rawText)) {
      final href = m.group(1) ?? '';
      final inner = m.group(2) ?? '';
      matches.add(
        _ExplicitTagMatch(
          start: m.start,
          end: m.end,
          displayText: inner.trim().isNotEmpty ? inner.trim() : href.trim(),
          targetUrl: href.trim(),
        ),
      );
    }

    // 3. Collect Markdown [text](url) links
    for (final m in _markdownLinkRegex.allMatches(rawText)) {
      final text = m.group(1) ?? '';
      final url = m.group(2) ?? '';
      matches.add(
        _ExplicitTagMatch(
          start: m.start,
          end: m.end,
          displayText: text.trim(),
          targetUrl: url.trim(),
        ),
      );
    }

    // Sort matches by start position and remove overlaps
    matches.sort((a, b) => a.start.compareTo(b.start));
    final nonOverlapping = <_ExplicitTagMatch>[];
    int lastEnd = 0;
    for (final m in matches) {
      if (m.start >= lastEnd) {
        nonOverlapping.add(m);
        lastEnd = m.end;
      }
    }

    // Build segment list
    final segments = <NotificationTextSegment>[];
    int cursor = 0;

    for (final tag in nonOverlapping) {
      if (tag.start > cursor) {
        final chunk = rawText.substring(cursor, tag.start);
        _parseChunkWithRawUrlsAndFormatting(chunk, segments);
      }

      segments.add(
        NotificationTextSegment(
          text: tag.displayText,
          isLink: true,
          link: NotificationLink(
            text: tag.displayText,
            url: tag.targetUrl,
          ),
        ),
      );
      cursor = tag.end;
    }

    if (cursor < rawText.length) {
      final tail = rawText.substring(cursor);
      _parseChunkWithRawUrlsAndFormatting(tail, segments);
    }

    return segments;
  }

  /// Parses non-explicit text for raw URLs and inline BBCode formatting ([b], [i], [u]).
  static void _parseChunkWithRawUrlsAndFormatting(
    String chunk,
    List<NotificationTextSegment> out,
  ) {
    if (chunk.isEmpty) return;

    // First scan for raw URLs
    final urlMatches = _rawUrlRegex.allMatches(chunk).toList();
    if (urlMatches.isEmpty) {
      _parseInlineFormatting(chunk, out);
      return;
    }

    int cursor = 0;
    for (final m in urlMatches) {
      if (m.start > cursor) {
        final textBefore = chunk.substring(cursor, m.start);
        _parseInlineFormatting(textBefore, out);
      }

      final url = m.group(0)!;
      out.add(
        NotificationTextSegment(
          text: url,
          isLink: true,
          link: NotificationLink(
            text: url,
            url: url,
          ),
        ),
      );
      cursor = m.end;
    }

    if (cursor < chunk.length) {
      final tail = chunk.substring(cursor);
      _parseInlineFormatting(tail, out);
    }
  }

  /// Parses inline formatting ([b], [i], [u]) in plain text chunks.
  static void _parseInlineFormatting(
    String text,
    List<NotificationTextSegment> out,
  ) {
    if (text.isEmpty) return;

    final formatMatches = _inlineFormatRegex.allMatches(text).toList();
    if (formatMatches.isEmpty) {
      out.add(NotificationTextSegment(text: text));
      return;
    }

    int cursor = 0;
    for (final m in formatMatches) {
      if (m.start > cursor) {
        out.add(
          NotificationTextSegment(
            text: text.substring(cursor, m.start),
          ),
        );
      }

      final tag = (m.group(1) ?? '').toLowerCase();
      final content = m.group(2) ?? '';
      out.add(
        NotificationTextSegment(
          text: content,
          isBold: tag == 'b',
          isItalic: tag == 'i',
          isUnderline: tag == 'u',
        ),
      );
      cursor = m.end;
    }

    if (cursor < text.length) {
      out.add(
        NotificationTextSegment(
          text: text.substring(cursor),
        ),
      );
    }
  }

  /// Resolves display text and URL from [a] tag parts.
  static NotificationLink _resolveLinkParts({
    String? explicitAttr,
    required String innerContent,
    Map<String, dynamic>? payload,
  }) {
    final trimmedInner = innerContent.trim();

    // 1. If explicit attribute provided: [a href="url"]text[/a]
    if (explicitAttr != null && explicitAttr.trim().isNotEmpty) {
      final url = explicitAttr.trim();
      final text = trimmedInner.isNotEmpty ? trimmedInner : url;
      return NotificationLink(text: text, url: url);
    }

    // 2. Pipe syntax: [a]Label|url[/a] or [a]url|Label[/a]
    if (trimmedInner.contains('|')) {
      final split = trimmedInner.split('|');
      final part1 = split[0].trim();
      final part2 = split.length > 1 ? split[1].trim() : '';

      if (_isLikelyUrl(part2)) {
        return NotificationLink(text: part1, url: part2);
      } else if (_isLikelyUrl(part1)) {
        return NotificationLink(text: part2, url: part1);
      } else {
        return NotificationLink(text: part1, url: part2);
      }
    }

    // 3. Parentheses syntax: [a]Label (url)[/a]
    final parenMatch = RegExp(
      r'^(.*?)\s*\(((?:https?://|t\.me/|tg://|www\.)\S+)\)$',
      caseSensitive: false,
    ).firstMatch(trimmedInner);
    if (parenMatch != null) {
      return NotificationLink(
        text: parenMatch.group(1)!.trim(),
        url: parenMatch.group(2)!.trim(),
      );
    }

    // 4. Content itself is a URL: [a]https://...[/a] or [a]t.me/...[/a]
    if (_isLikelyUrl(trimmedInner)) {
      return NotificationLink(text: trimmedInner, url: trimmedInner);
    }

    // 5. Content contains a URL: [a]Join us at https://t.me/channel[/a]
    final urlMatch = _rawUrlRegex.firstMatch(trimmedInner);
    if (urlMatch != null) {
      return NotificationLink(
        text: trimmedInner,
        url: urlMatch.group(0)!,
      );
    }

    // 6. Check payload URL if content is just a label: [a]Click here[/a]
    if (payload != null) {
      final payloadUrl = payload['url'] ??
          payload['link'] ??
          payload['action_url'] ??
          payload['target_url'] ??
          payload['href'];
      if (payloadUrl != null && payloadUrl.toString().trim().isNotEmpty) {
        return NotificationLink(
          text: trimmedInner.isNotEmpty ? trimmedInner : 'Open Link',
          url: payloadUrl.toString().trim(),
        );
      }
    }

    // 7. Fallback: treat inner content as both text and destination
    return NotificationLink(text: trimmedInner, url: trimmedInner);
  }

  /// Checks if string has URL characteristics.
  static bool _isLikelyUrl(String s) {
    final clean = s.trim().toLowerCase();
    if (clean.startsWith('http://') ||
        clean.startsWith('https://') ||
        clean.startsWith('t.me/') ||
        clean.startsWith('tg://') ||
        clean.startsWith('www.') ||
        clean.startsWith('mailto:') ||
        clean.startsWith('tel:')) {
      return true;
    }
    // Match common domain patterns e.g. matricmate.com or example.org/test
    return RegExp(
      r'^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}(?:/\S*)?$',
    ).hasMatch(clean);
  }

  /// Launches the link using native Telegram handler, in-app navigation, or external browser.
  static Future<void> launchLink(String rawUrl) async {
    final clean = rawUrl.trim();
    if (clean.isEmpty) return;

    // 1. Telegram links or handles: native app first, web browser fallback
    final lower = clean.toLowerCase();
    final isTelegram = lower.startsWith('tg://') ||
        lower.startsWith('t.me/') ||
        lower.startsWith('https://t.me/') ||
        lower.startsWith('http://t.me/') ||
        lower.startsWith('telegram.me/') ||
        lower.startsWith('https://telegram.me/') ||
        (clean.startsWith('@') && !clean.contains(' '));

    if (isTelegram) {
      await ProfileActionsHelper.launchTelegram(clean);
      return;
    }

    // 2. In-App routes: '/challenges', '/profile', etc.
    if (clean.startsWith('/') && !clean.startsWith('//')) {
      try {
        Get.toNamed(clean);
        return;
      } catch (e) {
        debugPrint('[NotificationLinkParser] In-app route failed: $e');
      }
    }

    // 3. Web URLs
    String targetUrl = clean;
    if (!targetUrl.contains('://')) {
      if (targetUrl.startsWith('www.') ||
          RegExp(r'^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}').hasMatch(targetUrl)) {
        targetUrl = 'https://$targetUrl';
      }
    }

    final uri = Uri.tryParse(targetUrl);
    if (uri == null || (!uri.hasScheme && !targetUrl.startsWith('http'))) {
      ToastHelper.error('Invalid link: $clean');
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        ToastHelper.error('Could not open link.');
      }
    } catch (e) {
      debugPrint('[NotificationLinkParser] Launch failed: $e');
      ToastHelper.error('Could not open link.');
    }
  }
}

class _ExplicitTagMatch {
  final int start;
  final int end;
  final String displayText;
  final String targetUrl;

  const _ExplicitTagMatch({
    required this.start,
    required this.end,
    required this.displayText,
    required this.targetUrl,
  });
}

