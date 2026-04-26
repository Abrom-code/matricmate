import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/features/exam/controllers/premium_controller.dart';
import 'package:matricmate/features/exam/screens/premium/payement.dart';
import 'package:matricmate/features/exam/screens/premium/payment_verify.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/payement_tile.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/telegram_chat.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/enums/payement_enum.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PremiumController());
    final methods = PaymentMethod.values;
    return Scaffold(
      appBar: Appbar(
        showBackArrow: true,
        title: Text(
          "Upgrade Premium",
          style: Theme.of(
            context,
          ).textTheme.headlineSmall!.apply(color: AppColors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Obx(() {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Total Amount Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade700,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Total Amount Due",
                        style: TextStyle(color: Colors.white70),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "250 ETB",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Payment Options
                ...methods.map((method) {
                  return paymentTile(
                    title: method.title,
                    subtitle: method.subtitle,
                    icon: method.icon,
                    isFeatured: method.isFeatured,
                    selected: method == controller.selectedMethod.value,
                    context: context,
                    onTap: () => controller.selectedMethod.value = method,
                  );
                }).toList(),

                const SizedBox(height: 50),
                TelegramChatButton(),
              ],
            );
          }),
        ),
      ),
      bottomNavigationBar: Obx(() {
        final isPending = UserController.instance.user.value.isPending;
        print(isPending.toString());
        return Container(
          padding: EdgeInsets.all(AppSizes.md),
          child: SizedBox(
            width: double.infinity,

            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: isPending
                  ? () => Get.to(() => PaymentVerificationScreen())
                  : () => Get.to(
                      () => PayementScreen(
                        method: controller.selectedMethod.value,
                      ),
                    ),
              child: Text(
                isPending ? "Check Status" : "Continue to Payment",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        );
      }),
    );
  }
}
