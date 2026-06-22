import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/common/widgets/dialogs/confirm_dialog_box.dart';
import 'package:matricmate/features/exam/controllers/premium_controller.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/telegram_chat.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';

class PaymentVerificationScreen extends StatelessWidget {
  const PaymentVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PremiumController());
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
                  textAlign: TextAlign.justify,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
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
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: AppColors.white.withValues(alpha: .5),
                            ),
                          )
                        : const Text(
                            'Refresh Payment',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // Cancel button
                TextButton(
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
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: AppColors.error.withValues(alpha: .5),
                          ),
                        )
                      : const Text(
                          'Cancel Payment',
                          style: TextStyle(fontSize: 16, color: Colors.red),
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
