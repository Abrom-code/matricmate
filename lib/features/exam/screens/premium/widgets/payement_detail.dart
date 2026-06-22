import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/enums/payement_enum.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class PayementDetail extends StatelessWidget {
  const PayementDetail({super.key, required this.method});

  final PaymentMethod method;

  @override
  Widget build(BuildContext context) {
    final isDark = AppHelperFunctions.isDark(context);
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
                'Account Name:',
                style: TextStyle(
                  color: isDark ? AppColors.grey : AppColors.darkGrey,
                ),
              ),
              Text(method.accountName),
            ],
          ),
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
                  Text(
                    method.accountNumber.length < 15
                        ? method.accountNumber
                        : '${method.accountNumber.substring(0, 12)} ...',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(width: 5),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(
                        ClipboardData(text: method.accountNumber),
                      );
                    },
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
