import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/authentication/controllers/login/forgot_password_controller.dart';
import 'package:matricmate/features/authentication/screens/password_configuration/forget_password.dart';
import 'package:matricmate/routes/app_routes.dart';

class FakeForgotPasswordController extends GetxController
    implements ForgotPasswordController {
  @override
  final TextEditingController email = TextEditingController();

  @override
  final RxBool isLoading = false.obs;

  @override
  final GlobalKey<FormState> forgetPasswordFormkey = GlobalKey<FormState>();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('ForgetPasswordScreen shows "Don\'t have an account? Register" footer', (tester) async {
    Get.put<ForgotPasswordController>(FakeForgotPasswordController());

    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: Routes.forgotPassword,
        getPages: [
          GetPage(
            name: Routes.forgotPassword,
            page: () => const ForgetPasswordScreen(),
          ),
          GetPage(
            name: Routes.signup,
            page: () => const Scaffold(body: Text('Signup Screen')),
          ),
        ],
      ),
    );

    // Verify footer text and register button are rendered
    expect(find.text("Don't have an account?"), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);

    // Tap Register and verify navigation
    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();

    expect(find.text('Signup Screen'), findsOneWidget);
  });
}
