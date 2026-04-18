import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/features/personalization/controller/update_profile_controller.dart';
import 'package:matricmate/utils/constants/app_strings.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/validators/validators.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UpdateProfileController());
    return Scaffold(
      appBar: Appbar(
        showBackArrow: true,
        title: Text("Edit Profile", style: TextStyle(color: AppColors.white)),
        actions: [
          TextButton(
            onPressed: () => controller.updateProfile(),
            child: Text("SAVE", style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
      body: Obx(
        () => Stack(
          children: [
            if (controller.isUpdating.value)
              Center(child: CircularProgressIndicator()),
            SingleChildScrollView(
              padding: EdgeInsets.all(AppSizes.defaultSpace),
              child: Form(
                key: controller.updateFormKey,
                child: Column(
                  children: [
                    TextFormField(
                      validator: (val) =>
                          AppValidator.validateEmptyText("First Name", val),
                      onTapOutside: (e) => FocusScope.of(context).unfocus(),
                      controller: controller.firstName,
                      expands: false,
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
                      expands: false,
                      decoration: const InputDecoration(
                        labelText: AppTextStrings.lastName,
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),

                    const SizedBox(height: AppSizes.spaceBtwInputFields),

                    const SizedBox(height: AppSizes.spaceBtwInputFields),

                    // stream
                    DropdownButtonFormField(
                      items: [
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
                      initialValue: controller.selectedStream.value.isEmpty
                          ? "natural"
                          : controller.selectedStream.value,
                    ),

                    const SizedBox(height: AppSizes.spaceBtwSections),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
