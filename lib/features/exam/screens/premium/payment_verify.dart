import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/common/widgets/dialogs/confirm_dialog_box.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/exam/controllers/premium_controller.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/telegram_chat.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';

class PaymentVerificationScreen extends StatelessWidget {
  const PaymentVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<PremiumController>()
        ? Get.find<PremiumController>()
        : Get.put(PremiumController());
    return Scaffold(
      appBar: Appbar(
        showBackArrow: true,
        title: Text(
          'Verify Payment',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall!.apply(color: AppColors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Obx(() {
            final isFetching = UserController.instance.userFetching.value;
            final isLoading = controller.isUploading.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 60),

                // Title
                const Text(
                  'Payment Verification in Progress',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 15),

                // Subtitle
                const Text(
                  'We are verifying your receipt. This usually takes a few hours. '
                  "Please click the refresh status button after around 30 minutes. If this couldn't work, please contact the our support on Telegram.",
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    color: AppColors.darkGrey,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 40),

                // Refresh button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await UserController.instance.checkPaymentStatus();
                    },
                    icon: isFetching ? null : const Icon(Icons.refresh),
                    label: isFetching && !isLoading
                        ? const AppCircularButtonLoading()
                        : const Text(
                            'Refresh Payment',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // Cancel button
                SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: TextButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            AppDialogBoxes.showOkCancelDialog(
                              context: context,
                              title: 'Cancel Payment',
                              subtitle:
                                  'Are you sure you want to cancel this payment?',
                              onPressed: () {
                                Get.back();
                                controller.cancelPayment();
                              },
                            );
                          },
                    child: isLoading
                        ? const AppCircularButtonLoading(color: AppColors.error)
                        : const Text(
                            'Cancel Payment',
                            style: TextStyle(fontSize: 16, color: Colors.red),
                          ),
                  ),
                ),
                const SizedBox(height: 15),
                const Divider(),
                const SizedBox(height: 15),

                // Back to home button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Get.until((route) => route.isFirst),
                    icon: const Icon(Icons.home_outlined),
                    label: const Text(
                      'Back to Home',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 15),
                const Divider(),
                const SizedBox(height: 15),

                const TelegramChatButton(),
              ],
            );
          }),
        ),
      ),
    );
  }
}
