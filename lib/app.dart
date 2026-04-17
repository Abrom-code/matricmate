import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/bindings/general_binding.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/themes/app_theme.dart';
import 'package:matricmate/utils/themes/theme_controller.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.put(ThemeController());

    return Obx(
      () => GetMaterialApp(
        initialBinding: GeneralBinding(),
        debugShowCheckedModeBanner: false,
        themeMode: themeController.themeMode.value,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const Scaffold(
          backgroundColor: AppColors.primary,
          body: Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
      ),
    );
  }
}
