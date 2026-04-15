import 'package:flutter/material.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';

class ProfileTile extends StatelessWidget {
  const ProfileTile({
    super.key,
    required this.icon,
    this.onTap,
    required this.title,
    this.trailing,
  });
  final Widget icon;
  final VoidCallback? onTap;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.hardEdge,
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(AppSizes.xs),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: icon,
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}
