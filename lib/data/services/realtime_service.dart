import 'package:flutter/foundation.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/features/authentication/models/user_model.dart';
import 'package:matricmate/features/exam/models/question_model.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Listens to Supabase Realtime for:
///   1. Question/explanation edits on subjects the user has downloaded.
///   2. User record updates (e.g. subscription_status: pending → active).
///
/// Requires in Supabase:
///   ALTER PUBLICATION supabase_realtime ADD TABLE public.users;
///   ALTER TABLE public.users REPLICA IDENTITY FULL;
///
/// Usage:
///   RealtimeService.instance.start(downloadedSubjectIds, userId: uid);
///   RealtimeService.instance.stop();   // on sign-out
class RealtimeService {
  RealtimeService._();
  static final RealtimeService instance = RealtimeService._();

  final _supabase = Supabase.instance.client;

  // Two separate channels so each can be removed independently.
  RealtimeChannel? _questionsChannel;
  RealtimeChannel? _userChannel;

  /// Start listening. Safe to call multiple times — stops existing first.
  /// [userId] is always required so the user status channel starts even
  /// when the user has no downloaded subjects.
  Future<void> start(List<int> subjectIds, {required String userId}) async {
    await stop();
    _startQuestionChannel(subjectIds);
    _startUserChannel(userId);
  }

  /// Stop and clean up all Realtime channels.
  Future<void> stop() async {
    if (_questionsChannel != null) {
      await _supabase.removeChannel(_questionsChannel!);
      _questionsChannel = null;
      debugPrint('[Realtime] unsubscribed from questions');
    }
    if (_userChannel != null) {
      await _supabase.removeChannel(_userChannel!);
      _userChannel = null;
      debugPrint('[Realtime] unsubscribed from user');
    }
  }

  // ── Questions channel ─────────────────────────────────────────────────────

  void _startQuestionChannel(List<int> subjectIds) {
    if (subjectIds.isEmpty) return;

    _questionsChannel = _supabase
        .channel('question_edits')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'questions',
          // Supabase Realtime only supports a single eq() filter, so we
          // receive all question updates and filter by subject_id locally.
          callback: (payload) => _onQuestionChanged(payload, subjectIds),
        )
        .subscribe((status, [error]) {
          debugPrint(
            '[Realtime] questions: $status'
            '${error != null ? ' — $error' : ''}',
          );
        });
  }

  Future<void> _onQuestionChanged(
    PostgresChangePayload payload,
    List<int> downloadedSubjectIds,
  ) async {
    try {
      final record = payload.newRecord;
      if (record.isEmpty) return;

      final subjectId = record['subject_id'] as int?;
      if (subjectId == null) return;

      // Ignore updates for subjects the user hasn't downloaded
      if (!downloadedSubjectIds.contains(subjectId)) return;

      final question = QuestionModel.fromMap(record);
      final db = await DatabaseService.instance.database;

      await db.insert(
        'questions',
        question.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      debugPrint('[Realtime] patched question ${question.id}');
    } catch (e) {
      debugPrint('[Realtime] error patching question: $e');
    }
  }

  // ── User channel ──────────────────────────────────────────────────────────

  void _startUserChannel(String userId) {
    if (userId.isEmpty) return;

    _userChannel = _supabase
        .channel('user_status_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'users',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: userId,
          ),
          callback: (payload) => _onUserChanged(payload),
        )
        .subscribe((status, [error]) {
          debugPrint(
            '[Realtime] user: $status'
            '${error != null ? ' — $error' : ''}',
          );
        });
  }

  Future<void> _onUserChanged(PostgresChangePayload payload) async {
    try {
      final record = payload.newRecord;
      if (record.isEmpty) return;

      final updated = UserModel.fromJson(record);

      // 1. Persist to local SQLite so the status survives app restarts.
      final db = await DatabaseService.instance.database;
      await db.insert(
        'user',
        updated.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 2. Update the reactive value — every Obx watching user rebuilds
      //    instantly: badge, banners, content gates, everything.
      UserController.instance.user.value = updated;

      debugPrint('[Realtime] user status → ${updated.status}');
    } catch (e) {
      debugPrint('[Realtime] error updating user: $e');
    }
  }
}
