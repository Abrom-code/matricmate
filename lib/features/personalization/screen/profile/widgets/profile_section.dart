import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart';
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
            child: const Image(
              image: AssetImage(AppImages.unknownUser),
              fit: BoxFit.fill,
            ),
          ),
        ),
        const SizedBox(height: AppSizes.spaceBtwItems),

        Obx(() {
          final controller = UserController.instance;

          if (controller.userFetching.value) {
            return const CircularProgressIndicator();
          }

          final user = controller.user.value;

          if (user.id.isEmpty) {
            return const Text(
              'No user data',
              style: TextStyle(color: Colors.grey),
            );
          }

          return Column(
            children: [
              Text(
                '${UserController.instance.user.value.firstName} ${UserController.instance.user.value.lastName}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                UserController.instance.user.value.email,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          );
        }),
      ],
    );
  }
}
