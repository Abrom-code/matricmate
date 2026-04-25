import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';

class AppbarStatusTitle extends StatelessWidget {
  const AppbarStatusTitle({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final status = UserController.instance.user.value.status;

      Color statusColor;
      String statusText;

      switch (status) {
        case "active":
          statusColor = const Color(0xFF1DE9B6);
          statusText = 'PREMIUM';
          break;
        case "pending":
          statusColor = const Color(0xFFFFD54F);
          statusText = 'PENDING';
          break;
        case "inactive":
        default:
          statusColor = const Color(0xFFB2DFDB);
          statusText = 'FREE';
      }

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall!.apply(color: AppColors.white),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    });
  }
}
