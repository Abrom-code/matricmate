import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:matricmate/bindings/general_binding.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/themes/theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      initialBinding: GeneralBinding(),
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      // getPages: AppRoutes.pages,
      home: const Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
    );
  }
}
