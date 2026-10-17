import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:matricmate/utils/constants/app_timeouts.dart';
import 'package:matricmate/utils/exceptions/exception_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Returns the number of receipt upload attempts from the users table.
  Future<int> getReceiptCount(String userId) async {
    try {
      final data = await _supabase
          .from('users')
          .select('receipt_upload_count')
          .eq('id', userId)
          .maybeSingle()
          .timeout(AppTimeouts.query);
      return (data?['receipt_upload_count'] as num?)?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Increments receipt_upload_count for the given user in Supabase.
  Future<void> incrementReceiptUploadCount(String userId) async {
    try {
      try {
        await _supabase.rpc(
          'increment_receipt_upload_count',
          params: {'p_user_id': userId},
        ).timeout(AppTimeouts.query);
      } catch (_) {
        // Fallback: direct update if RPC is not yet created in Supabase
        final data = await _supabase
            .from('users')
            .select('receipt_upload_count')
            .eq('id', userId)
            .maybeSingle()
            .timeout(AppTimeouts.query);
        final current =
            (data?['receipt_upload_count'] as num?)?.toInt() ?? 0;
        await _supabase
            .from('users')
            .update({'receipt_upload_count': current + 1})
            .eq('id', userId)
            .timeout(AppTimeouts.query);
      }
    } catch (_) {}
  }

  /// Uploads receipt directly to Cloudflare R2 via presigned PUT URL (0 MB on Supabase Storage).
  Future<Map<String, String>> uploadReceipt(XFile file, String userId) async {
    try {
      final bytes = await file.readAsBytes();
      final fileName = 'receipt_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // 1. Request temporary presigned Cloudflare R2 upload URL from Edge Function
      final edgeRes = await _supabase.functions.invoke(
        'receipt-storage',
        body: {
          'action': 'get_upload_url',
          'file_name': fileName,
        },
      ).timeout(AppTimeouts.upload);

      final rawData = edgeRes.data;
      if (edgeRes.status != 200 || rawData == null) {
        final err = rawData is Map ? rawData['error'] : null;
        throw err?.toString() ?? 'Failed to get upload authorization (HTTP ${edgeRes.status})';
      }

      final data = Map<String, dynamic>.from(rawData as Map);
      final uploadUrl = data['upload_url']?.toString();
      final fileKey = data['file_key']?.toString();

      if (uploadUrl == null || fileKey == null || uploadUrl.isEmpty) {
        throw 'Invalid upload credentials received from server';
      }

      // 2. Upload binary directly to Cloudflare R2 via HTTP PUT
      final httpResponse = await http.put(
        Uri.parse(uploadUrl),
        headers: {
          'Content-Type': 'image/jpeg',
        },
        body: bytes,
      ).timeout(AppTimeouts.upload);

      if (httpResponse.statusCode != 200) {
        throw 'Cloudflare upload failed (HTTP ${httpResponse.statusCode})';
      }

      return {
        'filePath': fileKey,
        'url': fileKey,
      };
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[PaymentRepository] uploadReceipt error: $e\n$st');
      }
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
      }).timeout(AppTimeouts.query);

      await incrementReceiptUploadCount(userId);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  /// Set pending
  Future<void> setUserPending(String userId) async {
    try {
      await _supabase
          .from('users')
          .update({'subscription_status': 'pending'})
          .eq('id', userId)
          .timeout(AppTimeouts.query);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  /// Cancels payment receipt and resets status to inactive if still pending.
  Future<void> cancelPayment(String userId) async {
    try {
      // 1. Delete every receipt row for this user from database table
      await _supabase.from('payment_receipts').delete().eq('user_id', userId).timeout(AppTimeouts.delete);

      // 2. Revert to inactive and reset upload count only when status is still pending
      await _supabase
          .from('users')
          .update({
            'subscription_status': 'inactive',
            'receipt_upload_count': 0,
          })
          .eq('id', userId)
          .eq('subscription_status', 'pending')
          .timeout(AppTimeouts.delete);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }
}
