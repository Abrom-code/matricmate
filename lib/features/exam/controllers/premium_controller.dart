import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:matricmate/data/repositories/payment/payment_repository.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart';
import 'package:matricmate/utils/enums/payement_enum.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';
import 'package:matricmate/utils/network_manager/network_manager.dart';

class PremiumController extends GetxController {
  static PremiumController get instance => Get.find();

  final PaymentRepository _repo = PaymentRepository();

  final selectedMethod = PaymentMethod.telebirr.obs;
  final receipt = Rxn<XFile>();
  final isUploading = false.obs;

  final TextEditingController urlFiledController = TextEditingController();
  GlobalKey<FormState> paymentFormKey = GlobalKey<FormState>();

  ///  Paste verification link
  Future<void> pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');

    if (data != null && data.text != null) {
      urlFiledController.text = data.text!;
    }
  }

  ///  Pick receipt image
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
      ToastHelper.error("Error", "Failed to pick image");
    }
  }

  ///  COMPLETE PAYMENT FLOW (MAIN LOGIC)
  Future<void> completePayment() async {
    try {
      final userId = UserController.instance.user.value.id;
      if (userId.isEmpty) {
        ToastHelper.warning("Error", "Unexpected error happend!");
        return;
      }
      if (!paymentFormKey.currentState!.validate()) return;

      if (receipt.value == null) {
        ToastHelper.warning("Warning", "Please upload the receipt!");
        return;
      }

      final isConnected = await NetworkManager.instance.hasRealInternet();

      if (!isConnected) {
        ToastHelper.warning("No Internet!", "Please connect to internet!");
        return;
      }

      isUploading.value = true;

      //  Upload receipt image
      final receiptUrl = await _repo.uploadReceipt(receipt.value!, userId);

      //  Save receipt in DB
      await _repo.savePaymentReceipt(
        userId: userId,
        receiptUrl: receiptUrl,
        paymentMethod: selectedMethod.value.name,
        verificationUrl: urlFiledController.text.trim(),
      );

      //  Set user to pending
      await _repo.setUserPending(userId);

      Get.back();
      ToastHelper.success("Success", "Payment submitted successfully");
    } catch (e) {
      ToastHelper.error("Error", e.toString());
    } finally {
      isUploading.value = false;
    }
  }
}
