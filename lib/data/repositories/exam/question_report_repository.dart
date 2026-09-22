import 'package:flutter/foundation.dart';
import 'package:matricmate/features/exam/models/question_report_model.dart';
import 'package:matricmate/utils/constants/app_timeouts.dart';
import 'package:matricmate/utils/exceptions/exception_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuestionReportRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Submits a question report to Supabase.
  /// Prevents duplicate submissions by checking if the user recently reported the same question.
  Future<bool> submitReport(QuestionReportModel report) async {
    try {
      // 1. Check if user already reported this question recently to avoid spam
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
        // User already reported this question; update the comment & reason if provided
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
        return true;
      }

      // 2. Insert new report
      await _supabase
          .from('question_reports')
          .insert(report.toJson())
          .timeout(AppTimeouts.query);

      return true;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[QuestionReportRepository] Submit error: $e\n$st');
      }
      throw AppExceptionHandler.handle(e);
    }
  }
}
