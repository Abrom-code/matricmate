import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/features/exam/controllers/grade_selection_controller.dart';
import 'package:matricmate/features/exam/screens/grade/widgets/all_grade_exams_tile.dart';
import 'package:matricmate/features/exam/screens/grade/widgets/chapters_list.dart';
import 'package:matricmate/features/exam/screens/question/question.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';

class GradeSelectionScreen extends StatelessWidget {
  const GradeSelectionScreen({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(GradeSelectionController());

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
              padding: EdgeInsets.only(left: 0),
              labelPadding: EdgeInsets.symmetric(horizontal: 10),
              controller: controller.tabController,
              indicatorPadding: const EdgeInsets.all(4),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              tabs: controller.tabs,
            ),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: TabBarView(
              controller: controller.tabController,
              children: controller.tabs.map((tab) {
                if (tab == controller.tabs[4]) {
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSizes.defaultSpace,
                    ),
                    child: AllGradeExamsTile(),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 60,

                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          side: BorderSide.none,
                        ),
                        onPressed: () => Get.to(() => QuestionScreen()),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "From All Chapters",
                              style: Theme.of(context).textTheme.titleMedium!
                                  .apply(
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: AppColors.white,
                              size: 30,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Divider(height: AppSizes.spaceBtwSections),

                    ChaptersList(),

                    const SizedBox(height: AppSizes.spaceBtwSections),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
