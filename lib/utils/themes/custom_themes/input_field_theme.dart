import 'package:flutter/material.dart';
import 'package:matricmate/utils/constants/colors.dart';

class AppTextFormFieldTheme {
  AppTextFormFieldTheme._();

  static InputDecorationTheme lightInputDecorationTheme = InputDecorationTheme(
    errorMaxLines: 3,
    prefixIconColor: AppColors.lightInputLabel,
    suffixIconColor: AppColors.lightInputLabel,
    labelStyle: const TextStyle(
      fontSize: 13.5,
      fontWeight: FontWeight.w500,
      color: AppColors.lightInputLabel,
    ),
    hintStyle: const TextStyle(
      fontSize: 13.5,
      fontWeight: FontWeight.w400,
      color: AppColors.lightInputHint,
    ),
    errorStyle: const TextStyle(
      fontSize: 11.5,
      fontWeight: FontWeight.w500,
      color: AppColors.error,
    ),
    floatingLabelStyle: const TextStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
      color: AppColors.primary,
    ),
    fillColor: AppColors.lightInputFill,
    filled: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1.2, color: AppColors.lightInputBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1.2, color: AppColors.lightInputBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1.6, color: AppColors.primary),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1.2, color: AppColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1.6, color: AppColors.error),
    ),
  );

  static InputDecorationTheme darkInputDecorationTheme = InputDecorationTheme(
    errorMaxLines: 3,
    prefixIconColor: AppColors.darkInputLabel,
    suffixIconColor: AppColors.darkInputLabel,
    labelStyle: const TextStyle(
      fontSize: 13.5,
      fontWeight: FontWeight.w500,
      color: AppColors.darkInputLabel,
    ),
    hintStyle: const TextStyle(
      fontSize: 13.5,
      fontWeight: FontWeight.w400,
      color: AppColors.darkInputHint,
    ),
    errorStyle: const TextStyle(
      fontSize: 11.5,
      fontWeight: FontWeight.w500,
      color: Color(0xFFF87171),
    ),
    floatingLabelStyle: const TextStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
      color: AppColors.primary,
    ),
    fillColor: AppColors.darkInputFill,
    filled: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1.2, color: AppColors.darkInputBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1.2, color: AppColors.darkInputBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1.6, color: AppColors.primary),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1.2, color: Color(0xFFEF4444)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1.6, color: Color(0xFFEF4444)),
    ),
  );
}
