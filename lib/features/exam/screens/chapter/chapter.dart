import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/exam/controllers/chapter_controller.dart';
import 'package:matricmate/features/exam/controllers/grade_selection_controller.dart';
import 'package:matricmate/features/exam/screens/chapter/widgets/all_chapters_button.dart';
import 'package:matricmate/features/exam/screens/chapter/widgets/chapter_progress_hero_card.dart';
import 'package:matricmate/features/exam/screens/chapter/widgets/chapter_tile.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';

class ChapterScreen extends StatefulWidget {
  const ChapterScreen({super.key});

  @override
  State<ChapterScreen> createState() => _ChapterScreenState();
}

class _ChapterScreenState extends State<ChapterScreen> with RouteAware {
  ChapterController get controller => ChapterController.instance;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    appRouteObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  /// Automatically refresh chapter and grade progress when user returns from a test
  @override
  void didPopNext() {
    controller.refreshAllProgress();
  }

  @override
  Widget build(BuildContext context) {
    final title = controller.title;
    final subjectId = controller.subjectId;
    final isCommon = controller.isCommon;
    final dark = AppHelperFunctions.isDark(context);

    // GradeSelectionController is only used for grade-tabbed subjects
    final tabController =
        isCommon ? null : Get.find<GradeSelectionController>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: Appbar.toolbarHeight(context),
        leading: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: IconButton(
            onPressed: Get.back,
            tooltip: 'Back',
            icon: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 18.5,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            Text(
              isCommon ? 'Sections & Tests' : 'Chapter & Grade Tests',
              style: const TextStyle(
                color: Color(0xFFD1FAE5),
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        bottom: isCommon
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.12),
                      width: 1,
                    ),
                  ),
                  child: TabBar(
                    controller: tabController!.tabController,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: AppColors.white.withValues(alpha: 0.22),
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: AppColors.white,
                    unselectedLabelColor:
                        AppColors.white.withValues(alpha: 0.70),
                    labelPadding: EdgeInsets.zero,
                    tabs: tabController.tabs.map((t) {
                      return Tab(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              t['label'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
      ),
      body: isCommon
          ? _buildCommonSectionsView(context, dark, title, subjectId)
          : _buildGradedChaptersView(
              context,
              tabController!,
              dark,
              title,
              subjectId,
            ),
    );
  }

  /// Section list for SAT & English (no grade filtering, directly lists sections)
  Widget _buildCommonSectionsView(
    BuildContext context,
    bool dark,
    String title,
    int subjectId,
  ) {
    return Obx(() {
      if (controller.isChapterLoading.value) {
        return const AppCircularLoading(title: 'Loading sections...');
      }

      final sections = controller.allSections;

      if (sections.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.primary
                        .withValues(alpha: dark ? 0.15 : 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Sections Available',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Sections and tests for this subject will appear once synced.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      final overallSummary = controller.overallSectionsProgress;

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        itemCount: sections.length + 1,
        itemBuilder: (context, index) {
          // Top Hero Progress Card
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ChapterProgressHeroCard(
                summary: overallSummary,
                categoryTitle: '$title Mastery',
                isSection: true,
              ),
            );
          }

          final section = sections[index - 1];
          final hasTests = controller.chapterHasTests[section.id] ?? false;
          final progress = controller.chapterProgress[section.id];

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ChapterTile(
              isSection: true,
              chapter: 'Section ${section.chapterNumber}',
              chapterTitle: section.title,
              chapterNumber: section.chapterNumber,
              progress: progress,
              onTap: () async {
                if (hasTests) {
                  await Get.toNamed(
                    Routes.testLists,
                    arguments: {
                      'subject_id': subjectId,
                      'grade': section.grade,
                      'subject': title,
                      'chapter': section.title,
                      'chapter_id': section.id,
                      'chapter_number': section.chapterNumber,
                      'is_common': true,
                    },
                  );
                  controller.refreshAllProgress();
                } else {
                  ToastHelper.info(
                    'No tests added for this section yet!',
                  );
                }
              },
            ),
          );
        },
      );
    });
  }

  /// Standard graded chapters view with Grade tabs for Physics, Biology, Maths, etc.
  Widget _buildGradedChaptersView(
    BuildContext context,
    GradeSelectionController tabController,
    bool dark,
    String title,
    int subjectId,
  ) {
    return TabBarView(
      controller: tabController.tabController,
      children: List.generate(tabController.tabs.length, (index) {
        final tab = tabController.tabs[index];
        final grade = tab['grade'] as int;

        return Obx(() {
          if (controller.isChapterLoading.value) {
            return const AppCircularLoading(title: 'Loading chapters...');
          }

          final chapters = controller.getChaptersByGrade(grade);

          if (chapters.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.primary
                            .withValues(alpha: dark ? 0.15 : 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Chapters for Grade $grade',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Chapters and tests for this grade will appear once synced.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final combinedGradeProgress = controller.gradeTestProgress[grade];

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            itemCount: chapters.length + 1,
            itemBuilder: (context, chapterIndex) {
              // Top item: All Chapters Practice Test
              if (chapterIndex == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: AllChaptersButton(
                    progress: combinedGradeProgress,
                    onPressed: () async {
                      await Get.toNamed(
                        Routes.gradeTests,
                        arguments: {
                          'subject_id': subjectId,
                          'grade': grade,
                          'subject': title,
                        },
                      );
                      controller.refreshAllProgress();
                    },
                  ),
                );
              }

              final chapter = chapters[chapterIndex - 1];
              final hasTests =
                  controller.chapterHasTests[chapter.id] ?? false;
              final progress = controller.chapterProgress[chapter.id];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ChapterTile(
                  chapter: AppHelperFunctions.getChapterName(
                    chapter.chapterNumber,
                  ),
                  chapterTitle: chapter.title,
                  chapterNumber: chapter.chapterNumber,
                  progress: progress,
                  onTap: () async {
                    if (hasTests) {
                      await Get.toNamed(
                        Routes.testLists,
                        arguments: {
                          'subject_id': subjectId,
                          'grade': grade,
                          'subject': title,
                          'chapter': chapter.title,
                          'chapter_id': chapter.id,
                          'chapter_number': chapter.chapterNumber,
                        },
                      );
                      controller.refreshAllProgress();
                    } else {
                      ToastHelper.info(
                        'No tests added for this chapter yet!',
                      );
                    }
                  },
                ),
              );
            },
          );
        });
      }),
    );
  }
}
