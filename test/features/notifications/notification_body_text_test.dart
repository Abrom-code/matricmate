import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matricmate/features/notifications/screens/widgets/notification_body_text.dart';

void main() {
  group('NotificationBodyText Widget', () {
    testWidgets('renders plain text and link text properly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationBodyText(
              text: 'Hello, please visit [a]https://t.me/matric_et[/a] today!',
            ),
          ),
        ),
      );

      expect(find.byType(NotificationBodyText), findsOneWidget);
      expect(find.byType(RichText), findsWidgets);
    });

    testWidgets('tapping link calls onLinkTap callback with target url',
        (tester) async {
      String? tappedUrl;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationBodyText(
              text: 'Check [a href="https://t.me/matric_et"]Telegram[/a] now.',
              onLinkTap: (url) {
                tappedUrl = url;
              },
            ),
          ),
        ),
      );

      final richTextFinder = find.byType(RichText);
      expect(richTextFinder, findsWidgets);

      // Find the RichText that contains our link TextSpan
      RichText? targetRichText;
      for (final element in richTextFinder.evaluate()) {
        final widget = element.widget as RichText;
        if (widget.text.toPlainText().contains('Telegram')) {
          targetRichText = widget;
          break;
        }
      }
      expect(targetRichText, isNotNull);

      // Verify the TextSpan has a TapGestureRecognizer and invoke it
      final span = targetRichText!.text as TextSpan;
      TapGestureRecognizer? recognizer;
      span.visitChildren((child) {
        if (child is TextSpan && child.text == 'Telegram') {
          recognizer = child.recognizer as TapGestureRecognizer?;
          return false;
        }
        return true;
      });

      expect(recognizer, isNotNull);
      recognizer?.onTap?.call();

      expect(tappedUrl, 'https://t.me/matric_et');
    });

    testWidgets('renders multiple links and triggers independent taps',
        (tester) async {
      final tapped = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationBodyText(
              text:
                  'Join [a]https://t.me/channel1[/a] and [a href="https://example.com"]Website[/a]',
              onLinkTap: (url) {
                tapped.add(url);
              },
            ),
          ),
        ),
      );

      final richTextFinder = find.byType(RichText);
      expect(richTextFinder, findsWidgets);

      // Collect all TapGestureRecognizers from the RichTexts
      final recognizers = <String, TapGestureRecognizer>{};
      for (final element in richTextFinder.evaluate()) {
        final widget = element.widget as RichText;
        if (widget.text is TextSpan) {
          (widget.text as TextSpan).visitChildren((child) {
            if (child is TextSpan && child.recognizer is TapGestureRecognizer) {
              final text = child.text ?? '';
              recognizers[text] = child.recognizer as TapGestureRecognizer;
            }
            return true;
          });
        }
      }

      expect(recognizers.containsKey('https://t.me/channel1'), isTrue);
      recognizers['https://t.me/channel1']?.onTap?.call();

      expect(recognizers.containsKey('Website'), isTrue);
      recognizers['Website']?.onTap?.call();

      expect(tapped, ['https://t.me/channel1', 'https://example.com']);
    });

    testWidgets(
        'renders question and explanation formatting (math, tables, bold)',
        (tester) async {
      const text = '''
[b]Question 1:[/b] What is the solution to \$x^2 = 4\$?
[table]
[row][cell]Option[/cell][cell]Value[/cell][/row]
[row][cell]A[/cell][cell]2[/cell][/row]
[/table]
Check [a]https://t.me/matric_et[/a] for full explanation!
''';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationBodyText(text: text),
          ),
        ),
      );

      expect(find.byType(NotificationBodyText), findsOneWidget);
      expect(find.textContaining('Question 1:'), findsWidgets);
    });
  });
}

