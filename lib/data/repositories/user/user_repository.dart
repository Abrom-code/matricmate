import 'package:get/get.dart';
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
    } catch (e) {
      throw e.toString();
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
        return null;
      }

      return UserModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  /// UPDATE SINGLE FIELD
  Future<void> updateSingleField(Map<String, dynamic> json) async {
    try {
      final userId = AuthenticationRepository.instance.authUser?.uid;

      json.remove('id'); // safety

      await _supabase.from('users').update(json).eq('id', userId!);
    } catch (e) {
      throw e.toString();
    }
  }

  /// FULL UPDATE
  Future<void> updateFullUserRecord(UserModel user) async {
    try {
      await _supabase.from('users').update(user.toJson()).eq('id', user.id);
    } catch (e) {
      throw e.toString();
    }
  }

  /// DELETE USER
  Future<void> deleteUserRecord(String userId) async {
    try {
      await _supabase.from('users').delete().eq('id', userId);
    } catch (e) {
      throw e.toString();
    }
  }
}
