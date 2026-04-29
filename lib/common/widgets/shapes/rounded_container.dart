import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class RoundedContainer extends StatelessWidget {
  const RoundedContainer({
    super.key,
    required this.child,
    this.radius,
    this.padding,
    this.width,
    this.height,
  });

  final Widget child;
  final double? radius;
  final EdgeInsets? padding;
  final double? width, height;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFuntions.isDark(context);

    return Container(
      width: width,
      height: height,
      padding:
          padding ??
          EdgeInsets.symmetric(
            vertical: AppSizes.defaultSpace / 1.5,
            horizontal: AppSizes.sm * 1.5,
          ),
      decoration: BoxDecoration(
        color: dark ? const Color.fromARGB(255, 27, 27, 27) : AppColors.white,
        borderRadius: BorderRadius.circular(radius ?? AppSizes.sm),
      ),
      child: child,
    );
  }
}
