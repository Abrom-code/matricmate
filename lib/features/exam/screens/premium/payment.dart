import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/data/services/payment_config_service.dart';
import 'package:matricmate/features/exam/controllers/premium_controller.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/link_input_field.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/payment_detail.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/payment_tile.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/receipt_container.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/telegram_chat.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class PaymentScreen extends StatelessWidget {
  final PaymentConfig payment;
  const PaymentScreen({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    final isDark = AppHelperFunctions.isDark(context);
    final controller = Get.find<PremiumController>();

    return Scaffold(
      appBar: Appbar(
        showBackArrow: true,
        title: Text(
          '${payment.label} - Payment',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall!.apply(color: AppColors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SELECTED METHOD',
                  style: TextStyle(
                    color: isDark ? AppColors.grey : AppColors.darkerGrey,
                  ),
                ),
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text(
                    'Change',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            ),
            paymentTile(
              title: payment.label,
              subtitle: payment.account.isNotEmpty
                  ? payment.account.length < 15
                      ? payment.account
                      : '${payment.account.substring(0, 12)}...'
                  : '',
              icon: payment.icon,
              context: context,
              showIcon: false,
              isFeatured: payment.isFeatured,
              detail: PaymentDetail(payment: payment),
            ),
            const SizedBox(height: AppSizes.spaceBtwItems),

            Text(
              'VERIFY TRANSACTION',
              style: TextStyle(
                color: isDark ? AppColors.grey : AppColors.darkerGrey,
              ),
            ),
            const SizedBox(height: AppSizes.spaceBtwItems * 2),

            Form(
              key: controller.paymentFormKey,
              child: Column(
                children: [
                  const LinkInputField(),
                  const SizedBox(height: AppSizes.spaceBtwSections),
                  Obx(() {
                    final file = controller.receipt.value;
                    return GestureDetector(
                      onTap: () => controller.pickReceipt(),
                      child: ReceiptContainer(file: file),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.spaceBtwItems * 2),
            const Divider(),
            const TelegramChatButton(),
          ],
        ),
      ),
      bottomNavigationBar: Obx(() {
        return Container(
          padding: const EdgeInsets.all(AppSizes.md),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
                minimumSize: const Size.fromHeight(50),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: controller.isUploading.value
                  ? null
                  : () => controller.completePayment(),
              child: controller.isUploading.value
                  ? const AppCircularButtonLoading()
                  : const Text(
                      'Complete Payment',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
            ),
          ),
        );
      }),
    );
  }
}
