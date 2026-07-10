import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/exam/controllers/question_controller.dart';
import 'package:matricmate/features/exam/screens/question/widgets/question_navigator_tile.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

/// Bottom sheet that shows all questions as a grid for quick navigation.
class QuestionNavigatorSheet extends StatelessWidget {
  const QuestionNavigatorSheet({super.key, required this.controller});

  final QuestionController controller;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    final sheetBg = dark ? AppColors.darkCard : AppColors.white;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.90,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSizes.borderRadiusLg * 2),
          ),
        ),
        child: Column(
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.darkGrey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.defaultSpace,
                vertical: AppSizes.xs,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Questions',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium!
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      const NavigatorLegendDot(
                          color: AppColors.success, label: 'Done'),
                      const SizedBox(width: AppSizes.sm),
                      const NavigatorLegendDot(
                          color: Colors.amber, label: 'Skipped'),
                      const SizedBox(width: AppSizes.sm),
                      NavigatorLegendDot(
                        color: AppColors.darkGrey.withValues(alpha: 0.35),
                        label: 'Not done',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Obx(() {
                final questions = controller.testQuestions;
                final hasSections = questions.any(
                  (q) =>
                      q.sectionTitle != null &&
                      q.sectionTitle!.trim().isNotEmpty,
                );

                if (!hasSections) {
                  return GridView.builder(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.all(AppSizes.defaultSpace),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      crossAxisSpacing: AppSizes.xs,
                      mainAxisSpacing: AppSizes.xs,
                    ),
                    itemCount: questions.length,
                    itemBuilder: (_, i) => QuestionNavigatorTile(
                      index: i,
                      controller: controller,
                      dark: dark,
                    ),
                  );
                }

                // Build section → indices map
                final sections = <String, List<int>>{};
                for (int i = 0; i < questions.length; i++) {
                  final label =
                      (questions[i].sectionTitle?.trim().isNotEmpty == true)
                          ? questions[i].sectionTitle!.trim()
                          : '—';
                  sections.putIfAbsent(label, () => []).add(i);
                }

                return CustomScrollView(
                  controller: scrollCtrl,
                  slivers: [
                    for (final entry in sections.entries) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSizes.defaultSpace,
                            AppSizes.spaceBtwItems,
                            AppSizes.defaultSpace,
                            AppSizes.sm,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall!
                                      .copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                              Text(
                                '${entry.value.length} questions',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall!
                                    .copyWith(color: AppColors.darkGrey),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.defaultSpace,
                        ),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 6,
                            crossAxisSpacing: AppSizes.xs,
                            mainAxisSpacing: AppSizes.xs,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (_, j) => QuestionNavigatorTile(
                              index: entry.value[j],
                              controller: controller,
                              dark: dark,
                            ),
                            childCount: entry.value.length,
                          ),
                        ),
                      ),
                    ],
                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppSizes.defaultSpace),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
