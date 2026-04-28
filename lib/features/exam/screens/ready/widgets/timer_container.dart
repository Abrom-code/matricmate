import 'package:flutter/material.dart';
import 'package:matricmate/common/widgets/shapes/rounded_container.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class TimerContainer extends StatelessWidget {
  const TimerContainer({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFuntions.isDark(context);

    return RoundedContainer(
      radius: AppSizes.md,
      padding: EdgeInsets.fromLTRB(
        AppSizes.defaultSpace,
        AppSizes.defaultSpace / 2,
        AppSizes.defaultSpace,
        AppSizes.defaultSpace,
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 0),
            leading: Icon(
              Icons.watch_later_outlined,
              color: AppColors.primary,
              size: 30,
            ),
            title: Text(
              "Timed Mode",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            trailing: Switch(value: true, onChanged: null),
          ),
          const SizedBox(height: AppSizes.spaceBtwItems / 2),

          Text(
            "When enabled, a 60-minute timer will apply, The test will be completed when time expires.",
            style: TextStyle(
              color: dark ? AppColors.grey : AppColors.darkerGrey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
