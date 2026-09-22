import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:matricmate/features/exam/models/question_report_model.dart';
import 'package:matricmate/utils/constants/app_timeouts.dart';
import 'package:matricmate/utils/exceptions/exception_handler.dart';
import 'package:matricmate/utils/network_manager/network_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuestionReportSubmitResult {
  final bool success;
  final bool isOffline;

  const QuestionReportSubmitResult({
    required this.success,
    required this.isOffline,
  });
}

class QuestionReportRepository {
  static final QuestionReportRepository instance = QuestionReportRepository._internal();
  QuestionReportRepository._internal() {
    _initConnectivityListener();
  }
  factory QuestionReportRepository() => instance;

  final SupabaseClient _supabase = Supabase.instance.client;
  final GetStorage _storage = GetStorage();
  static const String _offlineQueueKey = 'offline_question_reports_queue';

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isSyncing = false;

  void _initConnectivityListener() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = !results.contains(ConnectivityResult.none);
      if (isOnline) {
        syncPendingOfflineReports();
      }
    });
  }

  void dispose() {
    _connectivitySub?.cancel();
  }

  /// Submits a question report.
  /// If device is offline or network fails, automatically persists into local offline queue
  /// and returns `isOffline: true`.
  Future<QuestionReportSubmitResult> submitReport(QuestionReportModel report) async {
    final isOnline = await NetworkManager.instance.isConnected();

    if (!isOnline) {
      _enqueueOffline(report);
      return const QuestionReportSubmitResult(success: true, isOffline: true);
    }

    try {
      await _sendToSupabase(report);
      // Background-sync any other pending reports that were queued earlier
      unawaited(syncPendingOfflineReports());
      return const QuestionReportSubmitResult(success: true, isOffline: false);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[QuestionReportRepository] Direct submit failed ($e). Queuing offline.');
      }
      if (_isNetworkError(e)) {
        _enqueueOffline(report);
        return const QuestionReportSubmitResult(success: true, isOffline: true);
      }
      if (kDebugMode) {
        debugPrint('[QuestionReportRepository] Submit error: $e\n$st');
      }
      throw AppExceptionHandler.handle(e);
    }
  }

  /// Reads pending reports from local storage.
  List<Map<String, dynamic>> _getQueuedReports() {
    final raw = _storage.read<List>(_offlineQueueKey);
    if (raw == null) return [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Persists queued reports back to local storage.
  void _saveQueuedReports(List<Map<String, dynamic>> reports) {
    _storage.write(_offlineQueueKey, reports);
  }

  /// Enqueues a report into local storage, coalescing duplicates for the same user and question.
  void _enqueueOffline(QuestionReportModel report) {
    final list = _getQueuedReports();
    final index = list.indexWhere((item) {
      final sameUser = item['user_id'] == report.userId;
      final sameQ = report.questionId != null && item['question_id'] == report.questionId;
      final sameCq = report.challengeQuestionId != null && item['challenge_question_id'] == report.challengeQuestionId;
      return sameUser && (sameQ || sameCq);
    });

    final payload = report.toJson();
    if (index >= 0) {
      list[index] = payload;
    } else {
      list.add(payload);
    }
    _saveQueuedReports(list);

    if (kDebugMode) {
      debugPrint('[QuestionReportRepository] Report enqueued offline. Total pending: ${list.length}');
    }
  }

  /// Synchronizes all pending offline reports to Supabase when network is restored.
  Future<void> syncPendingOfflineReports() async {
    if (_isSyncing) return;
    final list = _getQueuedReports();
    if (list.isEmpty) return;

    final isOnline = await NetworkManager.instance.isConnected();
    if (!isOnline) return;

    _isSyncing = true;
    try {
      final remaining = <Map<String, dynamic>>[];
      for (int i = 0; i < list.length; i++) {
        final item = list[i];
        try {
          final model = QuestionReportModel.fromJson(item);
          await _sendToSupabase(model);
          if (kDebugMode) {
            debugPrint('[QuestionReportRepository] Successfully synced offline report for question: ${model.questionId ?? model.challengeQuestionId}');
          }
        } catch (e) {
          if (_isNetworkError(e)) {
            // Network dropped; preserve current item and all subsequent items
            remaining.addAll(list.sublist(i));
            break;
          } else {
            // Non-recoverable error (e.g. invalid foreign key or permission); discard to avoid poison pill
            if (kDebugMode) {
              debugPrint('[QuestionReportRepository] Discarding unprocessable report: $e');
            }
          }
        }
      }
      _saveQueuedReports(remaining);
    } finally {
      _isSyncing = false;
    }
  }

  /// Internal worker to upsert report into Supabase.
  Future<void> _sendToSupabase(QuestionReportModel report) async {
    var checkQuery = _supabase
        .from('question_reports')
        .select('id')
        .eq('user_id', report.userId);

    if (report.questionId != null) {
      checkQuery = checkQuery.eq('question_id', report.questionId!);
    } else if (report.challengeQuestionId != null) {
      checkQuery = checkQuery.eq('challenge_question_id', report.challengeQuestionId!);
    }

    final existing = await checkQuery.limit(1).timeout(AppTimeouts.query);
    if (existing.isNotEmpty) {
      final existingId = existing.first['id'] as String;
      await _supabase
          .from('question_reports')
          .update({
            'reason': report.reason,
            if (report.comment != null && report.comment!.trim().isNotEmpty)
              'comment': report.comment!.trim(),
            'status': 'pending',
            'created_at': DateTime.now().toIso8601String(),
          })
          .eq('id', existingId)
          .timeout(AppTimeouts.query);
      return;
    }

    await _supabase
        .from('question_reports')
        .insert(report.toJson())
        .timeout(AppTimeouts.query);
  }

  /// Determines if an exception was caused by lack of connectivity or network failure.
  bool _isNetworkError(dynamic e) {
    if (e is SocketException || e is TimeoutException || e is HttpException) {
      return true;
    }
    final msg = e.toString().toLowerCase();
    return msg.contains('socketexception') ||
        msg.contains('failed host lookup') ||
        msg.contains('network is unreachable') ||
        msg.contains('connection refused') ||
        msg.contains('timed out') ||
        msg.contains('clientexception') ||
        msg.contains('handshakeexception');
  }
}
