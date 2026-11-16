import 'package:flutter/material.dart';
import 'package:matricmate/features/personalization/utils/profile_actions_helper.dart';
import 'package:matricmate/utils/constants/app_images.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class AppDetail extends StatelessWidget {
  const AppDetail({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        // Brand logo & Help Button Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Brand Logo in rounded container
            Container(
              width: 64,
              height: 64,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: dark ? 0.25 : 0.10),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Image.asset(
                AppImages.transparentIcon,
                fit: BoxFit.contain,
              ),
            ),

            // Help Support Pill
            InkWell(
              onTap: ProfileActionsHelper.openTelegramSupport,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: dark
                      ? const Color(0xFF0284C7).withValues(alpha: 0.12)
                      : const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.28),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.send_rounded, size: 10, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'Need help?',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: dark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 26),

        // Title
        Text(
          'Login',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
            color: dark ? AppColors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 6),

        // Subtitle
        Text(
          'Login to access tests, study practice, and exam tracking.',
          style: TextStyle(
            fontSize: 14,
            height: 1.45,
            color: dark ? AppColors.darkGrey : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
