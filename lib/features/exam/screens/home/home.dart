import 'package:flutter/material.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFuntions.isDark(context);
    return Scaffold(
      appBar: Appbar(
        title: Text(
          "ExamMate",
          style: Theme.of(
            context,
          ).textTheme.headlineMedium!.apply(color: AppColors.white),
        ),
        leadingIcon: Icons.menu,
        leadingOnPressed: () {},
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.defaultSpace),
            child: IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.refresh,
                size: AppSizes.iconLg,
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
              DropdownButtonFormField(
                decoration: InputDecoration(
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppSizes.defaultSpace / 2,
                    ),
                    borderSide: BorderSide(
                      color: dark ? Colors.grey : AppColors.darkGrey,
                      width: 2,
                    ),
                  ),
                  prefixIcon: Icon(Icons.book),
                ),
                initialValue: "natural",
                items: [
                  DropdownMenuItem(value: "natural", child: Text("Natural")),
                  DropdownMenuItem(value: "social", child: Text("Social")),
                ],
                onChanged: (val) {},
              ),
              const SizedBox(height: AppSizes.spaceBtwItems),
            ],
          ),
        ),
      ),
    );
  }
}
