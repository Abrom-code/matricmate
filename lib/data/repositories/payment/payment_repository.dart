import 'package:matricmate/data/services/ensure_supabase_auth.dart';
import 'package:matricmate/utils/exceptions/exeption_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class PaymentRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Upload receipt
  Future<Map<String, String>> uploadReceipt(XFile file, String userId) async {
    try {
      await ensureSupabaseAuth();
      final bytes = await File(file.path).readAsBytes();

      final fileName =
          'receipt_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await _supabase.storage.from('receipts').uploadBinary(fileName, bytes);

      final url = _supabase.storage.from('receipts').getPublicUrl(fileName);

      return {"filePath": fileName, "url": url};
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  /// Save payment
  Future<void> savePaymentReceipt({
    required String userId,
    required String receiptPath,
    required String receiptUrl,
    required String paymentMethod,
    required String verificationUrl,
  }) async {
    await ensureSupabaseAuth();
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
    try {
      await ensureSupabaseAuth();
      await _supabase
          .from('users')
          .update({'subscription_status': 'pending'})
          .eq('id', userId);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  /// Cancel payment
  Future<void> cancelPayment(String userId) async {
    try {
      await ensureSupabaseAuth();
      final data = await _supabase
          .from('payment_receipts')
          .select('receipt_path')
          .eq('user_id', userId);

      if (data.isNotEmpty) {
        final List<String> filesToDelete = data
            .map((e) => e['receipt_path'].toString().trim())
            .toList();

        final List<FileObject> deletedFiles = await _supabase.storage
            .from('receipts')
            .remove(filesToDelete);

        if (deletedFiles.isEmpty) {
          throw Exception("Failed to delete any receipt files");
        }
      }

      // Attempt DB row deletion
      await _supabase
          .from('payment_receipts')
          .delete()
          .eq('user_id', userId)
          .select();

      // Update user status
      await _supabase
          .from('users')
          .update({'subscription_status': 'inactive'})
          .eq('id', userId);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }
}
