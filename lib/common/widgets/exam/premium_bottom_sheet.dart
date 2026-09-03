import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class PremiumBottomSheet extends StatefulWidget {
  const PremiumBottomSheet({super.key});

  @override
  State<PremiumBottomSheet> createState() => _PremiumBottomSheetState();
}

class _PremiumBottomSheetState extends State<PremiumBottomSheet> {
  bool _showAllFeatures = false;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    final screenHeight = MediaQuery.sizeOf(context).height;

    final isPending = UserController.instance.user.value.isPending;
    if (isPending) {
      return _buildPendingVerificationContent(context, dark, screenHeight);
    }

    final bgColor = dark ? AppColors.darkCard : AppColors.white;
    final cardBg = dark ? AppColors.darkSurface : AppColors.lightGrey;
    final borderColor = dark ? AppColors.darkBorder : AppColors.borderPrimary;
    final primaryTextColor = dark ? AppColors.textWhite : AppColors.textPrimary;
    final secondaryTextColor = dark ? AppColors.darkGrey : AppColors.textSecondary;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.92),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          color: bgColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Drag Handle ──────────────────────────────────────────
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: dark ? AppColors.darkBorder : AppColors.grey,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Scrollable Body ──────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  MediaQuery.paddingOf(context).bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Primary Theme Floating Icon ──────────────────
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.workspace_premium_rounded,
                          color: AppColors.white,
                          size: 32,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── Title & Subtitle ────────────────────────────
                    Text(
                      'Unlock Full Access',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: primaryTextColor,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'Everything you need to excel in your matric exams — all subjects, all grades.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: secondaryTextColor,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Main Core Features ──────────────────────────
                    _featureCard(
                      icon: Icons.military_tech_rounded,
                      iconColor: AppColors.amberAccent,
                      title: 'National Entrance Exams',
                      subtitle: '10+ years of past matric papers with full answer keys.',
                      cardBg: cardBg,
                      borderColor: borderColor,
                      primaryText: primaryTextColor,
                      secondaryText: secondaryTextColor,
                    ),

                    _featureCard(
                      icon: Icons.menu_book_rounded,
                      iconColor: AppColors.primary,
                      title: 'Chapter Tests for All Subjects',
                      subtitle: 'Targeted chapter quizzes covering Grades 9, 10, 11 & 12.',
                      cardBg: cardBg,
                      borderColor: borderColor,
                      primaryText: primaryTextColor,
                      secondaryText: secondaryTextColor,
                    ),

                    _featureCard(
                      icon: Icons.wifi_off_rounded,
                      iconColor: AppColors.success,
                      title: '100% Offline Access',
                      subtitle: 'Download and practice tests anytime, anywhere without internet.',
                      cardBg: cardBg,
                      borderColor: borderColor,
                      primaryText: primaryTextColor,
                      secondaryText: secondaryTextColor,
                    ),

                    _featureCard(
                      icon: Icons.translate_rounded,
                      iconColor: AppColors.primary,
                      title: 'Amharic & English Explanations',
                      subtitle: 'Clear, step-by-step reasoning in both languages.',
                      cardBg: cardBg,
                      borderColor: borderColor,
                      primaryText: primaryTextColor,
                      secondaryText: secondaryTextColor,
                    ),

                    // ── Expandable Features with Slide-Down Animation ────
                    AnimatedSize(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeInOutCubic,
                      child: _showAllFeatures
                          ? AnimatedSlide(
                              duration: const Duration(milliseconds: 320),
                              curve: Curves.easeOutCubic,
                              offset: Offset.zero,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 300),
                                opacity: 1.0,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _featureCard(
                                      icon: Icons.speed_rounded,
                                      iconColor: AppColors.secondary,
                                      title: 'Exam Mode vs Practice Mode',
                                      subtitle: 'Take timed real simulations or practice with instant feedback.',
                                      cardBg: cardBg,
                                      borderColor: borderColor,
                                      primaryText: primaryTextColor,
                                      secondaryText: secondaryTextColor,
                                    ),
                                    _featureCard(
                                      icon: Icons.assignment_turned_in_rounded,
                                      iconColor: AppColors.info,
                                      title: 'Standardized Model Exams',
                                      subtitle: 'Full-length model tests designed by expert educators.',
                                      cardBg: cardBg,
                                      borderColor: borderColor,
                                      primaryText: primaryTextColor,
                                      secondaryText: secondaryTextColor,
                                    ),
                                    _featureCard(
                                      icon: Icons.school_rounded,
                                      iconColor: AppColors.primary,
                                      title: 'Grade-Level Assessments',
                                      subtitle: 'Comprehensive yearly assessments for each grade.',
                                      cardBg: cardBg,
                                      borderColor: borderColor,
                                      primaryText: primaryTextColor,
                                      secondaryText: secondaryTextColor,
                                    ),
                                    _featureCard(
                                      icon: Icons.insights_rounded,
                                      iconColor: AppColors.warning,
                                      title: 'Detailed Performance Analytics',
                                      subtitle: 'Track your speed, strengths, and chapters to review.',
                                      cardBg: cardBg,
                                      borderColor: borderColor,
                                      primaryText: primaryTextColor,
                                      secondaryText: secondaryTextColor,
                                    ),
                                    _featureCard(
                                      icon: Icons.bookmark_added_rounded,
                                      iconColor: AppColors.amberAccent,
                                      title: 'Smart Bookmarks & Question Bank',
                                      subtitle: 'Save challenging questions and review them before exams.',
                                      cardBg: cardBg,
                                      borderColor: borderColor,
                                      primaryText: primaryTextColor,
                                      secondaryText: secondaryTextColor,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),

                    // ── See More / See Less Toggle ──────────────────
                    TextButton.icon(
                      onPressed: () {
                        setState(() => _showAllFeatures = !_showAllFeatures);
                      },
                      icon: Icon(
                        _showAllFeatures
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      label: Text(
                        _showAllFeatures
                            ? 'Show less'
                            : 'See all features & test modes (5 more)',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),

                    // ── Primary Action Button ────────────────────────
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => Get.offNamed(Routes.premium),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'View Plans & Upgrade',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: AppColors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _featureCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color cardBg,
    required Color borderColor,
    required Color primaryText,
    required Color secondaryText,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(icon, color: iconColor, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: primaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: secondaryText,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingVerificationContent(
    BuildContext context,
    bool dark,
    double screenHeight,
  ) {
    final bgColor = dark ? AppColors.darkCard : AppColors.white;
    final cardBg = dark ? AppColors.darkSurface : const Color(0xFFF8FAFC);
    final borderColor = dark ? AppColors.darkBorder : const Color(0xFFE2E8F0);
    final primaryTextColor = dark ? AppColors.textWhite : const Color(0xFF0F172A);
    final secondaryTextColor = dark ? AppColors.darkGrey : AppColors.textSecondary;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.85),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          color: bgColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.paddingOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Drag Handle ──────────────────────────────────────────
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: dark ? AppColors.darkBorder : AppColors.grey,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Hourglass Hero Icon ─────────────────────────────────
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFF59E0B),
                    Color(0xFFD97706),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.hourglass_top_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // ── Title & Subtitle ────────────────────────────────────
            Text(
              'Payment Under Review',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: primaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your payment receipt was received and is currently being verified by our team. All Pro features will unlock automatically once approved.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 20),

            // ── Status Steps Card ───────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  _pendingStatusRow(
                    icon: Icons.check_circle_rounded,
                    iconColor: const Color(0xFF10B981),
                    title: 'Receipt Submitted',
                    subtitle: 'Screenshot received successfully',
                    isDone: true,
                    dark: dark,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Divider(
                      height: 1,
                      color: borderColor,
                    ),
                  ),
                  _pendingStatusRow(
                    icon: Icons.pending_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    title: 'Admin Verification',
                    subtitle: 'Our team is reviewing your transaction',
                    isDone: false,
                    dark: dark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // ── Action Buttons ──────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Get.toNamed(Routes.paymentVerification);
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Check Payment Status',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Got it, I’ll wait',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: dark ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pendingStatusRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDone,
    required bool dark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: dark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: dark ? Colors.white60 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
