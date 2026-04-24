import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/payement_tile.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/enums/payement_enum.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class PayementScreen extends StatelessWidget {
  final PaymentMethod method;
  const PayementScreen({super.key, required this.method});

  @override
  Widget build(BuildContext context) {
    final isDark = AppHelperFuntions.isDark(context);
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
        padding: EdgeInsets.all(AppSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "SELECTED METHOD",
                  style: TextStyle(
                    color: isDark ? AppColors.grey : AppColors.darkerGrey,
                  ),
                ),
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text(
                    "Change",
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
              selected: true,
              isFeatured: method.isFeatured,
              detail: Padding(
                padding: const EdgeInsets.all(AppSizes.defaultSpace / 2),
                child: Column(
                  children: [
                    Divider(),
                    const SizedBox(height: AppSizes.spaceBtwItems / 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Account Name:",
                          style: TextStyle(
                            color: isDark ? AppColors.grey : AppColors.darkGrey,
                          ),
                        ),
                        Text("Hamas Masah"),
                      ],
                    ),
                    const SizedBox(height: AppSizes.spaceBtwItems / 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Account Number:",
                          style: TextStyle(
                            color: isDark ? AppColors.grey : AppColors.darkGrey,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              "19197398",
                              softWrap: true,
                              style: TextStyle(fontStyle: FontStyle.italic),
                            ),
                            SizedBox(width: 5),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(
                                  const ClipboardData(text: "197799398"),
                                );
                              },
                              child: CircleAvatar(
                                radius: 13,

                                backgroundColor: Colors.transparent,
                                child: Icon(
                                  Icons.copy,
                                  size: 15,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.spaceBtwItems),

            Text(
              "VERIFY TRANSACTION",
              style: TextStyle(
                color: isDark ? AppColors.grey : AppColors.darkerGrey,
              ),
            ),
            const SizedBox(height: AppSizes.spaceBtwItems * 2),

            Form(
              child: Column(
                children: [
                  TextFormField(
                    onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "https://cbe.com:299/verify....",
                      hintStyle: Theme.of(context).textTheme.labelMedium,
                      // Prefix icon
                      prefixIcon: const Icon(Icons.link, color: Colors.teal),

                      // Filled background
                      filled: true,
                      fillColor: isDark ? AppColors.dark : Colors.grey.shade100,

                      // Content spacing
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),

                      // Default border
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),

                      // Enabled border
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.darkerGrey
                              : Colors.grey.shade300,
                        ),
                      ),

                      // Focused border
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.teal,
                          width: 1.5,
                        ),
                      ),

                      // Optional label
                      labelText: "Payment Link",
                      labelStyle: const TextStyle(color: Colors.teal),
                    ),
                  ),
                  const SizedBox(height: AppSizes.spaceBtwItems),

                  GestureDetector(
                    onTap: () {
                      // open file picker here
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.teal.withValues(alpha: 0.4),
                          width: 1.5,
                          style: BorderStyle.solid,
                        ),
                        color: isDark ? AppColors.dark : Colors.grey.shade100,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Icon circle
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.cloud_upload_outlined,
                              color: Colors.teal,
                              size: 28,
                            ),
                          ),

                          const SizedBox(height: 12),

                          const Text(
                            "Upload Receipt Screenshot",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            "PNG, JPG OR PDF UP TO 5MB",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.spaceBtwSections),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {},
                      child: Text(
                        "PAY",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
