import 'package:flutter/material.dart';
import 'package:matricmate/utils/constants/colors.dart';

class AllChaptersButton extends StatelessWidget {
  const AllChaptersButton({super.key, required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,

      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.primary,
          side: BorderSide.none,
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "From All Chapters",
              style: Theme.of(context).textTheme.titleMedium!.apply(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.white, size: 30),
          ],
        ),
      ),
    );
  }
}
