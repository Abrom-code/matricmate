import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/features/challenges/models/challenge_attempt_model.dart';
import 'package:matricmate/features/challenges/models/challenge_leaderboard_entry.dart';
import 'package:matricmate/features/challenges/models/challenge_model.dart';
import 'package:matricmate/features/challenges/models/challenge_question_model.dart';
import 'package:matricmate/features/exam/models/passage_model.dart';
import 'package:matricmate/utils/exceptions/app_failure_model.dart';
import 'package:matricmate/utils/network_manager/network_manager.dart';

class ChallengeRepository {
  final _sb = Supabase.instance.client;

  Future<void> _checkConnectivity() async {
    final hasInterface = await NetworkManager.instance.hasNetworkInterface();
    if (!hasInterface) {
      throw const AppFailure(
        title: 'No Connection',
        message: 'Challenges require an active internet connection.',
      );
    }
  }

  // ── Fetch Visible Challenges for Student ───────────────────────────────────

  /// Fetches all published challenges (live, scheduled, closed, archived).
  Future<List<LeaderboardChallengeModel>> fetchAllChallenges({
    String? stream,
  }) async {
    await _checkConnectivity();

    final rows = await _sb
        .from('leaderboard_challenges')
        .select('*, subjects(name), challenge_questions(id)')
        .inFilter('status', ['live', 'scheduled', 'closed', 'archived'])
        .order('created_at', ascending: false);

    final list = (rows as List)
        .map((r) => LeaderboardChallengeModel.fromJson(r as Map<String, dynamic>))
        .toList();

    if (stream != null && stream.isNotEmpty) {
      final s = stream.toLowerCase().trim();
      return list.where((c) {
        final aud = c.audience.toLowerCase().trim();
        return aud == 'both' || aud == s || aud.isEmpty;
      }).toList();
    }
    return list;
  }

  /// Fetches challenges that are live or scheduled.
  Future<List<LeaderboardChallengeModel>> fetchVisibleChallenges({
    String? stream,
  }) async {
    await _checkConnectivity();

    // Query active and scheduled rounds
    final query = _sb
        .from('leaderboard_challenges')
        .select('*, subjects(name), challenge_questions(id)')
        .inFilter('status', ['live', 'scheduled'])
        .order('starts_at', ascending: true);

    final rows = await query;
    final list = (rows as List)
        .map((r) => LeaderboardChallengeModel.fromJson(r as Map<String, dynamic>))
        .toList();

    // Filter by stream locally if needed
    if (stream != null && stream.isNotEmpty) {
      final s = stream.toLowerCase();
      return list.where((c) => c.audience.toLowerCase().trim() == 'both' || c.audience.toLowerCase().trim() == s.toLowerCase().trim()).toList();
    }
    return list;
  }

