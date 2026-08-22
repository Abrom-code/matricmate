import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:matricmate/common/widgets/appbar/modern_appbar.dart';
import 'package:matricmate/features/notifications/controllers/notifications_controller.dart';
import 'package:matricmate/features/notifications/models/notification_model.dart';
import 'package:matricmate/features/notifications/services/notification_navigator.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class NotificationDetailScreen extends StatelessWidget {
  const NotificationDetailScreen({super.key, required this.notification});

  final AppNotification notification;

  String get _paymentStatus => notification.payload['status']?.toString() ?? '';

  bool get _isApproved =>
      notification.type == 'payment' && _paymentStatus == 'active';

  bool get _isRejected =>
      notification.type == 'payment' && _paymentStatus == 'rejected';

  _TypeVisuals get _visuals {
    if (_isApproved) {
      return const _TypeVisuals(
        icon: Icons.verified_rounded,
        color: Color(0xFF10B981),
        typeName: 'Payment Approved',
      );
    }
    if (_isRejected) {
      return const _TypeVisuals(
        icon: Icons.cancel_rounded,
        color: Color(0xFFEF4444),
        typeName: 'Payment Issue',
      );
    }

    switch (notification.type) {
      case 'payment':
        return const _TypeVisuals(
          icon: Icons.account_balance_wallet_rounded,
          color: Color(0xFFF59E0B),
          typeName: 'Payment Update',
        );
      case 'new_content':
        return const _TypeVisuals(
          icon: Icons.menu_book_rounded,
          color: Color(0xFF0284C7),
          typeName: 'New Test Available',
        );
      default:
        return const _TypeVisuals(
          icon: Icons.campaign_rounded,
          color: AppColors.primary,
          typeName: 'Announcement',
        );
    }
  }

  Future<void> _handleAction() async {
    switch (notification.type) {
      case 'payment':
        if (_isApproved) {
          Get.until((route) => route.isFirst);
        } else {
          Get.toNamed(Routes.paymentVerification);
        }
        break;
      case 'new_content':
        await NotificationTestOpener.open(notification.payload);
        break;
      default:
        Get.back();
        break;
    }
  }

  void _deleteAndPop(BuildContext context) {
    NotificationsController.instance.deleteOne(notification.id);
    Get.back();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Notification deleted'),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          action: SnackBarAction(
            label: 'Undo',
            textColor: const Color(0xFF5EEAD4),
            onPressed: () => NotificationsController.instance.undoDeleteOne(),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    final visuals = _visuals;
    final formattedDate =
        DateFormat('EEEE, MMM d, yyyy · hh:mm a').format(notification.createdAt);

    return Scaffold(
      backgroundColor: dark ? AppColors.dark : const Color(0xFFF8FAFC),
      appBar: ModernAppbarWithBuilder(
        title: 'Notification',
        showBackArrow: true,
        subtitleBuilder: (_) => Text(
          visuals.typeName,
          style: const TextStyle(
            color: Color(0xFFD1FAE5),
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Delete notification',
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
            onPressed: () => _deleteAndPop(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Header Card ──────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: dark ? AppColors.darkCard : AppColors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: dark ? 0.25 : 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Icon squircle
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: visuals.color.withValues(
                            alpha: dark ? 0.22 : 0.12,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: visuals.color.withValues(
                              alpha: dark ? 0.35 : 0.25,
                            ),
                            width: 1.2,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            visuals.icon,
                            size: 24,
                            color: visuals.color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Type label & date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              visuals.typeName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: visuals.color,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                fontSize: 12,
                                color: dark
                                    ? AppColors.darkGrey
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (_isApproved)
                        _Badge(
                          label: 'Active',
                          color: const Color(0xFF10B981),
                          dark: dark,
                        )
                      else if (_isRejected)
                        _Badge(
                          label: 'Rejected',
                          color: const Color(0xFFEF4444),
                          dark: dark,
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Divider(
                    height: 1,
                    thickness: 0.8,
                    color: dark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFF1F5F9),
                  ),
                  const SizedBox(height: 14),

                  // Title
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      height: 1.3,
                      color: dark ? AppColors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Rejection Reason Banner (if applicable) ───────────────
            if (_isRejected &&
                notification.payload['rejection_reason'] != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(
                    alpha: dark ? 0.14 : 0.08,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withValues(
                      alpha: dark ? 0.3 : 0.2,
                    ),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 20,
                      color: Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Reason for Rejection',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            notification.payload['rejection_reason'].toString(),
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: dark
                                  ? const Color(0xFFFCA5A5)
                                  : const Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Body Message Card ────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: dark ? AppColors.darkCard : AppColors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: dark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MESSAGE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color:
                          dark ? AppColors.darkGrey : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SelectableText(
                    notification.body,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.6,
                      color: dark
                          ? const Color(0xFFE2E8F0)
                          : const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Action Button ─────────────────────────────────────────
            if (notification.type == 'new_content')
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _handleAction,
                  icon: const Icon(Icons.play_arrow_rounded, size: 22),
                  label: const Text(
                    'Start Test Now',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              )
            else if (notification.type == 'payment')
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _handleAction,
                  icon: Icon(
                    _isApproved
                        ? Icons.bolt_rounded
                        : Icons.account_balance_wallet_rounded,
                    size: 20,
                  ),
                  label: Text(
                    _isApproved
                        ? 'Explore Premium Features'
                        : _isRejected
                            ? 'Submit Payment Again'
                            : 'Check Verification Status',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isApproved
                        ? const Color(0xFF10B981)
                        : _isRejected
                            ? const Color(0xFFEF4444)
                            : const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _TypeVisuals {
  final IconData icon;
  final Color color;
  final String typeName;
  const _TypeVisuals({
    required this.icon,
    required this.color,
    required this.typeName,
  });
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    required this.dark,
  });
  final String label;
  final Color color;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: dark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: dark ? 0.4 : 0.25),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
