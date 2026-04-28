import 'package:flutter/widgets.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class InstructionBox extends StatelessWidget {
  const InstructionBox({super.key, required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFuntions.isDark(context);
    return Container(
      padding: EdgeInsets.all(AppSizes.defaultSpace / 1.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.md),
        color: dark
            ? AppColors.darkerGrey.withValues(alpha: 0.5)
            : Color(0xFFe7eae7),
      ),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: AppSizes.defaultSpace),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
