import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:matricmate/data/repositories/payment/payment_repository.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/enums/payement_enum.dart';
import 'package:matricmate/utils/exceptions/exeption_handler.dart';
import 'package:matricmate/utils/helpers/snackbar_helper.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';
import 'package:matricmate/utils/network_manager/network_manager.dart';

class PremiumController extends GetxController {
  static PremiumController get instance => Get.find();

  final PaymentRepository _repo = PaymentRepository();
  final UserController _userController = Get.find<UserController>();

  final selectedMethod = PaymentMethod.telebirr.obs;
  final receipt = Rxn<XFile>();
  final isUploading = false.obs;

  late final TextEditingController urlFiledController;
  late GlobalKey<FormState> paymentFormKey;

  @override
  void onInit() {
    urlFiledController = TextEditingController();
    paymentFormKey = GlobalKey<FormState>();
    super.onInit();
  }

  Future<void> pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');

    if (data?.text != null) {
      urlFiledController.text = data!.text!;
    }
  }

  Future<void> pickRecipt() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery);

      if (file != null) {
        receipt.value = file;
      }
    } catch (_) {
      ToastHelper.error('Failed to pick image');
    }
  }

  Future<void> completePayment() async {
    try {
      if (!paymentFormKey.currentState!.validate()) return;

      if (receipt.value == null) {
        ToastHelper.warning('Please upload receipt!');
        return;
      }

      final isConnected = await NetworkManager.instance.isConnected();

      if (!isConnected) {
        ToastHelper.warning('No Internet!');
        return;
      }

      isUploading.value = true;

      final userId = _userController.user.value.id;

      if (userId.isEmpty) {
        SnackbarHelper.error('Error', 'No user found!');
        return;
      }

      final result = await _repo.uploadReceipt(receipt.value!, userId);

      await _repo.savePaymentReceipt(
        userId: userId,
        receiptPath: result['filePath']!,
        receiptUrl: result['url']!,
        paymentMethod: selectedMethod.value.name,
        verificationUrl: urlFiledController.text.trim(),
      );

      await _repo.setUserPending(userId);

      await _userController.fetchUserRecord();

      Get.offNamed(Routes.paymentVerification);

      ToastHelper.success('Payment submitted!');
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    } finally {
      isUploading.value = false;
    }
  }

  Future<void> cancelPayment() async {
    try {
      final userId = _userController.user.value.id;

      if (userId.isEmpty) {
        ToastHelper.warning('Unexpected error!');
        return;
      }

      final isConnected = await NetworkManager.instance.isConnected();

      if (!isConnected) {
        ToastHelper.warning('No Internet!');
        return;
      }

      isUploading.value = true;

      await _repo.cancelPayment(userId);

      await _userController.fetchUserRecord();

      receipt.value = null;
      urlFiledController.clear();

      Get.back();

      ToastHelper.success('Payment cancelled');
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    } finally {
      isUploading.value = false;
    }
  }

  @override
  void onClose() {
    urlFiledController.dispose();
    super.onClose();
  }
}
