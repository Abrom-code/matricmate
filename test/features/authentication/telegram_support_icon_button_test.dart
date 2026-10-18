import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matricmate/features/authentication/screens/widgets/telegram_support_icon_button.dart';

void main() {
  testWidgets('TelegramSupportIconButton renders and responds to taps', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TelegramSupportIconButton(),
        ),
      ),
    );

    // Verify Telegram send icon is rendered
    expect(find.byIcon(Icons.send_rounded), findsOneWidget);
    expect(find.byType(TelegramSupportIconButton), findsOneWidget);

    // Tap the icon
    await tester.tap(find.byType(TelegramSupportIconButton));
    await tester.pump();
  });
}
