import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/bindings/test_binding.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/common/widgets/tiles/chpater_tile.dart';
import 'package:matricmate/features/exam/controllers/chapter_controller.dart';
import 'package:matricmate/features/exam/controllers/grade_selection_controller.dart';
import 'package:matricmate/features/exam/screens/chapter/widgets/all_chapters_button.dart';
import 'package:matricmate/features/exam/screens/chapter/widgets/all_grade_exams_tile.dart';
import 'package:matricmate/features/exam/screens/tests_list/tests_list.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class ChapterScreen extends GetView<ChapterController> {
  const ChapterScreen({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
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
                  return const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSizes.defaultSpace,
                    ),
                    child: AllGradeExamsTile(),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Obx(() {
                    final chapters = controller.getChaptersByGrade(grade);
                    if (controller.isChapterLoading.value) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (chapters.isEmpty) {
                      return const Center(child: Text("No Chapters Found"));
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AllChaptersButton(
                          onPressed: () => Get.to(
                            () => TestListScreen(
                              subject: title,
                              chapter: "Chapter One",
                            ),
                          ),
                        ),
                        const Divider(height: AppSizes.spaceBtwSections),
                        ...chapters.map((chapter) {
                          final hasTests =
                              controller.chapterHasTests[chapter.id] ?? false;
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
                                  Get.to(
                                    () => TestListScreen(
                                      subject: title,
                                      grade: chapter.grade,
                                      chapter: chapter.title,
                                      chapterId: chapter.id,
                                    ),
                                    binding: TestBinding(),
                                    arguments: chapter.subjectId,
                                  );
                                } else {
                                  AppHelperFuntions.showAlert(
                                    "Alert",
                                    "No Tests",
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
