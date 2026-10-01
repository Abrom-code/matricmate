import 'package:flutter/material.dart';
import 'package:matricmate/common/widgets/appbar/modern_appbar.dart';
import 'package:matricmate/features/personalization/screens/others/widgets/pilot_exam_coming_soon.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class PilotExamDetailScreen extends StatelessWidget {
  const PilotExamDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Scaffold(
      backgroundColor: dark ? AppColors.dark : const Color(0xFFF8FAFC),
      appBar: const ModernAppbar(
        title: 'Pilot Exam Simulator',
        subtitle: 'National Exam Simulation',
        showBackArrow: true,
      ),
      body: const PilotExamComingSoon(),
    );
  }
}
