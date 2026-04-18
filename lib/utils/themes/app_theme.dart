import 'package:flutter/material.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/themes/custom_themes/appbar_theme.dart';
import 'package:matricmate/utils/themes/custom_themes/bottom_sheet_theme.dart';
import 'package:matricmate/utils/themes/custom_themes/checkbox_theme.dart';
import 'package:matricmate/utils/themes/custom_themes/chip_theme.dart';
import 'package:matricmate/utils/themes/custom_themes/elevated_button_theme.dart';
import 'package:matricmate/utils/themes/custom_themes/input_field_theme.dart';
import 'package:matricmate/utils/themes/custom_themes/outlined_button_theme.dart';
import 'custom_themes/text_theme.dart';

class AppTheme {
  AppTheme._();

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: Brightness.light,
    ),
    fontFamily: "Poppins",
    textTheme: AppTextTheme.lightTextTheme.apply(
      fontFamilyFallback: ["Roboto", "Sans-serif"],
    ),
    scaffoldBackgroundColor: AppColors.light,
    appBarTheme: AppAppBarTheme.lightAppBarTheme,
    bottomSheetTheme: AppBottomSheetTheme.lightBottomSheetTheme,
    checkboxTheme: AppCheckboxTheme.lightCheckboxTheme,
    chipTheme: AppChipTheme.lightChipTheme,
    elevatedButtonTheme: AppElevatedButtonTheme.lightElevatedButtonTheme,
    inputDecorationTheme: AppTextFormFieldTheme.lightInputDecorationTheme,
    outlinedButtonTheme: AppOutlinedButtonTheme.lightOutlinedButtonTheme,
    primaryColor: Colors.teal,
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: Brightness.dark,
    ),
    fontFamily: "Poppins",
    textTheme: AppTextTheme.darkTextTheme.apply(
      // FIXED: Using darkTextTheme
      fontFamilyFallback: ["Roboto", "Sans-serif"],
    ),
    scaffoldBackgroundColor: Colors.black,
    appBarTheme: AppAppBarTheme.darkAppBarTheme,
    bottomSheetTheme: AppBottomSheetTheme.darkBottomSheetTheme,
    checkboxTheme: AppCheckboxTheme.darkCheckboxTheme,
    chipTheme: AppChipTheme.darkChipTheme,
    elevatedButtonTheme: AppElevatedButtonTheme.darkElevatedButtonTheme,
    inputDecorationTheme: AppTextFormFieldTheme.darkInputDecorationTheme,
    outlinedButtonTheme: AppOutlinedButtonTheme.darkOutlinedButtonTheme,
    primaryColor: Colors.teal,
  );
}
