import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/features/personalization/controller/update_profile_controller.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart'; 
import 'package:matricmate/utils/constants/app_strings.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/validators/validators.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UpdateProfileController());
    final userController = UserController.instance;

    return Scaffold(
      appBar: Appbar(
        showBackArrow: true,
        title: const Text(
          "Edit Profile",
          style: TextStyle(color: AppColors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => controller.updateProfile(),
            child: const Text("SAVE", style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
      body: Obx(
        () => Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.defaultSpace),
              child: Form(
                key: controller.updateFormKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: controller.firstName,
                      validator: (val) =>
                          AppValidator.validateEmptyText("First Name", val),
                      onTapOutside: (e) => FocusScope.of(context).unfocus(),
                      decoration: const InputDecoration(
                        labelText: AppTextStrings.firstName,
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: AppSizes.spaceBtwItems),
                    TextFormField(
                      controller: controller.lastName,
                      validator: (val) =>
                          AppValidator.validateEmptyText("Last Name", val),
                      onTapOutside: (e) => FocusScope.of(context).unfocus(),
                      decoration: const InputDecoration(
                        labelText: AppTextStrings.lastName,
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: AppSizes.spaceBtwInputFields),
                    DropdownButtonFormField(
                      initialValue: controller.selectedStream.value.isEmpty
                          ? "natural"
                          : controller.selectedStream.value,
                      items: const [
                        DropdownMenuItem(
                          value: "natural",
                          child: Text("Natural"),
                        ),
                        DropdownMenuItem(
                          value: "social",
                          child: Text("Social"),
                        ),
                      ],
                      onChanged: (stream) =>
                          controller.selectedStream.value = stream!,
                      decoration: const InputDecoration(
                        labelText: "Stream",
                        prefixIcon: Icon(Icons.school),
                      ),
                    ),

                    const SizedBox(height: AppSizes.spaceBtwSections),

                    SizedBox(
                      width: double.infinity,
                      child: Obx(() {
                        if (userController.isDeleting.value) {
                          return const Center(
                            child: Column(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(),
                                ),
                                SizedBox(height: 8),
                                Text("Deleting..."),
                              ],
                            ),
                          );
                        }

                        return TextButton(
                          onPressed: () => userController.showDeleteDialog(),
                          child: const Text(
                            "Delete Account",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),

            if (controller.isUpdating.value)
              const Opacity(
                opacity: 0.5,
                child: ModalBarrier(dismissible: false, color: Colors.black),
              ),
            if (controller.isUpdating.value)
              const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
