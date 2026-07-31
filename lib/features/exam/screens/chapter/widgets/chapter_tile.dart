import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/tiles/tile.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class ChapterTile extends StatelessWidget {
  const ChapterTile({
    super.key,
    required this.chapter,
    required this.chapterTitle,
    this.icon = Iconsax.book_copy,
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
    final dark = AppHelperFunctions.isDark(context);
    return AppTile(
      icon: icon,
      title: chapter,
      iconBgColor: AppColors.primary,
      subTitle: Text(
        chapterTitle,
        style: TextStyle(
          fontSize: 14,
          color: !dark ? AppColors.darkerGrey : AppColors.grey,
        ),
      ),
      onTap: onTap,
    );
  }
}
