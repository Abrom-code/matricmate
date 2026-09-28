import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class StudyPlanComingSoon extends StatefulWidget {
  const StudyPlanComingSoon({super.key});

  @override
  State<StudyPlanComingSoon> createState() => _StudyPlanComingSoonState();
}

class _StudyPlanComingSoonState extends State<StudyPlanComingSoon> {
  bool _isNotified = false;

  void _toggleNotification() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isNotified = !_isNotified;
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _isNotified ? Icons.check_circle_rounded : Icons.info_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _isNotified
                    ? "You're enrolled for early access to Smart Study Plan!"
                    : 'Alert preference removed.',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: _isNotified ? const Color(0xFF2563EB) : AppColors.darkSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon Avatar with Glow
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Iconsax.calendar_tick_copy,
                  size: 42,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 22),

            // Coming Soon Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: dark ? 0.22 : 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 13,
                    color: Color(0xFF2563EB),
                  ),
                  SizedBox(width: 5),
                  Text(
                    'COMING SOON',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2563EB),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Title
            Text(
              'Smart Study Plan',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: dark ? Colors.white : AppColors.textPrimary,
                letterSpacing: -0.4,
              ),
            ),

            const SizedBox(height: 8),

            // Short Description
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                'Personalized daily study roadmap tailored to your target matric score and learning pace. Stay tuned for the upcoming release.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Waitlist Notification Action Button
            SizedBox(
              width: 230,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: _toggleNotification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isNotified
                      ? (dark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFEFF6FF))
                      : const Color(0xFF2563EB),
                  foregroundColor: _isNotified
                      ? const Color(0xFF2563EB)
                      : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: _isNotified
                        ? const BorderSide(color: Color(0xFF2563EB), width: 1.2)
                        : BorderSide.none,
                  ),
                ),
                icon: Icon(
                  _isNotified ? Icons.check_circle_rounded : Iconsax.notification_bing_copy,
                  size: 18,
                ),
                label: Text(
                  _isNotified ? 'Waitlist Joined' : 'Notify Me When Ready',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
