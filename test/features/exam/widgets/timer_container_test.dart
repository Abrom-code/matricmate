import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matricmate/features/exam/screens/ready/widgets/timer_container.dart';

void main() {
  testWidgets('describes practice mode and calls the toggle callback', (
    tester,
  ) async {
    var changes = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TimerContainer(
            time: 90,
            value: false,
            onChange: () => changes++,
          ),
        ),
      ),
    );

    expect(find.textContaining('Practice mode is on'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    expect(changes, 1);
  });

  testWidgets('describes the timer and hidden answers in exam mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TimerContainer(time: 90, value: true, onChange: _doNothing),
        ),
      ),
    );

    expect(find.textContaining('Answers are hidden'), findsOneWidget);
    expect(find.textContaining('90-minute timer'), findsOneWidget);
  });
}

void _doNothing() {}
