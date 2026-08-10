import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matricmate/data/services/payment_config_service.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class PaymentDetail extends StatelessWidget {
  const PaymentDetail({super.key, required this.payment});

  final PaymentConfig payment;

  @override
  Widget build(BuildContext context) {
    final isDark   = AppHelperFunctions.isDark(context);
    final number   = payment.account;
    final name     = payment.holder;

    return Padding(
      padding: const EdgeInsets.all(AppSizes.defaultSpace / 2),
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: AppSizes.spaceBtwItems / 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Account Number:',
                style: TextStyle(
                  color: isDark ? AppColors.grey : AppColors.darkGrey,
                ),
              ),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        number.length < 15
                            ? number
                            : '${number.substring(0, 12)} ...',
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                      if (name.isNotEmpty)
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.grey
                                : AppColors.darkGrey,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 5),
                  InkWell(
                    onTap: () =>
                        Clipboard.setData(ClipboardData(text: number)),
                    child: const CircleAvatar(
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
    );
  }
}
