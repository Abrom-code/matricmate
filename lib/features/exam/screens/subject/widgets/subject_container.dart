import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/exam/controllers/subjects_controller.dart';
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
    required this.onPressed,
  });
  final String title, image;
  final VoidCallback onTap, onPressed;
  final bool isDownloaded;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.sm),
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.defaultSpace),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.8)),
        ),
        child: Obx(() {
          final isDownloading =
              SubjectsController.instance.downloadingMap[title] ?? false;
          return Stack(
            children: [
              if (isDownloaded)
                const Positioned(
                  top: 0,
                  right: 0,
                  child: Icon(
                    Icons.check,
                    color: AppColors.primary,
                    size: AppSizes.iconSm,
                  ),
                ),
              Column(
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const Divider(),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: dark
                                ? AppColors.darkCard.withValues(alpha: 0.5)
                                : Colors.transparent,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(
                                AppSizes.defaultSpace,
                              ),
                              bottomRight: Radius.circular(
                                AppSizes.defaultSpace,
                              ),
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
                              onPressed: onPressed,
                              icon: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(50),
                                  color: AppColors.darkGrey.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                                child: isDownloading
                                    ? const CircularProgressIndicator()
                                    : const Icon(
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
            ],
          );
        }),
      ),
    );
  }
}
