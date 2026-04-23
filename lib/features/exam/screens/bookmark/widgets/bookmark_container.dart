import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/exam/controllers/bookmark_controller.dart';
import 'package:matricmate/features/exam/models/bookmark_model.dart';
import 'package:matricmate/features/exam/models/question_model.dart';
import 'package:matricmate/features/exam/screens/bookmark/widgets/bookmark_qn_container.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/formatter/formatter.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class BookmarkContainer extends GetView<BookmarkController> {
  const BookmarkContainer({super.key, required this.qn});

  final QuestionModel qn;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFuntions.isDark(context);
    final isGrater = qn.questionText.length > 150;
    final bookmark = controller.bookmarkedQuestionIds.firstWhere(
      (b) => b.questionId == qn.id,
      orElse: () => BookmarkModel(
        userId: UserController.instance.user.value.id,
        questionId: qn.id,
        savedAt: 0,
      ),
    );

    final savedAt = bookmark.savedAt;
    return Obx(() {
      return Container(
        padding: EdgeInsets.all(AppSizes.defaultSpace / 1.3),
        decoration: BoxDecoration(
          color: dark
              ? AppColors.darkerGrey.withValues(alpha: 0.5)
              : Color(0xFFe7eae7),
          borderRadius: BorderRadius.circular(AppSizes.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(AppSizes.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.lg),
                  ),
                  child: Text(
                    controller.subject(qn.subjectId).toUpperCase(),
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),

                IconButton(
                  padding: EdgeInsets.all(0),
                  onPressed: () => AppHelperFuntions.showAppDialog(
                    context,
                    "Do you want to remove?",
                    "It will be deleted from your bookmark!",
                    () {
                      controller.removeFromBookmark(qn.id);
                      Navigator.pop(context);

                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                  ),
                  icon: Icon(Icons.bookmark, color: AppColors.primary),
                ),
              ],
            ),

            const SizedBox(height: AppSizes.spaceBtwItems / 2),

            Text(
              " ${qn.questionText.substring(0, isGrater ? 150 : qn.questionText.length)} ${isGrater ? '...' : ''}",
              textAlign: TextAlign.justify,

              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                fontSize: 17,
                color: dark ? AppColors.grey : AppColors.darkerGrey,
              ),
            ),
            const SizedBox(height: AppSizes.spaceBtwItems),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.date_range, color: Colors.grey, size: 17),
                    const SizedBox(width: AppSizes.xs),
                    Text(
                      'Saved ${AppFormatter.formatDate(savedAt)}',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                SizedBox(
                  width: 100,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Get.to(BookmarkedQnContainer(qn: qn)),
                    child: Center(child: Text("View")),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}
