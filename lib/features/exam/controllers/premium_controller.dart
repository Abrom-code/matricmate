import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:matricmate/common/widgets/loaders/full_screen_loader.dart';
import 'package:matricmate/data/repositories/payment/payment_repository.dart';
import 'package:matricmate/data/services/payment_config_service.dart';
import 'package:matricmate/features/exam/models/subscription_plan.dart';
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

  /// Currently selected subscription plan (defaults to 1 Year).
  final selectedPlan = Rx<SubscriptionPlan>(SubscriptionPlan.featured);

  /// Current price in ETB for the selected plan.
  int get selectedPlanPrice => _cfg.getPriceForPlan(
    selectedPlan.value.key,
    selectedPlan.value.defaultPrice,
  );

  /// Currently selected payment method.
  final selectedPayment = Rxn<PaymentConfig>();

  final receipt = Rxn<XFile>();
  final isUploading = false.obs;

  final receiptCount = 0.obs;
  bool get exceededUploadLimit =>
      _userController.user.value.exceededUploadLimit ||
      receiptCount.value >= 2;

  late final TextEditingController urlFiledController;
  late GlobalKey<FormState> paymentFormKey;

  @override
  void onInit() {
    urlFiledController = TextEditingController();
    paymentFormKey = GlobalKey<FormState>();

    receiptCount.value = _userController.user.value.receiptUploadCount;

    // Load payment config if not yet loaded or empty
    if (!_cfg.isLoaded.value || _cfg.methods.isEmpty) {
      _cfg.load();
    }

    // Pick the first available method once methods are loaded.
    _selectDefault();

    _fetchReceiptCount();

    // Sync receiptCount whenever user model updates (e.g. Realtime admin reset)
    ever(_userController.user, (user) {
      receiptCount.value = user.receiptUploadCount;
    });

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

  Future<void> reloadPaymentConfig() async {
    await _cfg.load(force: true);
  }

  void _selectDefault() {
    final list = _cfg.methods;
    if (list.isNotEmpty) {
      selectedPayment.value = list.first;
    }
    // If list is still empty (loading), the `ever` above will pick it up.
  }

  Future<void> _fetchReceiptCount() async {
    final user = _userController.user.value;
    receiptCount.value = user.receiptUploadCount;
    if (user.id.isNotEmpty) {
      receiptCount.value = await _repo.getReceiptCount(user.id);
    }
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

      if (exceededUploadLimit) {
        Get.offNamed(Routes.contactAdmin);
        return;
      }

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

      final plan = selectedPlan.value;
      final price = selectedPlanPrice;

      await _repo.savePaymentReceipt(
        userId: userId,
        receiptPath: result['filePath']!,
        receiptUrl: result['url']!,
        paymentMethod: payment.key,
        verificationUrl: urlFiledController.text.trim(),
        planKey: plan.key,
        planDurationMonths: plan.durationMonths,
        amount: price,
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

      // Show full-screen loading dialog with spinner & status
      isUploading.value = true;
      AppFullScreenLoader.openLoadingDialog('Cancelling payment...');

      await _repo.cancelPayment(userId);
      await _userController.fetchUserRecord();

      receipt.value = null;
      urlFiledController.clear();
      receiptCount.value = 0;

      // Close loading dialog before navigation
      AppFullScreenLoader.stopLoading();

      // Pop back all the way to home (subjects screen)
      Get.until((route) => route.isFirst);
      ToastHelper.success('Payment cancelled');
    } catch (e) {
      AppFullScreenLoader.stopLoading();
      AppExceptionHandler.handleResponse(e);
    } finally {
      AppFullScreenLoader.stopLoading();
      isUploading.value = false;
    }
  }

  @override
  void onClose() {
    urlFiledController.dispose();
    super.onClose();
  }
}
