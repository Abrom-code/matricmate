import 'package:flutter/material.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class AppTile extends StatelessWidget {
  const AppTile({
    super.key,
    this.subTitle,
    required this.icon,
    this.iconColor = AppColors.primary,
    required this.title,
    this.onTap,
    this.iconBgColor = Colors.grey,
    this.isBorderVisible = true,
    this.titleColor = Colors.teal,
    this.style,
  });
  final Widget? subTitle;
  final IconData icon;
  final Color? iconColor;
  final String title;
  final VoidCallback? onTap;
  final Color? iconBgColor;
  final bool isBorderVisible;
  final Color? titleColor;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFuntions.isDark(context);
    return Material(
      clipBehavior: Clip.hardEdge,
      borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg),
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          border: isBorderVisible
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.5))
              : null,
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 10),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor!.withValues(alpha: dark ? .2 : .1),

              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor),
          ),
          title: Text(
            title,

            style: style == null
                ? Theme.of(
                    context,
                  ).textTheme.titleSmall!.apply(color: titleColor)
                : style,
          ),
          subtitle: subTitle,

          // visualDensity: VisualDensity(vertical: 2),
          onTap: onTap,
        ),
      ),
    );
  }
}
