import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:matricmate/common/widgets/tiles/chpater_tile.dart';
import 'package:matricmate/features/exam/screens/tests_list/tests_list.dart';
import 'package:matricmate/utils/constants/sizes.dart';

class ChaptersList extends StatelessWidget {
  const ChaptersList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Chapters of selected course
        ChapterTile(
          chapter: "Chapter one",
          chapterTitle: "Chemical reaction",
          onTap: () => Get.to(
            () => const TestListScreen(
              subject: "Naturalmaths",
              chapter: "chapter one",
            ),
          ),
        ),
        const SizedBox(height: AppSizes.spaceBtwItems),

        ChapterTile(
          chapter: "Chapter Two",
          chapterTitle: "Chemical reaction",
          onTap: () {},
        ),
        const SizedBox(height: AppSizes.spaceBtwItems),

        ChapterTile(
          chapter: "Chapter Three",
          chapterTitle: "Chemical reaction",
          onTap: () {},
        ),
        const SizedBox(height: AppSizes.spaceBtwItems),

        ChapterTile(
          chapter: "Chapter Four",
          chapterTitle: "Chemical reaction",
          onTap: () {},
        ),
        const SizedBox(height: AppSizes.spaceBtwItems),

        ChapterTile(
          chapter: "Chapter Five",
          chapterTitle: "Chemical reaction",
          onTap: () {},
        ),
        const SizedBox(height: AppSizes.spaceBtwItems),
        ChapterTile(
          chapter: "Chapter Five",
          chapterTitle: "Chemical reaction",
          onTap: () {},
        ),
        const SizedBox(height: AppSizes.spaceBtwItems),
        ChapterTile(
          chapter: "Chapter Five",
          chapterTitle: "Chemical reaction",
          onTap: () {},
        ),
        const SizedBox(height: AppSizes.spaceBtwItems),
        ChapterTile(
          chapter: "Chapter Five",
          chapterTitle: "Chemical reaction",
          onTap: () {},
        ),
        const SizedBox(height: AppSizes.spaceBtwItems),
      ],
    );
  }
}
