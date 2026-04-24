import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class PaymentRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  ///  Upload image to Supabase Storage
  Future<String> uploadReceipt(XFile file, String userId) async {
    final bytes = await File(file.path).readAsBytes();

    final fileName =
        'receipt_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

    await _supabase.storage
        .from('receipts')
        .uploadBinary(
          fileName,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/*'),
        );

    return _supabase.storage.from('receipts').getPublicUrl(fileName);
  }

  ///  Save payment receipt in DB
  Future<void> savePaymentReceipt({
    required String userId,
    required String receiptUrl,
    required String paymentMethod,
    required String verificationUrl,
  }) async {
    await _supabase.from('payment_receipts').insert({
      'user_id': userId,
      'receipt_url': receiptUrl,
      'payment_method': paymentMethod,
      'verification_url': verificationUrl,
    });
  }

  /// Update user status → pending
  Future<void> setUserPending(String userId) async {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;

    if (currentUid != userId) {
      throw Exception("Unauthorized");
    }
    await _supabase
        .from('users')
        .update({'subscription_status': 'pending'})
        .eq('id', userId);
  }

  /// Cancel payment → remove receipt + reset user status
  Future<void> cancelPayment(String userId) async {
    // 1. Delete payment receipt records
    await _supabase.from('payment_receipts').delete().eq('user_id', userId);

    // 2. Reset user status to inactive
    await _supabase
        .from('users')
        .update({'subscription_status': 'inactive'})
        .eq('id', userId);
  }
}
