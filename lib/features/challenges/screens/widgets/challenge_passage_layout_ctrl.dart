import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/exam/models/passage_model.dart';
import 'package:matricmate/utils/constants/colors.dart';

/// Appbar action toggle for challenge questions with an associated passage.
class ChallengePassageLayoutCtrl extends StatelessWidget {
  const ChallengePassageLayoutCtrl({
    super.key,
    required this.passage,
    required this.isHidden,
    required this.onToggle,
  });

  final PassageModel? passage;
  final RxBool isHidden;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hidden = isHidden.value;
      final title = (passage?.title?.trim().isNotEmpty == true)
          ? passage!.title!
          : 'Reading Passage';

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.article_outlined,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 5),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 100),
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Icon(
                  hidden
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 14,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
