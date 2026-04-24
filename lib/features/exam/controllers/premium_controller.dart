import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:matricmate/utils/enums/payement_enum.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';

class PremiumController extends GetxController {
  static PremiumController get instance => Get.find();
  final selectedMethod = PaymentMethod.telebirr.obs;
  final receipt = Rxn<XFile>();

  final TextEditingController urlFiledController = TextEditingController();

  GlobalKey<FormState> paymentFormKey = GlobalKey<FormState>();

  Future<void> pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');

    if (data != null && data.text != null) {
      urlFiledController.text = data.text!;
    }
  }

  Future<void> pickRecipt() async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile != null) {
        receipt.value = pickedFile;
      }
    } catch (e) {
      ToastHelper.error("Error", "Faild to pick image");
    }
  }
}
