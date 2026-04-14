import 'package:flutter/material.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class BookmarkContainer extends StatelessWidget {
  const BookmarkContainer({super.key, required this.qnText});

  final String qnText;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFuntions.isDark(context);
    return Container(
      padding: EdgeInsets.all(AppSizes.defaultSpace / 1.3),
      decoration: BoxDecoration(
        color: dark
            ? AppColors.darkerGrey.withValues(alpha: 0.5)
            : Color(0xFFe7eae7),
        borderRadius: BorderRadius.circular(AppSizes.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(AppSizes.sm),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.lg),
                ),
                child: Text(
                  "Biology",
                  style: TextStyle(color: AppColors.primary),
                ),
              ),

              IconButton(
                padding: EdgeInsets.all(0),
                onPressed: () {},
                icon: Icon(Icons.bookmark, color: AppColors.primary),
              ),
            ],
          ),

          const SizedBox(height: AppSizes.spaceBtwItems / 2),

          Text(
            " ${qnText.substring(0, qnText.length > 150 ? 150 : qnText.length)}...",
            textAlign: TextAlign.justify,

            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
              fontSize: 17,
              color: dark ? AppColors.grey : AppColors.darkerGrey,
            ),
          ),
          const SizedBox(height: AppSizes.spaceBtwItems),
          Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.date_range, color: Colors.grey, size: 17),
                  const SizedBox(width: AppSizes.xs),
                  Text(
                    "Saved Oct 24, 2026",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              SizedBox(
                width: 100,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {},
                  child: Center(child: Text("View")),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
