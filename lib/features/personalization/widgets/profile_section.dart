import 'package:flutter/material.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/image_string.dart';
import 'package:matricmate/utils/constants/sizes.dart';

class ProfileSection extends StatelessWidget {
  const ProfileSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary),
            borderRadius: BorderRadius.circular(100),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: Image(
              image: AssetImage(AppImages.unknownUser),
              fit: BoxFit.fill,
            ),
          ),
        ),
        const SizedBox(height: AppSizes.spaceBtwItems),

        Text("User Name", style: Theme.of(context).textTheme.headlineSmall),
        Text("Natural Science", style: TextStyle(color: Colors.grey)),
      ],
    );
  }
}
