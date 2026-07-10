import 'package:flutter/foundation.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/features/exam/models/question_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Listens to Supabase Realtime for question/explanation edits on subjects
/// the user has already downloaded. Updates SQLite silently in the background.
///
/// Only subscribed to UPDATE events — new tests/questions are handled by
/// the delta sync flow. This is strictly for text edits on existing rows.
///
/// Usage:
///   RealtimeService.instance.start(downloadedSubjectIds);
///   RealtimeService.instance.stop();   // on sign-out
class RealtimeService {
  RealtimeService._();
  static final RealtimeService instance = RealtimeService._();

  final _supabase = Supabase.instance.client;
  RealtimeChannel? _channel;

  /// Start listening for question edits across [subjectIds].
  /// Safe to call multiple times — stops existing subscription first.
  Future<void> start(List<int> subjectIds) async {
    if (subjectIds.isEmpty) return;
    await stop();

    _channel = _supabase
        .channel('question_edits')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'questions',
          // Filter is limited to a single eq() in Supabase Realtime.
          // We receive all question updates and filter by subject_id locally
          // — this is the most efficient approach given the SDK limitation.
          callback: (payload) => _onQuestionChanged(payload, subjectIds),
        )
        .subscribe();

    debugPrint('[Realtime] subscribed to question edits');
  }

  /// Stop and clean up the Realtime channel.
  Future<void> stop() async {
    if (_channel != null) {
      await _supabase.removeChannel(_channel!);
      _channel = null;
      debugPrint('[Realtime] unsubscribed');
    }
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

      // Only apply if the user has this subject downloaded
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
}
