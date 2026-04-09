import 'package:flutter/material.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class SubjectContainer extends StatelessWidget {
  const SubjectContainer({
    super.key,
    required this.title,
    required this.image,
    required this.onTap,
    required this.isDownloaded,
  });
  final String title, image;
  final VoidCallback onTap;
  final bool isDownloaded;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFuntions.isDark(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(AppSizes.sm),
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.defaultSpace),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.8)),
        ),
        child: Column(
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const Divider(),
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: dark
                          ? const Color.fromARGB(255, 43, 43, 43)
                          : Colors.transparent,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(AppSizes.defaultSpace),
                        bottomRight: Radius.circular(AppSizes.defaultSpace),
                      ),
                    ),

                    child: ClipRRect(
                      clipBehavior: Clip.hardEdge,
                      child: Image.asset(
                        image,
                        fit: BoxFit.contain,
                        width: double.infinity,
                      ),
                    ),
                  ),

                  if (!isDownloaded)
                    Center(
                      child: IconButton(
                        onPressed: () {},
                        icon: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            color: AppColors.darkGrey.withValues(alpha: 0.7),
                          ),
                          child: Icon(
                            Icons.cloud_download_rounded,
                            color: AppColors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
