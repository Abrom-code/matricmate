import 'package:get/get.dart';
import 'package:matricmate/features/authentication/models/user_model.dart';

class UserRepository extends GetxController {
  static UserRepository get instance => Get.find();

  Future<void> saveUserRecord(UserModel user) async {}

  Future<void> fetchUserDetails() async {}

  /// Update specific fields of a user record
  Future<void> updateSingleField(Map<String, dynamic> json) async {}

  Future<void> updateFullUserRecord(UserModel user) async {}

  // Delete user account
  Future<void> deleteUserRecord(String userId) async {}
}
