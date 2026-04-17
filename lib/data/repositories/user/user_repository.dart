import 'package:get/get.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:matricmate/data/repositories/authentication/authentication_repository.dart';
import 'package:matricmate/features/authentication/models/user_model.dart';

class UserRepository extends GetxController {
  static UserRepository get instance => Get.find();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// SAVE (UPSERT)
  Future<void> saveUserRecord(UserModel user) async {
    try {
      await _supabase.from('users').upsert(user.toJson(), onConflict: 'id');

      ToastHelper.success("Success", "User saved successfully.");
    } catch (e) {
      ToastHelper.error("Error", "Failed to save user.");
      rethrow;
    }
  }

  /// FETCH USER
  Future<UserModel?> fetchUserDetails() async {
    try {
      final userId = AuthenticationRepository.instance.authUser?.uid;

      final data = await _supabase
          .from('users')
          .select()
          .eq('id', userId!)
          .maybeSingle();

      if (data == null) {
        ToastHelper.error("Error", "User not found.");
        return null;
      }

      return UserModel.fromJson(data);
    } catch (e) {
      ToastHelper.error("Error", "Failed to fetch user.");
      return null;
    }
  }

  /// UPDATE SINGLE FIELD
  Future<void> updateSingleField(Map<String, dynamic> json) async {
    try {
      final userId = AuthenticationRepository.instance.authUser?.uid;

      json.remove('id'); // safety

      await _supabase.from('users').update(json).eq('id', userId!);

      ToastHelper.success("Success", "User updated successfully.");
    } catch (e) {
      ToastHelper.error("Error", "Failed to update user.");
    }
  }

  /// FULL UPDATE
  Future<void> updateFullUserRecord(UserModel user) async {
    try {
      await _supabase.from('users').update(user.toJson()).eq('id', user.id);

      ToastHelper.success("Success", "User updated successfully.");
    } catch (e) {
      ToastHelper.error("Error", "Failed to update user.");
    }
  }

  /// DELETE USER
  Future<void> deleteUserRecord(String userId) async {
    try {
      await _supabase.from('users').delete().eq('id', userId);

      ToastHelper.success("Success", "User deleted successfully.");
    } catch (e) {
      ToastHelper.error("Error", "Failed to delete user.");
      rethrow;
    }
  }
}
