import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/common/widgets/tiles/chpater_tile.dart';
import 'package:matricmate/features/exam/controllers/chapter_controller.dart';
import 'package:matricmate/features/exam/controllers/grade_selection_controller.dart';
import 'package:matricmate/features/exam/screens/chapter/widgets/all_chapters_button.dart';
import 'package:matricmate/features/exam/screens/chapter/widgets/all_grade_exams_tile.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';

class ChapterScreen extends GetView<ChapterController> {
  const ChapterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final title = controller.title;
    final subjectId = controller.subjectId;
    final tabController = Get.find<GradeSelectionController>();
    return Scaffold(
      appBar: Appbar(
        showBackArrow: true,
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium!.apply(color: AppColors.white),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.defaultSpace,
            ),
            child: TabBar(
              tabAlignment: TabAlignment.start,
              isScrollable: true,
              labelPadding: const EdgeInsets.symmetric(horizontal: 10),
              controller: tabController.tabController,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              tabs: tabController.tabs
                  .map((t) => Tab(text: t["label"]))
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: TabBarView(
              controller: tabController.tabController,
              children: List.generate(tabController.tabs.length, (index) {
                final tab = tabController.tabs[index];
                final grade = tab["grade"];

                if (grade == null) {
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSizes.defaultSpace,
                    ),
                    child: AllGradeExamsTile(subjectId: subjectId),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Obx(() {
                    if (controller.isChapterLoading.value) {
                      return AppCircularLoading(title: 'Loading');
                    }

                    final chapters = controller.getChaptersByGrade(grade);

                    if (chapters.isEmpty) {
                      return const Center(child: Text("No Chapters Found"));
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AllChaptersButton(
                          onPressed: () => Get.toNamed(
                            Routes.gradeTests,
                            arguments: {
                              'subject_id': subjectId,
                              'grade': grade,
                              'subject': title,
                            },
                          ),
                        ),
                        const Divider(height: AppSizes.spaceBtwSections),
                        ...chapters.map((chapter) {
                          final hasTests =
                              controller.chapterHasTests[chapter.id];

                          if (hasTests == null) {
                            return const SizedBox();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSizes.spaceBtwItems,
                            ),
                            child: ChapterTile(
                              chapter: AppHelperFuntions.getChapterName(
                                chapter.chapterNumber,
                              ),
                              chapterTitle: chapter.title,
                              onTap: () {
                                if (hasTests) {
                                  Get.toNamed(
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
                                } else {
                                  ToastHelper.info(
                                    "No Tests",
                                    "Tests will be added soon!",
                                  );
                                }
                              },
                            ),
                          );
                        }),
                        const SizedBox(height: AppSizes.spaceBtwSections),
                      ],
                    );
                  }),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
