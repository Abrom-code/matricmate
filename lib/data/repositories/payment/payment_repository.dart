import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class PaymentRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Upload receipt image
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

    // return PUBLIC URL (for UI)
    return _supabase.storage.from('receipts').getPublicUrl(fileName);
  }

  /// Save payment record
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

  /// Set user pending
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

  Future<void> cancelPayment(String userId) async {
    // 1. Get receipt URL
    final data = await _supabase
        .from('payment_receipts')
        .select('receipt_url')
        .eq('user_id', userId)
        .maybeSingle();

    final receiptUrl = data?['receipt_url'];

    if (receiptUrl != null) {
      final filePath = _extractFilePath(receiptUrl);

      if (filePath != null) {
        await _supabase.storage.from('receipts').remove([filePath]);
      }
    }

    await _supabase.from('payment_receipts').delete().eq('user_id', userId);

    // 4. Reset user status
    await _supabase
        .from('users')
        .update({'subscription_status': 'inactive'})
        .eq('id', userId);
  }

  /// Extract file path from Supabase public URL
  String? _extractFilePath(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;

      final index = segments.indexOf('receipts');
      if (index == -1 || index + 1 >= segments.length) return null;

      return segments.sublist(index + 1).join('/');
    } catch (_) {
      return null;
    }
  }
}
