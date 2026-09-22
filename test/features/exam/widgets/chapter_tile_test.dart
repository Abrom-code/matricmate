import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matricmate/features/exam/models/chapter_progress_model.dart';
import 'package:matricmate/features/exam/screens/chapter/widgets/all_chapters_button.dart';
import 'package:matricmate/features/exam/screens/chapter/widgets/chapter_tile.dart';

void main() {
  group('ChapterTile Widget Tests', () {
    testWidgets('renders unlocked chapter with standard chevron and no PRO badge', (
      tester,
    ) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChapterTile(
              chapter: 'Chapter 1',
              chapterTitle: 'Introduction to Physics',
              chapterNumber: 1,
              isLocked: false,
              progress: ChapterProgressModel(
                chapterId: 1,
                grade: 12,
                totalTests: 3,
                freeTests: 1,
                completedTests: 0,
              ),
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Introduction to Physics'), findsOneWidget);
      expect(find.text('PRO'), findsNothing);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);

      await tester.tap(find.text('Introduction to Physics'));
      expect(tapped, isTrue);
    });

    testWidgets('renders locked chapter with lock icon in squircle and standard right chevron without PRO tag', (
      tester,
    ) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChapterTile(
              chapter: 'Chapter 2',
              chapterTitle: 'Kinematics in One Dimension',
              chapterNumber: 2,
              isLocked: true,
              progress: ChapterProgressModel(
                chapterId: 2,
                grade: 12,
                totalTests: 4,
                freeTests: 0,
                completedTests: 0,
              ),
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Kinematics in One Dimension'), findsOneWidget);
      // No PRO badge
      expect(find.text('PRO'), findsNothing);
      // Lock icon is present in the squircle
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
      // Standard chevron is present on the right
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);

      await tester.tap(find.text('Kinematics in One Dimension'));
      expect(tapped, isTrue);
    });
  });

  group('AllChaptersButton Widget Tests', () {
    testWidgets('renders locked AllChaptersButton with lock icon in squircle and standard chevron without PRO tag', (
      tester,
    ) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AllChaptersButton(
              isLocked: true,
              progress: ChapterProgressModel(
                chapterId: 0,
                grade: 12,
                totalTests: 5,
                freeTests: 0,
                completedTests: 0,
              ),
              onPressed: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Practice All Chapters'), findsOneWidget);
      expect(find.text('PRO'), findsNothing);
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);

      await tester.tap(find.text('Practice All Chapters'));
      expect(tapped, isTrue);
    });

    testWidgets('renders unlocked AllChaptersButton with layers icon and chevron', (
      tester,
    ) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AllChaptersButton(
              isLocked: false,
              progress: ChapterProgressModel(
                chapterId: 0,
                grade: 12,
                totalTests: 5,
                freeTests: 2,
                completedTests: 0,
              ),
              onPressed: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Practice All Chapters'), findsOneWidget);
      expect(find.text('PRO'), findsNothing);
      expect(find.byIcon(Icons.layers_rounded), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);

      await tester.tap(find.text('Practice All Chapters'));
      expect(tapped, isTrue);
    });
  });
}
