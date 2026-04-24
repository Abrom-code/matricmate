import 'package:get/get.dart';
import 'package:matricmate/utils/enums/payement_enum.dart';

class PremiumController extends GetxController {
  static PremiumController get instance => Get.find();
  final Rx<PaymentMethod> selectdMethod = PaymentMethod.telebirr.obs;
}
