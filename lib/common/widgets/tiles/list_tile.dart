import 'package:flutter/material.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class AppListTile extends StatelessWidget {
  const AppListTile({
    super.key,
    required this.icon,
    this.onTap,
    required this.title,
    this.subtitle,
    this.trailing,
    this.isDense,
  });
  final Widget icon;
  final VoidCallback? onTap;
  final String title;
  final String? subtitle;
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: dark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(child: icon),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: dark ? AppColors.white : const Color(0xFF1E293B),
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                ),
              )
            : null,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}
