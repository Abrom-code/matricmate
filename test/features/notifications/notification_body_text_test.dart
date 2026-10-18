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
  });
}
