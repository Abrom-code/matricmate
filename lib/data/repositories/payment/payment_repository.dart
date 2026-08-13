import 'package:matricmate/data/services/ensure_supabase_auth.dart';
import 'package:matricmate/utils/exceptions/exception_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class PaymentRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Returns the number of receipt rows the user has uploaded.
  Future<int> getReceiptCount(String userId) async {
    try {
      await ensureSupabaseAuth();
      final data = await _supabase
          .from('payment_receipts')
          .select('id')
          .eq('user_id', userId);
      return data.length;
    } catch (_) {
      return 0;
    }
  }

  /// Upload receipt
  Future<Map<String, String>> uploadReceipt(XFile file, String userId) async {
    try {
      await ensureSupabaseAuth();
      final bytes = await File(file.path).readAsBytes();

      final fileName =
          'receipt_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await _supabase.storage.from('receipts').uploadBinary(fileName, bytes);

      final url = _supabase.storage.from('receipts').getPublicUrl(fileName);

      return {'filePath': fileName, 'url': url};
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
    try {
      await ensureSupabaseAuth();
      await _supabase.from('payment_receipts').insert({
        'user_id': userId,
        'receipt_path': receiptPath,
        'receipt_url': receiptUrl,
        'payment_method': paymentMethod,
        'verification_url': verificationUrl,
      });
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
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

  /// Cancel payment — wipes the user's full receipt history and storage files,
  /// but only reverts subscription_status to 'inactive' when the status is
  /// still 'pending'. If an admin already approved ('active'), that stays
  /// untouched — the admin owns that state.
  Future<void> cancelPayment(String userId) async {
    try {
      await ensureSupabaseAuth();

      // 1. Collect all file paths so storage stays clean.
      final data = await _supabase
          .from('payment_receipts')
          .select('receipt_path')
          .eq('user_id', userId);

      if (data.isNotEmpty) {
        final filesToDelete = data
            .map((e) => e['receipt_path']?.toString().trim() ?? '')
            .where((p) => p.isNotEmpty)
            .toList();

        if (filesToDelete.isNotEmpty) {
          // Best-effort — a storage failure must not block the DB cleanup.
          try {
            await _supabase.storage.from('receipts').remove(filesToDelete);
          } catch (_) {}
        }
      }

      // 2. Delete every receipt row for this user.
      await _supabase
          .from('payment_receipts')
          .delete()
          .eq('user_id', userId);

      // 3. Revert to inactive only when the status is still 'pending'.
      //    '.eq(subscription_status, pending)' means the UPDATE is a no-op
      //    if admin already flipped it to 'active' — no accidental downgrade.
      await _supabase
          .from('users')
          .update({'subscription_status': 'inactive'})
          .eq('id', userId)
          .eq('subscription_status', 'pending');
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }
}
