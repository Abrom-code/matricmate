import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/common/widgets/buttons/drop_down_button.dart';
import 'package:matricmate/common/widgets/layout/grid_layout.dart';
import 'package:matricmate/features/exam/screens/grade/grade_selection_screen.dart';
import 'package:matricmate/features/exam/screens/home/widgets/subject_container.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/image_string.dart';
import 'package:matricmate/utils/constants/sizes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Appbar(
        title: Text(
          "MatricMate",
          style: Theme.of(
            context,
          ).textTheme.headlineMedium!.apply(color: AppColors.white),
        ),
        leadingIcon: Icons.menu,
        leadingOnPressed: () {},
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.defaultSpace / 2),
            child: IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.refresh,
                size: AppSizes.iconMd * 1.2,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.defaultSpace),
          child: Column(
            children: [
              // Select stream dropdown
              AppDropDownField(
                items: [
                  DropdownMenuItem(
                    value: "natural",
                    child: Text(
                      "Natural",
                      style: Theme.of(
                        context,
                      ).textTheme.titleSmall!.apply(color: AppColors.primary),
                    ),
                  ),
                  DropdownMenuItem(
                    value: "social",
                    child: Text(
                      "Social",
                      style: Theme.of(
                        context,
                      ).textTheme.titleSmall!.apply(color: AppColors.primary),
                    ),
                  ),
                ],
                icon: Icons.book,
                onChanged: (val) {},
                initialValue: "natural",
              ),
              const SizedBox(height: AppSizes.spaceBtwSections),

              GridLayout(
                itemCount: 5,
                itemBuilder: (_, index) => SubjectContainer(
                  title: "Chemistry",
                  image: AppImages.chemistryMainImage,
                  onTap: () => Get.to(
                    () => const GradeSelectionScreen(title: "Chemistry"),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
