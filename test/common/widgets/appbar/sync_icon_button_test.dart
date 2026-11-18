import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matricmate/common/widgets/appbar/sync_icon_button.dart';

void main() {
  testWidgets('SyncIconButton triggers onPressed when idle', (tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: [
              SyncIconButton(
                isSyncing: false,
                onPressed: () => tapped = true,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(SyncIconButton), findsOneWidget);
    await tester.tap(find.byType(SyncIconButton));
    expect(tapped, isTrue);
  });

  testWidgets('SyncIconButton disables tap and animates rotation while syncing', (tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: [
              SyncIconButton(
                isSyncing: true,
                onPressed: () => tapped = true,
              ),
            ],
          ),
        ),
      ),
    );

    // Tap should be ignored while syncing
    await tester.tap(find.byType(SyncIconButton));
    expect(tapped, isFalse);

    final transformFinder = find.descendant(
      of: find.byType(SyncIconButton),
      matching: find.byType(Transform),
    );
    expect(transformFinder, findsOneWidget);

    final initialTransform = tester.widget<Transform>(transformFinder);
    final initialMatrix = initialTransform.transform.clone();

    // Advance 175ms (quarter of 700ms animation cycle)
    await tester.pump(const Duration(milliseconds: 175));

    final rotatedTransform = tester.widget<Transform>(transformFinder);
    final rotatedMatrix = rotatedTransform.transform;

    expect(initialMatrix, isNot(equals(rotatedMatrix)));
  });

  testWidgets('SyncIconButton smoothly finishes animation and resets when syncing ends', (tester) async {
    bool syncing = true;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          return MaterialApp(
            home: Scaffold(
              appBar: AppBar(
                actions: [
                  SyncIconButton(
                    isSyncing: syncing,
                    onPressed: () {},
                  ),
                ],
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () => setState(() => syncing = false),
              ),
            ),
          );
        },
      ),
    );

    // Starts spinning
    await tester.pump(const Duration(milliseconds: 200));

    // Stop syncing
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();

    // Settle the smooth completion animation
    await tester.pumpAndSettle();

    // After settling, button is idle and ready
    expect(find.byType(SyncIconButton), findsOneWidget);
  });
}

