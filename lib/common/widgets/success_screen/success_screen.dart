import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/icons/circular_icon.dart';
import 'package:matricmate/features/authentication/controllers/authentication_controller.dart';
import 'package:matricmate/utils/constants/sizes.dart';

class SuccessScreen extends GetView<SuccessController> {
  const SuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Padding(
            padding: EdgeInsets.all(AppSizes.defaultSpace),
            child: Obx(
              () => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircularIcon(
                    icon: Icons.check,
                    color: Colors.green,
                    background: Colors.transparent,
                    iconWeight: FontWeight.w900,
                    borderColor: Colors.green,
                    size: 50,
                    radius: 100,
                  ),
                  const SizedBox(height: AppSizes.spaceBtwSections * 2),

                  Text(
                    controller.title.value,
                    style: Theme.of(context).textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.spaceBtwItems),

                  Text(
                    controller.subTitle.value,
                    style: Theme.of(context).textTheme.labelMedium,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppSizes.spaceBtwSections * 2),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          AuthenticationController.instance.screenRedirect,
                      child: Text(controller.buttonText.value),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SuccessController extends GetxController {
  final title = "".obs;
  final subTitle = "".obs;
  final buttonText = "Continue".obs;
  final nextRoute = "".obs;

  @override
  void onInit() {
    final args = Get.arguments;

    title.value = args['title'] ?? '';
    subTitle.value = args['sub_title'] ?? '';
    buttonText.value = args['button_text'] ?? 'Continue';

    super.onInit();
  }
}
