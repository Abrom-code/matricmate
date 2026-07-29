import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matricmate/features/exam/models/subject_model.dart';
import 'package:matricmate/features/exam/screens/entrance/widgets/entrance_action_widget.dart';

void main() {
  final subject = SubjectModel(id: 7, name: 'Physics', isNatural: true);

  Future<void> pumpAction(
    WidgetTester tester, {
    required bool isDownloading,
    required bool isDownloaded,
    required bool canDownload,
    required bool noContent,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EntranceActionWidget(
            subject: subject,
            dark: false,
            isDownloading: isDownloading,
            isDownloaded: isDownloaded,
            canDownload: canDownload,
            noContent: noContent,
          ),
        ),
      ),
    );
  }

  testWidgets(
    'shows no trailing action while an entrance exam is downloading',
    (tester) async {
      await pumpAction(
        tester,
        isDownloading: true,
        isDownloaded: false,
        canDownload: true,
        noContent: false,
      );

      expect(find.byType(SizedBox), findsWidgets);
      expect(find.text('Download'), findsNothing);
    },
  );

  testWidgets('shows a completion indicator after an entrance exam download', (
    tester,
  ) async {
    await pumpAction(
      tester,
      isDownloading: false,
      isDownloaded: true,
      canDownload: true,
      noContent: false,
    );

    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('Download'), findsNothing);
  });

  testWidgets(
    'disables the download action when no entrance content is available',
    (tester) async {
      await pumpAction(
        tester,
        isDownloading: false,
        isDownloaded: false,
        canDownload: true,
        noContent: true,
      );

      expect(find.text('Download'), findsOneWidget);
      expect(find.byType(GestureDetector), findsNothing);
    },
  );

  testWidgets('disables the download action when the user is not eligible', (
    tester,
  ) async {
    await pumpAction(
      tester,
      isDownloading: false,
      isDownloaded: false,
      canDownload: false,
      noContent: false,
    );

    expect(find.text('Download'), findsOneWidget);
    expect(find.byType(GestureDetector), findsNothing);
  });
}
