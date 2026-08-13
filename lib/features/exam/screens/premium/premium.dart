import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/data/services/payment_config_service.dart';
import 'package:matricmate/features/exam/controllers/premium_controller.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/payment_tile.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = PremiumController.instance;
    final cfg = PaymentConfigService.instance;

    return Scaffold(
      appBar: Appbar(
        showBackArrow: true,
        title: Text(
          'Upgrade Premium',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall!.apply(color: AppColors.white),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, _) {
          final isLandscape =
              MediaQuery.orientationOf(context) == Orientation.landscape;

          final content = SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Obx(() {
                final price    = cfg.subscriptionPrice.value;
                final methods  = cfg.methods.toList();
                final selected = controller.selectedPayment.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Total Amount Card ──────────────────────────
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Amount Due',
                            style: TextStyle(color: AppColors.white),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$price ETB',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── All payment methods from DB ─────────────────
                    if (methods.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: AppCircularLoading(
                          title: 'Loading payment methods...',
                        ),
                      )
                    else
                      ...methods.map((method) {
                        return paymentTile(
                          title: method.label,
                          subtitle: method.account.isNotEmpty
                              ? method.account.length < 15
                                  ? method.account
                                  : '${method.account.substring(0, 12)}...'
                              : '',
                          icon: method.icon,
                          isFeatured: method.isFeatured,
                          selected: selected == method,
                          context: context,
                          onTap: () =>
                              controller.selectedPayment.value = method,
                        );
                      }),
                  ],
                );
              }),
            ),
          );

          if (!isLandscape) return content;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: content,
            ),
          );
        },
      ),
      bottomNavigationBar: Obx(() {
        final isPending  = UserController.instance.user.value.isPending;
        final hasMethod  = controller.selectedPayment.value != null;

        return Container(
          padding: const EdgeInsets.all(AppSizes.md),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: (!isPending && !hasMethod)
                  ? null
                  : isPending
                      ? () => Get.toNamed(Routes.paymentVerification)
                      : () {
                          if (controller.exceededUploadLimit) {
                            Get.toNamed(Routes.contactAdmin);
                          } else {
                            Get.toNamed(
                              Routes.payment,
                              arguments: controller.selectedPayment.value,
                            );
                          }
                        },
              child: Text(
                isPending ? 'Check Status' : 'Continue to Payment',
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        );
      }),
    );
  }
}
