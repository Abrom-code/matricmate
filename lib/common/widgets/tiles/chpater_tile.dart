import 'package:flutter/material.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';

class ChapterTile extends StatelessWidget {
  const ChapterTile({
    super.key,
    required this.chapter,
    required this.chapterTitle,
    this.icon = Icons.receipt,
    required this.onTap,
    this.hasSubTitle = true,
    this.chapterNumber,
  });
  final String chapter, chapterTitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool hasSubTitle;
  final int? chapterNumber;

  @override
  Widget build(BuildContext context) {
    return Material(
      clipBehavior: Clip.hardEdge,
      borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg),
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg),
        ),
        child: ListTile(
          minVerticalPadding: 10,
          leading: Icon(icon, color: AppColors.primary),
          title: Text(
            chapter.toUpperCase(),
            style: Theme.of(
              context,
            ).textTheme.titleSmall!.apply(color: AppColors.primary),
          ),
          subtitle: Text(chapterTitle),
          visualDensity: VisualDensity(vertical: 2),

          onTap: onTap,
        ),
      ),
    );
  }
}
