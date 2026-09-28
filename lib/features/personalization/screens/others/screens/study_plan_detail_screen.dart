import 'package:flutter/material.dart';
import 'package:matricmate/common/widgets/appbar/modern_appbar.dart';
import 'package:matricmate/features/personalization/screens/others/widgets/study_plan_coming_soon.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class StudyPlanDetailScreen extends StatelessWidget {
  const StudyPlanDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Scaffold(
      backgroundColor: dark ? AppColors.dark : const Color(0xFFF8FAFC),
      appBar: const ModernAppbar(
        title: 'Smart Study Plan',
        subtitle: 'AI Adaptive Revision Roadmap',
        showBackArrow: true,
      ),
      body: const StudyPlanComingSoon(),
    );
  }
}