  // ── Attempt Flow ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> startAttempt({
    required String challengeId,
    required String userId,
  }) async {
    await _checkConnectivity();

    dynamic res;
    try {
      res = await _sb.rpc('rpc_start_attempt', params: {
        'p_challenge_id': challengeId,
        'p_user_id': userId,
      });
    } catch (e) {
      if (e is PostgrestException &&
          (e.code == '42883' ||
              e.code == 'PGRST202' ||
              e.message.contains('does not exist') ||
              e.message.contains('not found'))) {
        res = await _sb.rpc('rpc_start_challenge_attempt', params: {
          'p_challenge_id': challengeId,
          'p_user_id': userId,
        });
      } else {
        rethrow;
      }
    }

    if (res is Map<String, dynamic>) {
      final rawQuestions = res['questions'];
      final List<ChallengeQuestionModel> questions = [];
      if (rawQuestions is List) {
        for (final item in rawQuestions) {
          if (item is Map<String, dynamic>) {
            final q = ChallengeQuestionModel.fromJson(item);
            if (q.passageId != null && q.passage == null) {
              final p = await getPassage(q.passageId);
              questions.add(q.copyWith(passage: p));
            } else {
              questions.add(q);
            }
          }
        }
      }

      return {
        'attempt_id': res['attempt_id']?.toString() ?? '',
        'challenge_id': res['challenge_id']?.toString() ?? '',
        'title': res['title']?.toString() ?? '',
        'duration_seconds': (res['duration_seconds'] as num?)?.toInt() ?? 3600,
        'started_at': res['started_at'] != null
            ? DateTime.tryParse(res['started_at'].toString())?.toLocal()
            : DateTime.now(),
        'ends_at': res['ends_at'] != null
            ? DateTime.tryParse(res['ends_at'].toString())?.toLocal()
            : null,
        'questions': questions,
      };
    }

    throw const AppFailure(
      title: 'Error',
      message: 'Failed to start challenge attempt',
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

  /// Batch syncs all local user answers to ensure nothing is missed before final submission.
  Future<void> batchSubmitAnswers({
    required String attemptId,
    required Map<String, String> answers,
  }) async {
    if (answers.isEmpty) return;
    try {
      await _checkConnectivity();
      final futures = answers.entries.map((entry) {
        return _sb.rpc('rpc_submit_answer', params: {
          'p_attempt_id': attemptId,
          'p_question_id': entry.key,
          'p_selected_choice': entry.value,
        }).catchError((_) {});
      });
      await Future.wait(futures);
    } catch (_) {}
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

  Future<List<ChallengeQuestionModel>> fetchQuestionsForReview(
    String challengeId, {
    String? setId,
  }) async {
    await _checkConnectivity();

    var query = _sb.from('challenge_questions').select('*');
    if (setId != null && setId.isNotEmpty) {
      query = query.or('challenge_id.eq.$challengeId,set_id.eq.$setId');
    } else {
      query = query.eq('challenge_id', challengeId);
    }
    final rows = await query.order('order_index', ascending: true);

    final list = <ChallengeQuestionModel>[];
    for (final r in rows) {
      final q = ChallengeQuestionModel.fromJson(r);
      if (q.passageId != null && q.passage == null) {
        final p = await getPassage(q.passageId);
        list.add(q.copyWith(passage: p));
      } else {
        list.add(q);
      }
    }
    return list;
  }

  Future<Map<String, dynamic>?> fetchUserAttempt({
    required String challengeId,
    required String userId,
  }) async {
    try {
      await _checkConnectivity();

      final attemptRow = await _sb
          .from('challenge_attempts')
          .select('*')
          .eq('challenge_id', challengeId)
          .eq('user_id', userId)
          .maybeSingle();

      if (attemptRow == null) return null;

      final attemptId = attemptRow['id']?.toString() ?? '';
      final answersRows = await _sb
          .from('challenge_answers')
          .select('question_id, selected_choice, is_correct')
          .eq('attempt_id', attemptId);

      final Map<String, String> userAnswers = {};
      for (final a in answersRows) {
        final qId = a['question_id']?.toString() ?? '';
        final choice = a['selected_choice']?.toString() ?? '';
        if (qId.isNotEmpty) {
          userAnswers[qId] = choice;
        }
      }

      return {
        'attempt': ChallengeAttemptModel.fromJson(attemptRow),
        'user_answers': userAnswers,
      };
    } catch (_) {
      return null;
    }
  }

  // ── Leaderboards ──────────────────────────────────────────────────────────

  Future<List<ChallengeLeaderboardEntry>> fetchLeaderboard({
    required String challengeId,
    String? stream,
    int limit = 50,
  }) async {
    await _checkConnectivity();

    try {
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
    } catch (_) {
      // Fallback: direct query on challenge_attempts
    }

    try {
      var query = _sb
          .from('challenge_attempts')
          .select('*, users(first_name, last_name)')
          .eq('challenge_id', challengeId)
          .eq('status', 'submitted');

      if (stream != null && stream.isNotEmpty && stream != 'all') {
        query = query.eq('stream', stream);
      }

      final rows = await query
          .order('score', ascending: false)
          .order('total_time_seconds', ascending: true)
          .order('submitted_at', ascending: true)
          .limit(limit);

      final list = <ChallengeLeaderboardEntry>[];
      for (int i = 0; i < rows.length; i++) {
        final r = rows[i];
        final user = r['users'] as Map<String, dynamic>? ?? {};
        final sc = (r['score'] as num?)?.toInt() ?? 0;
        list.add(ChallengeLeaderboardEntry(
          rank: i + 1,
          userId: r['user_id']?.toString() ?? '',
          firstName: user['first_name']?.toString() ?? 'Student',
          lastName: user['last_name']?.toString() ?? '',
          stream: r['stream']?.toString() ?? '',
          score: sc,
          totalTimeSeconds: (r['total_time_seconds'] as num?)?.toInt() ?? 0,
          correctCount: sc,
          incorrectCount: (r['incorrect_count'] as num?)?.toInt() ?? 0,
          notDoneCount: (r['not_done_count'] as num?)?.toInt() ?? 0,
          challengesTaken: 1,
        ));
      }
      return list;
    } catch (_) {}

    return [];
  }

  Future<List<ChallengeLeaderboardEntry>> fetchPeriodLeaderboard({
    required String stream,
    required String period, // 'week' or 'month'
    DateTime? periodStart,
    int limit = 100,
  }) async {
    await _checkConnectivity();

    // 1. Try RPC first
    try {
      final res = await _sb.rpc('rpc_get_period_leaderboard', params: {
        'p_stream': (stream.isEmpty || stream == 'all') ? 'all' : stream,
        'p_period': period,
        if (periodStart != null)
          'p_period_start': periodStart.toIso8601String().split('T').first,
        'p_limit': limit,
      });

      if (res is List && res.isNotEmpty) {
        return res
            .map((r) => ChallengeLeaderboardEntry.fromJson(r as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}

    // 2. Direct aggregation from challenge_attempts (100% resilient fallback)
    try {
      final now = DateTime.now();
      DateTime startDate;
      if (periodStart != null) {
        startDate = periodStart;
      } else if (period == 'week') {
        final daysFromMon = (now.weekday - 1);
        startDate = DateTime(now.year, now.month, now.day - daysFromMon);
      } else {
        startDate = DateTime(now.year, now.month, 1);
      }

      var query = _sb
          .from('challenge_attempts')
          .select('*, users(first_name, last_name)')
          .eq('status', 'submitted');

      if (stream.isNotEmpty && stream != 'all') {
        query = query.eq('stream', stream);
      }

      final rows = await query.order('submitted_at', ascending: false);

      final userMap = <String, Map<String, dynamic>>{};
      for (final r in rows) {
        final userId = r['user_id']?.toString() ?? '';
        if (userId.isEmpty) continue;

        final submittedAtStr = r['submitted_at']?.toString();
        if (submittedAtStr != null) {
          final submittedAt = DateTime.tryParse(submittedAtStr);
          if (submittedAt != null && submittedAt.isBefore(startDate)) {
            continue;
          }
        }

        final user = r['users'] as Map<String, dynamic>? ?? {};
        final score = (r['score'] as num?)?.toInt() ?? 0;
        final timeSec = (r['total_time_seconds'] as num?)?.toInt() ?? 0;
        final st = r['stream']?.toString() ?? stream;

        if (!userMap.containsKey(userId)) {
          userMap[userId] = {
            'user_id': userId,
            'first_name': user['first_name']?.toString() ?? 'Student',
            'last_name': user['last_name']?.toString() ?? '',
            'stream': st,
            'total_score': score,
            'total_time_seconds': timeSec,
            'challenges_taken': 1,
          };
        } else {
          final existing = userMap[userId]!;
          existing['total_score'] = (existing['total_score'] as int) + score;
          existing['total_time_seconds'] = (existing['total_time_seconds'] as int) + timeSec;
          existing['challenges_taken'] = (existing['challenges_taken'] as int) + 1;
        }
      }

      // If userMap is empty, include all submitted attempts to display available records
      if (userMap.isEmpty && rows.isNotEmpty) {
        for (final r in rows) {
          final userId = r['user_id']?.toString() ?? '';
          if (userId.isEmpty) continue;

          final user = r['users'] as Map<String, dynamic>? ?? {};
          final score = (r['score'] as num?)?.toInt() ?? 0;
          final timeSec = (r['total_time_seconds'] as num?)?.toInt() ?? 0;
          final st = r['stream']?.toString() ?? stream;

          if (!userMap.containsKey(userId)) {
            userMap[userId] = {
              'user_id': userId,
              'first_name': user['first_name']?.toString() ?? 'Student',
              'last_name': user['last_name']?.toString() ?? '',
              'stream': st,
              'total_score': score,
              'total_time_seconds': timeSec,
              'challenges_taken': 1,
            };
          } else {
            final existing = userMap[userId]!;
            existing['total_score'] = (existing['total_score'] as int) + score;
            existing['total_time_seconds'] = (existing['total_time_seconds'] as int) + timeSec;
            existing['challenges_taken'] = (existing['challenges_taken'] as int) + 1;
          }
        }
      }

      final sortedList = userMap.values.toList()
        ..sort((a, b) {
          final scoreComp = (b['total_score'] as int).compareTo(a['total_score'] as int);
          if (scoreComp != 0) return scoreComp;
          return (a['total_time_seconds'] as int).compareTo(b['total_time_seconds'] as int);
        });

      final result = <ChallengeLeaderboardEntry>[];
      for (int i = 0; i < sortedList.length && i < limit; i++) {
        final item = sortedList[i];
        result.add(ChallengeLeaderboardEntry(
          rank: i + 1,
          userId: item['user_id'] as String,
          firstName: item['first_name'] as String,
          lastName: item['last_name'] as String,
          stream: item['stream'] as String,
          score: item['total_score'] as int,
          totalTimeSeconds: item['total_time_seconds'] as int,
          correctCount: item['total_score'] as int,
          challengesTaken: item['challenges_taken'] as int,
          periodStart: startDate.toIso8601String().split('T').first,
        ));
      }

      return result;
    } catch (_) {}

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
        .select('*, subjects(name), challenge_questions(id)')
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
      return list.where((c) => c.audience.toLowerCase().trim() == 'both' || c.audience.toLowerCase().trim() == s.toLowerCase().trim()).toList();
    }
    return list;
  }

  /// Fetches challenges of ALL statuses across all subjects or a specific subject (used by archive/list screen).
  Future<List<LeaderboardChallengeModel>> fetchAllSubjectChallenges({
    int? subjectId,
    String? stream,
  }) async {
    await _checkConnectivity();

    var query = _sb
        .from('leaderboard_challenges')
        .select('*, subjects(name), challenge_questions(id)')
        .inFilter('status', ['live', 'scheduled', 'closed', 'archived']);

    if (subjectId != null) {
      query = query.eq('subject_id', subjectId);
    }

    final rows = await query.order('created_at', ascending: false);
    final list = (rows as List)
        .map((r) => LeaderboardChallengeModel.fromJson(r as Map<String, dynamic>))
        .toList();

    if (stream != null && stream.isNotEmpty) {
      final s = stream.toLowerCase();
      return list.where((c) => c.audience.toLowerCase().trim() == 'both' || c.audience.toLowerCase().trim() == s.toLowerCase().trim()).toList();
    }
    return list;
  }

  /// Fetches challenges of ALL statuses for a specific subject (used by archive/list screen).
  Future<List<LeaderboardChallengeModel>> fetchSubjectChallenges({
    required int subjectId,
    String? stream,
  }) => fetchAllSubjectChallenges(subjectId: subjectId, stream: stream);

  final Map<int, PassageModel> _passageCache = {};

  Future<PassageModel?> getPassage(int? passageId) async {
    if (passageId == null) return null;
    if (_passageCache.containsKey(passageId)) return _passageCache[passageId];

    // 1. Try local SQLite
    try {
      final local = await DatabaseService.instance.getPassage(passageId);
      if (local.id != -1 && local.content.isNotEmpty && local.content != 'No passage found') {
        _passageCache[passageId] = local;
        return local;
      }
    } catch (_) {}

    // 2. Try Supabase
    try {
      final row = await _sb.from('passages').select().eq('id', passageId).maybeSingle();
      if (row != null) {
        final p = PassageModel.fromJson(row);
        _passageCache[passageId] = p;
        try {
          await DatabaseService.instance.insetData('passages', p.toMap());
        } catch (_) {}
        return p;
      }
    } catch (_) {}

    return null;
  }

  Future<Map<String, dynamic>> fetchChallengeBundle({
    required String challengeId,
    required String userId,
  }) async {
    await _checkConnectivity();

    final chRow = await _sb
        .from('leaderboard_challenges')
        .select('*, subjects(name)')
        .eq('id', challengeId)
        .single();

    final qRows = await _sb
        .from('challenge_questions')
        .select('*')
        .eq('challenge_id', challengeId)
        .order('order_index', ascending: true);

    final questionsList = <Map<String, dynamic>>[];
    for (final rawQ in qRows) {
      final qMap = Map<String, dynamic>.from(rawQ);
      final pId = (qMap['passage_id'] as num?)?.toInt();
      if (pId != null) {
        final p = await getPassage(pId);
        if (p != null) {
          qMap['passage'] = p.toMap();
        }
      }
      questionsList.add(qMap);
    }

    return {
      'id': chRow['id']?.toString() ?? '',
      'challenge_id': chRow['id']?.toString() ?? '',
      'set_id': chRow['set_id']?.toString() ?? challengeId,
      'subject_id': (chRow['subject_id'] as num?)?.toInt() ?? 0,
      'title': chRow['title']?.toString() ?? 'Challenge',
      'audience': chRow['audience']?.toString() ?? 'both',
      'questions': questionsList,
    };
  }

  Future<Set<String>> fetchUserSubmittedChallengeIds(String userId) async {
    try {
      final rows = await _sb
          .from('challenge_attempts')
          .select('challenge_id')
          .eq('user_id', userId)
          .eq('status', 'submitted');
      return rows
          .map((r) => r['challenge_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
    } catch (_) {
      return {};
    }
  }

  Future<Set<String>> fetchUserInProgressChallengeIds(String userId) async {
    try {
      final rows = await _sb
          .from('challenge_attempts')
          .select('challenge_id')
          .eq('user_id', userId)
          .eq('status', 'in_progress');
      return rows
          .map((r) => r['challenge_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> deleteChallengeAttempt({
    required String challengeId,
    required String userId,
  }) async {
    try {
      await _sb
          .from('challenge_attempts')
          .delete()
          .eq('challenge_id', challengeId)
          .eq('user_id', userId);
    } catch (_) {
      // Best-effort if offline or RLS restrictions
    }
  }
}
