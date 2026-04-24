import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:matricmate/data/repositories/payment/payment_repository.dart';
import 'package:matricmate/features/exam/screens/premium/payment_verify.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart';
import 'package:matricmate/utils/enums/payement_enum.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';
import 'package:matricmate/utils/logging/logging.dart';
import 'package:matricmate/utils/network_manager/network_manager.dart';

class PremiumController extends GetxController {
  static PremiumController get instance => Get.find();

  final PaymentRepository _repo = PaymentRepository();

  final selectedMethod = PaymentMethod.telebirr.obs;
  final receipt = Rxn<XFile>();
  final isUploading = false.obs;

  final TextEditingController urlFiledController = TextEditingController();

  GlobalKey<FormState> paymentFormKey = GlobalKey<FormState>();

  /// Paste clipboard
  Future<void> pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');

    if (data?.text != null) {
      urlFiledController.text = data!.text!;
    }
  }

  /// Pick image
  Future<void> pickRecipt() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery);

      if (file != null) {
        receipt.value = file;
      }
    } catch (_) {
      ToastHelper.error("Error", "Failed to pick image");
    }
  }

  /// COMPLETE PAYMENT
  Future<void> completePayment() async {
    try {
      final userId = UserController.instance.user.value.id;

      if (userId.isEmpty) {
        ToastHelper.warning("Error", "Unexpected error happened!");
        return;
      }

      //  form validation (KEEPED)
      if (!paymentFormKey.currentState!.validate()) return;

      //  image check (KEEPED)
      if (receipt.value == null) {
        ToastHelper.warning("Warning", "Please upload receipt!");
        return;
      }

      //  network check (KEEPED)
      final isConnected = await NetworkManager.instance.hasRealInternet();

      if (!isConnected) {
        ToastHelper.warning("No Internet!", "Connect to internet!");
        return;
      }

      isUploading.value = true;

      // upload
      final result = await _repo.uploadReceipt(receipt.value!, userId);

      // save
      await _repo.savePaymentReceipt(
        userId: userId,
        receiptPath: result["filePath"]!, // FIXED
        receiptUrl: result["url"]!,
        paymentMethod: selectedMethod.value.name,
        verificationUrl: urlFiledController.text.trim(),
      );

      // set pending
      await _repo.setUserPending(userId);

      // refresh user
      await UserController.instance.fetchUserRecord();

      Get.off(() => PaymentVerificationScreen());

      ToastHelper.success("Success", "Payment submitted!");
    } catch (e) {
      ToastHelper.error("Error", e.toString());
    } finally {
      isUploading.value = false;
    }
  }

  /// CANCEL PAYMENT
  Future<void> cancelPayment() async {
    try {
      final userId = UserController.instance.user.value.id;

      if (userId.isEmpty) {
        ToastHelper.warning("Error", "Unexpected error!");
        return;
      }

      // network check
      final isConnected = await NetworkManager.instance.hasRealInternet();

      if (!isConnected) {
        ToastHelper.warning("No Internet!", "Connect to internet!");
        return;
      }

      isUploading.value = true;

      await _repo.cancelPayment(userId);

      await UserController.instance.fetchUserRecord();

      receipt.value = null;
      urlFiledController.clear();

      Get.back();

      ToastHelper.success("Cancelled", "Payment cancelled");
    } catch (e) {
      AppLoggerHelper.error(e.toString());
      ToastHelper.error("Error", e.toString());
    } finally {
      isUploading.value = false;
    }
  }
}
