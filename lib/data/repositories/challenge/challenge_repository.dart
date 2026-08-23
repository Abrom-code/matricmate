import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:matricmate/features/challenges/models/challenge_leaderboard_entry.dart';
import 'package:matricmate/features/challenges/models/challenge_model.dart';
import 'package:matricmate/features/challenges/models/challenge_question_model.dart';
import 'package:matricmate/utils/exceptions/app_failure_model.dart';
import 'package:matricmate/utils/network_manager/network_manager.dart';

class ChallengeRepository {
  final _sb = Supabase.instance.client;

  Future<void> _checkConnectivity() async {
    final connected = await NetworkManager.instance.isConnected();
    if (!connected) {
      throw const AppFailure(
        title: 'No Connection',
        message: 'Challenges require an active internet connection.',
      );
    }
  }

  // ── Fetch Visible Challenges for Student ───────────────────────────────────

  /// Fetches challenges that are live, closed, or scheduled within the 12h pre-window.
  Future<List<LeaderboardChallengeModel>> fetchVisibleChallenges({
    String? stream,
  }) async {
    await _checkConnectivity();

    final twelveHoursFromNow =
        DateTime.now().toUtc().add(const Duration(hours: 12)).toIso8601String();

    // Query active/scheduled/closed rounds
    final query = _sb
        .from('leaderboard_challenges')
        .select('*, subjects(name), challenge_question_sets(title)')
        .or('status.in.(live,closed),and(status.eq.scheduled,starts_at.lte.$twelveHoursFromNow)')
        .order('starts_at', ascending: true);

    final rows = await query;
    final list = (rows as List)
        .map((r) => LeaderboardChallengeModel.fromJson(r as Map<String, dynamic>))
        .toList();

    // Filter by stream locally if needed
    if (stream != null && stream.isNotEmpty) {
      final s = stream.toLowerCase();
      return list.where((c) => c.audience == 'both' || c.audience.toLowerCase() == s).toList();
    }
    return list;
  }

  // ── Attempt Flow ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> startAttempt({
    required String challengeId,
    required String userId,
  }) async {
    await _checkConnectivity();

    final res = await _sb.rpc('rpc_start_attempt', params: {
      'p_challenge_id': challengeId,
      'p_user_id': userId,
    });

    if (res is Map<String, dynamic>) {
      final rawQuestions = res['questions'];
      List<ChallengeQuestionModel> questions = [];
      if (rawQuestions is List) {
        questions = rawQuestions
            .map((q) => ChallengeQuestionModel.fromJson(q as Map<String, dynamic>))
            .toList();
      }

      return {
        'attempt_id': res['attempt_id']?.toString() ?? '',
        'challenge_id': res['challenge_id']?.toString() ?? '',
        'title': res['title']?.toString() ?? '',
        'duration_seconds': (res['duration_seconds'] as num?)?.toInt() ?? 3600,
        'started_at': res['started_at'] != null
            ? DateTime.tryParse(res['started_at'].toString())
            : DateTime.now(),
        'ends_at': res['ends_at'] != null
            ? DateTime.tryParse(res['ends_at'].toString())
            : null,
        'questions': questions,
      };
    }

    throw const AppFailure(
      title: 'Error',
      message: 'Failed to initialize challenge attempt.',
    );
  }

  Future<void> submitAnswer({
    required String attemptId,
    required String questionId,
    required String selectedChoice,
  }) async {
    await _checkConnectivity();

    await _sb.rpc('rpc_submit_answer', params: {
      'p_attempt_id': attemptId,
      'p_question_id': questionId,
      'p_selected_choice': selectedChoice,
    });
  }

  Future<Map<String, dynamic>> submitAttempt({
    required String attemptId,
    int? totalTimeSeconds,
  }) async {
    await _checkConnectivity();

    final res = await _sb.rpc('rpc_submit_attempt', params: {
      'p_attempt_id': attemptId,
      if (totalTimeSeconds != null) 'p_total_time_seconds': totalTimeSeconds,
    });

    if (res is Map<String, dynamic>) {
      return res;
    }
    return {'success': true};
  }

  // ── Leaderboards ──────────────────────────────────────────────────────────

  Future<List<ChallengeLeaderboardEntry>> fetchLeaderboard({
    required String challengeId,
    String? stream,
    int limit = 50,
  }) async {
    await _checkConnectivity();

    final res = await _sb.rpc('rpc_get_leaderboard', params: {
      'p_challenge_id': challengeId,
      if (stream != null && stream.isNotEmpty && stream != 'all')
        'p_stream': stream,
      'p_limit': limit,
    });

    if (res is List) {
      return res
          .map((r) => ChallengeLeaderboardEntry.fromJson(r as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<ChallengeLeaderboardEntry>> fetchPeriodLeaderboard({
    required String stream,
    required String period, // 'week' or 'month'
    DateTime? periodStart,
    int limit = 50,
  }) async {
    await _checkConnectivity();

    final res = await _sb.rpc('rpc_get_period_leaderboard', params: {
      'p_stream': stream,
      'p_period': period,
      if (periodStart != null)
        'p_period_start': periodStart.toIso8601String().split('T').first,
      'p_limit': limit,
    });

    if (res is List) {
      return res
          .map((r) => ChallengeLeaderboardEntry.fromJson(r as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // ── Archive & Offline Bundle ──────────────────────────────────────────────

  Future<List<LeaderboardChallengeModel>> fetchClosedChallenges({
    int? subjectId,
    String? stream,
  }) async {
    await _checkConnectivity();

    var query = _sb
        .from('leaderboard_challenges')
        .select('*, subjects(name), challenge_question_sets(title)')
        .inFilter('status', ['closed', 'archived']);

    if (subjectId != null) {
      query = query.eq('subject_id', subjectId);
    }

    final rows = await query.order('ends_at', ascending: false);
    final list = (rows as List)
        .map((r) => LeaderboardChallengeModel.fromJson(r as Map<String, dynamic>))
        .toList();

    if (stream != null && stream.isNotEmpty) {
      final s = stream.toLowerCase();
      return list.where((c) => c.audience == 'both' || c.audience.toLowerCase() == s).toList();
    }
    return list;
  }

  Future<Map<String, dynamic>> fetchChallengeBundle({
    required String challengeId,
    required String userId,
  }) async {
    await _checkConnectivity();

    final res = await _sb.rpc('rpc_get_challenge_bundle', params: {
      'p_challenge_id': challengeId,
      'p_user_id': userId,
    });

    if (res is Map<String, dynamic>) {
      return res;
    }
    throw const AppFailure(
      title: 'Download Failed',
      message: 'Unable to retrieve challenge archive.',
    );
  }
}
