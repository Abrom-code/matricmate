import 'package:flutter/material.dart';
import 'package:matricmate/utils/constants/app_strings.dart';
import 'package:matricmate/utils/constants/image_string.dart';
import 'package:matricmate/utils/constants/sizes.dart';

class AppDetail extends StatelessWidget {
  const AppDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSizes.spaceBtwSections * 2),
        const SizedBox(
          width: 70,
          child: ClipRRect(
            clipBehavior: Clip.hardEdge,
            child: Image(image: AssetImage(AppImages.transparentLogo)),
          ),
        ),

        const SizedBox(height: AppSizes.spaceBtwItems),

        Text(
          AppTextStrings.loginTitle,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSizes.spaceBtwItems / 2),
        Text(
          AppTextStrings.loginSubTitle,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
