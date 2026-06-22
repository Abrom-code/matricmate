import 'package:flutter/material.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class AppListTile extends StatelessWidget {
  const AppListTile({
    super.key,
    required this.icon,
    this.onTap,
    required this.title,
    this.trailing,
    this.isDense,
  });
  final Widget icon;
  final VoidCallback? onTap;
  final String title;
  final Widget? trailing;
  final bool? isDense;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.hardEdge,
      child: ListTile(
        dense: isDense,
        leading: Container(
          padding: const EdgeInsets.all(AppSizes.xs),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: icon,
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
            color: dark ? AppColors.grey : AppColors.darkerGrey,
          ),
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}
