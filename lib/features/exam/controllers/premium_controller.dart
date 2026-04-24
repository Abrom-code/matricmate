import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:matricmate/utils/enums/payement_enum.dart';

class PremiumController extends GetxController {
  static PremiumController get instance => Get.find();
  final selectedMethod = PaymentMethod.telebirr.obs;

  final TextEditingController urlFiledController = TextEditingController();
  
  GlobalKey<FormState> paymentFormKey = GlobalKey<FormState>();

  Future<void> pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');

    if (data != null && data.text != null) {
      urlFiledController.text = data.text!;
    }
  }
}
