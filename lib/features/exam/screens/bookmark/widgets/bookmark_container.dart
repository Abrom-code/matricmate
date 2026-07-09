import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/features/exam/controllers/bookmark_controller.dart';
import 'package:matricmate/features/exam/models/bookmark_model.dart';
import 'package:matricmate/features/exam/models/question_model.dart';
import 'package:matricmate/features/exam/screens/bookmark/widgets/bookmark_qn_container.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/formatter/formatter.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:matricmate/utils/helpers/rich_text_parser.dart';

class BookmarkContainer extends GetView<BookmarkController> {
  const BookmarkContainer({super.key, required this.qn});

  final QuestionModel qn;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
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
      return GestureDetector(
        onTap: () => Get.to(BookmarkedQnContainer(qn: qn)),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.defaultSpace / 1.3,
            vertical: AppSizes.defaultSpace / 3,
          ),
          decoration: BoxDecoration(
            color: dark
                ? AppColors.darkerGrey.withValues(alpha: 0.5)
                : AppColors.lightCard,
            borderRadius: BorderRadius.circular(AppSizes.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSizes.sm),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSizes.lg),
                    ),
                    child: Text(
                      controller.subject(qn.subjectId).toUpperCase(),
                      style: const TextStyle(color: AppColors.primary),
                    ),
                  ),

                  IconButton(
                    padding: const EdgeInsets.all(0),
                    onPressed: () => AppHelperFunctions.showAppDialog(
                      context,
                      'Do you want to remove?',
                      'It will be deleted from your bookmark!',
                      () async {
                        Get.back();

                        await controller.removeFromBookmark(qn.id);
                        FocusManager.instance.primaryFocus?.unfocus();
                      },
                    ),
                    icon: const Icon(Iconsax.archive_minus, color: AppColors.primary),
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.spaceBtwItems / 2),

              Text.rich(
                RichTextParser.parse(
                  ' ${qn.questionText.substring(0, isGrater ? 150 : qn.questionText.length)}${isGrater ? ' ...' : ''}',
                  TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 1.6,
                    letterSpacing: 0.1,
                    color: dark ? AppColors.grey : AppColors.darkerGrey,
                  ),
                ),
                textAlign: TextAlign.start,
              ),
              const SizedBox(height: AppSizes.spaceBtwItems / 2),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.date_range, color: AppColors.darkGrey, size: 17),
                      const SizedBox(width: AppSizes.xs),
                      Text(
                        'Saved ${AppFormatter.formatDate(savedAt)}',
                        style: const TextStyle(color: AppColors.darkGrey),
                      ),
                    ],
                  ),
                  const Icon(Icons.keyboard_arrow_right),
                ],
              ),
              const SizedBox(height: AppSizes.spaceBtwItems / 2),
            ],
          ),
        ),
      );
    });
  }
}
