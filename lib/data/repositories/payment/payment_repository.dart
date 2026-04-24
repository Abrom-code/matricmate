import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class PaymentRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Upload receipt
  Future<Map<String, String>> uploadReceipt(XFile file, String userId) async {
    final bytes = await File(file.path).readAsBytes();

    final fileName =
        'receipt_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

    await _supabase.storage.from('receipts').uploadBinary(fileName, bytes);

    final url = _supabase.storage.from('receipts').getPublicUrl(fileName);

    return {"filePath": fileName, "url": url};
  }

  /// Save payment
  Future<void> savePaymentReceipt({
    required String userId,
    required String receiptPath,
    required String receiptUrl,
    required String paymentMethod,
    required String verificationUrl,
  }) async {
    await _supabase.from('payment_receipts').insert({
      'user_id': userId,
      'receipt_path': receiptPath,
      'receipt_url': receiptUrl,
      'payment_method': paymentMethod,
      'verification_url': verificationUrl,
    });
  }

  /// Set pending
  Future<void> setUserPending(String userId) async {
    await _supabase
        .from('users')
        .update({'subscription_status': 'pending'})
        .eq('id', userId);
  }

  /// Cancel payment
  Future<void> cancelPayment(String userId) async {
    try {
      final data = await _supabase
          .from('payment_receipts')
          .select('receipt_path')
          .eq('user_id', userId)
          .maybeSingle();

      if (data != null) {
        final String filePath = data['receipt_path'];

        final List<String> filesToDelete = [filePath.trim()];
        final List<FileObject> deletedFiles = await _supabase.storage
            .from('receipts')
            .remove(filesToDelete);

        if (deletedFiles.isEmpty) {
          print(
            "Storage Warning: No file was deleted. Check path or policies.",
          );
        }
      }

      // Attempt DB row deletion
      final response = await _supabase
          .from('payment_receipts')
          .delete()
          .eq('user_id', userId)
          .select();

      print("DB Delete Response: $response");

      // Update user status
      await _supabase
          .from('users')
          .update({'subscription_status': 'inactive'})
          .eq('id', userId);
    } catch (e) {
      print("Full Error in cancelPayment: $e");
      throw e.toString();
    }
  }
}
