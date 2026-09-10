import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matricmate/features/authentication/controllers/login/verify_reset_otp_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class OtpInputWidget extends StatelessWidget {
  final VerifyResetOtpController controller;

  const OtpInputWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return _buildDigitBox(context, index, dark);
      }),
    );
  }

  Widget _buildDigitBox(BuildContext context, int index, bool dark) {
    return SizedBox(
      width: 46,
      height: 56,
      child: Focus(
        onKeyEvent: (node, event) {
          // Detect Backspace key when the current field is empty to jump back
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              controller.otpControllers[index].text.isEmpty &&
              index > 0) {
            controller.focusNodes[index - 1].requestFocus();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: TextFormField(
          controller: controller.otpControllers[index],
          focusNode: controller.focusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          autofocus: index == 0,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: dark ? AppColors.white : const Color(0xFF0F172A),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
          onChanged: (value) {
            // Handle paste of 6 digits in any cell
            if (value.length > 1) {
              controller.handlePastedOtp(value);
              return;
            }

            if (value.isNotEmpty) {
              if (index < 5) {
                controller.focusNodes[index + 1].requestFocus();
              } else {
                controller.focusNodes[index].unfocus();
              }
            }

            controller.updateOtpFromControllers();
          },
          decoration: InputDecoration(
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            filled: true,
            fillColor: dark ? AppColors.darkInputFill : AppColors.lightInputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
