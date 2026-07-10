import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/exam/controllers/premium_controller.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/link_input_field.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/payement_detail.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/payement_tile.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/recipt_container.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/telegram_chat.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/enums/payement_enum.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class PayementScreen extends StatelessWidget {
  final PaymentMethod method;
  const PayementScreen({super.key, required this.method});

  @override
  Widget build(BuildContext context) {
    final isDark = AppHelperFunctions.isDark(context);
    final controller = Get.find<PremiumController>();
    return Scaffold(
      appBar: Appbar(
        showBackArrow: true,
        title: Text(
          '${method.title} - Payment',
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
              title: method.title,
              subtitle: method.subtitle,
              icon: method.icon,
              context: context,
              showIcon: false,
              isFeatured: method.isFeatured,
              detail: PayementDetail(method: method),
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
                  const LinkInputFiled(),
                  const SizedBox(height: AppSizes.spaceBtwSections),

                  Obx(() {
                    final file = controller.receipt.value;

                    return GestureDetector(
                      onTap: () => controller.pickRecipt(),
                      child: ReciptContainer(file: file),
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
