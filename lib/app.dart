import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/route_manager.dart';
import 'package:matricmate/bindings/general_binding.dart';
import 'package:matricmate/features/authentication/screens/login/login.dart';
import 'package:matricmate/utils/themes/app_theme.dart';
import 'package:matricmate/utils/themes/theme_controller.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      initialBinding: GeneralBinding(),
      debugShowCheckedModeBanner: false,

      builder: (context, child) {
        final controller = Get.find<ThemeController>();

        return Obx(
          () => MaterialApp(
            debugShowCheckedModeBanner: false,
            themeMode: controller.themeMode.value,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: child,
          ),
        );
      },

      home: LoginScreen(),
    );
  }
}
