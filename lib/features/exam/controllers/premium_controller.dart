import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:matricmate/data/repositories/payment/payment_repository.dart';
import 'package:matricmate/data/services/payment_config_service.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/exceptions/exception_handler.dart';
import 'package:matricmate/utils/helpers/snackbar_helper.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';
import 'package:matricmate/utils/network_manager/network_manager.dart';
import 'package:flutter/material.dart';

class PremiumController extends GetxController {
  static PremiumController get instance => Get.find();

  final PaymentRepository _repo = PaymentRepository();
  final UserController _userController = Get.find<UserController>();
  final _cfg = PaymentConfigService.instance;

  /// Currently selected payment method. Defaults to first available from DB,
  /// or a placeholder until methods load.
  final selectedPayment = Rxn<PaymentConfig>();

  final receipt = Rxn<XFile>();
  final isUploading = false.obs;

  late final TextEditingController urlFiledController;
  late GlobalKey<FormState> paymentFormKey;

  @override
  void onInit() {
    urlFiledController = TextEditingController();
    paymentFormKey = GlobalKey<FormState>();

    // Pick the first available method once methods are loaded.
    _selectDefault();

    // Keep selection valid when the methods list changes (Realtime update).
    ever(_cfg.methods, (_) {
      final current = selectedPayment.value;
      final list = _cfg.methods;

      if (list.isEmpty) {
        selectedPayment.value = null;
        return;
      }

      // If current selection is gone from the new list, reset to first.
      if (current == null || !list.contains(current)) {
        selectedPayment.value = list.first;
      }
    });

    super.onInit();
  }

  void _selectDefault() {
    final list = _cfg.methods;
    if (list.isNotEmpty) {
      selectedPayment.value = list.first;
    }
    // If list is still empty (loading), the `ever` above will pick it up.
  }

  Future<void> pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      urlFiledController.text = data!.text!;
    }
  }

  Future<void> pickReceipt() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery);
      if (file != null) receipt.value = file;
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

      final payment = selectedPayment.value;
      if (payment == null) {
        ToastHelper.warning('Please select a payment method!');
        return;
      }

      // Show loading immediately so the button feels responsive.
      isUploading.value = true;

      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        ToastHelper.warning('No Internet!');
        return;
      }

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
        paymentMethod: payment.key,
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

      // Show loading immediately so the button feels responsive.
      isUploading.value = true;

      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        ToastHelper.warning('No Internet!');
        return;
      }

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
