import 'package:flutter/material.dart';
import 'package:matricmate/common/widgets/helpers/badges.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

/// Circular badge shown at the top of the result screen.
class ResultBadgeCircle extends StatelessWidget {
  const ResultBadgeCircle({super.key, required this.ratio});

  final double ratio;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    final examBadge = ExamBadgeHelper.getBadge(ratio);

    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(150),
        color: dark ? AppColors.darkCard : AppColors.lightCard,
      ),
      child: Stack(
        children: [
          Positioned(
            top: 10,
            right: 30,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(70),
                color: Colors.yellow,
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 10,
            child: Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.greenAccent,
              ),
            ),
          ),
          Center(
            child: Icon(examBadge.icon, color: examBadge.color, size: 100),
          ),
        ],
      ),
    );
  }
}
