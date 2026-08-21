import 'package:matricmate/data/services/ensure_supabase_auth.dart';
import 'package:matricmate/utils/exceptions/exception_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class PaymentRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Returns the number of receipt upload attempts from the users table.
  Future<int> getReceiptCount(String userId) async {
    try {
      await ensureSupabaseAuth();
      final data = await _supabase
          .from('users')
          .select('receipt_upload_count')
          .eq('id', userId)
          .maybeSingle();
      return (data?['receipt_upload_count'] as num?)?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Increments receipt_upload_count for the given user in Supabase.
  Future<void> incrementReceiptUploadCount(String userId) async {
    try {
      await ensureSupabaseAuth();
      try {
        await _supabase.rpc(
          'increment_receipt_upload_count',
          params: {'p_user_id': userId},
        );
      } catch (_) {
        // Fallback: direct update if RPC is not yet created in Supabase
        final data = await _supabase
            .from('users')
            .select('receipt_upload_count')
            .eq('id', userId)
            .maybeSingle();
        final current =
            (data?['receipt_upload_count'] as num?)?.toInt() ?? 0;
        await _supabase
            .from('users')
            .update({'receipt_upload_count': current + 1})
            .eq('id', userId);
      }
    } catch (_) {}
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

  /// Save payment receipt with chosen plan details
  Future<void> savePaymentReceipt({
    required String userId,
    required String receiptPath,
    required String receiptUrl,
    required String paymentMethod,
    required String verificationUrl,
    String? planKey,
    int? planDurationMonths,
    num? amount,
  }) async {
    try {
      await ensureSupabaseAuth();
      await _supabase.from('payment_receipts').insert({
        'user_id': userId,
        'receipt_path': receiptPath,
        'receipt_url': receiptUrl,
        'payment_method': paymentMethod,
        'verification_url': verificationUrl,
        if (planKey != null) 'plan_key': planKey,
        if (planDurationMonths != null)
          'plan_duration_months': planDurationMonths,
        if (amount != null) 'amount': amount,
      });

      await incrementReceiptUploadCount(userId);
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

  /// Cancels payment receipt and resets status to inactive if still pending.
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
      await _supabase.from('payment_receipts').delete().eq('user_id', userId);

      // 3. Revert to inactive and reset upload count only when status is still pending
      await _supabase
          .from('users')
          .update({
            'subscription_status': 'inactive',
            'receipt_upload_count': 0,
          })
          .eq('id', userId)
          .eq('subscription_status', 'pending');
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }
}
