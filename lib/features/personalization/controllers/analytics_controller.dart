import 'dart:convert';
import 'package:get/get.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/data/repositories/user/user_repository.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';

// ── Data classes ──────────────────────────────────────────────────────────────

class SubjectStat {
  final String name;
  final double avgScore;
  final int? subjectId;
  final int testsCount;

  SubjectStat({
    required this.name,
    required this.avgScore,
    this.subjectId,
    this.testsCount = 0,
  });
}

class ChapterStat {
  final String title;
  final double? score;
  final int? chapterId;
  final int? subjectId;
  final String? subjectName;
  final int? grade;

  ChapterStat({
    required this.title,
    required this.score,
    this.chapterId,
    this.subjectId,
    this.subjectName,
    this.grade,
  });
}

class TrendPoint {
  final int index;
  final double score;
  TrendPoint({required this.index, required this.score});
}

class SubjectNotesStat {
  final int subjectId;
  final String subjectName;
  final int completedNotes;
  final int totalNotes;
  final int downloadedNotes;

  double get progressPct =>
      totalNotes > 0 ? (completedNotes / totalNotes * 100) : 0.0;

  SubjectNotesStat({
    required this.subjectId,
    required this.subjectName,
    required this.completedNotes,
    required this.totalNotes,
    required this.downloadedNotes,
  });
}

class GradeNotesStat {
  final int grade;
  final int completedNotes;
  final int totalNotes;

  double get progressPct =>
      totalNotes > 0 ? (completedNotes / totalNotes * 100) : 0.0;

  GradeNotesStat({
    required this.grade,
    required this.completedNotes,
    required this.totalNotes,
  });
}

class WeakChapterStat {
  final int? chapterId;
  final String chapterTitle;
  final int chapterNumber;
  final int grade;
  final int? subjectId;
  final String subjectName;
  final double avgScore;
  final int testsTaken;
  final bool hasNoteCompleted;
  final int? noteId;

  WeakChapterStat({
    this.chapterId,
    required this.chapterTitle,
    this.chapterNumber = 1,
    this.grade = 9,
    this.subjectId,
    required this.subjectName,
    required this.avgScore,
    required this.testsTaken,
    this.hasNoteCompleted = false,
    this.noteId,
  });
}

enum RecommendationType {
  readNote,
  practiceChapter,
  practiceSubject,
  explore,
  exploreNotes,
}

class StudyRecommendation {
  final String id;
  final String title;
  final String subtitle;
  final String subjectName;
  final int? subjectId;
  final RecommendationType type;
  final int? targetId;
  final String badgeText;

  StudyRecommendation({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.subjectName,
    this.subjectId,
    required this.type,
    this.targetId,
    required this.badgeText,
  });
}

class _ChapterScoreAgg {
  final int chapterId;
  final String chapterTitle;
  final int chapterNumber;
  final int grade;
  final int? subjectId;
  final String subjectName;
  final int correct;
  final int total;
  final int? noteId;
  final bool noteCompleted;

  _ChapterScoreAgg({
    required this.chapterId,
    required this.chapterTitle,
    required this.chapterNumber,
    required this.grade,
    this.subjectId,
    required this.subjectName,
    required this.correct,
    required this.total,
    this.noteId,
    required this.noteCompleted,
  });
}

// ── Filter & Navigation enums ─────────────────────────────────────────────────

enum AnalyticsTab { overview, notes, tests }

enum TimeFilter { all, lastWeek, lastMonth, last3Months }

enum GradeFilter { all, grade9, grade10, grade11, grade12 }

enum StreamFilter { all, natural, social, common }

enum ScoreFilter { all, poor, average, good }

enum TimedFilter { all, timedOnly, untimeOnly }

// ── Controller ────────────────────────────────────────────────────────────────

class AnalyticsController extends GetxController {
  static AnalyticsController get instance => Get.find();

  AnalyticsController({DatabaseService? databaseService})
    : _db = databaseService ?? DatabaseService.instance;

  final DatabaseService _db;

  final isLoading = true.obs;
  final isRefreshing = false.obs;

  // ── Tab selection ────────────────────────────────────────────────────────
  final selectedTab = AnalyticsTab.overview.obs;

  void switchTab(AnalyticsTab tab) {
    selectedTab.value = tab;
  }

  // ── Filter selections ────────────────────────────────────────────────────

  final selectedSubject = Rx<String>('All Subjects');
  final selectedTestType = Rx<String>('All Types');
  final selectedTimeFilter = TimeFilter.all.obs;
  final selectedGrade = GradeFilter.all.obs;
  final selectedStream = StreamFilter.all.obs;
  final selectedScore = ScoreFilter.all.obs;
  final selectedTimed = TimedFilter.all.obs;

  // ── Available option lists ───────────────────────────────────────────────

  final availableSubjects = <String>[].obs;
  final availableTestTypes = <String>[
    'All Categories',
    'Entrance Exam',
    'Model Exam',
    'Chapter Test',
    'Grade Exam',
  ].obs;

  // ── Output data ──────────────────────────────────────────────────────────

  final testsCompleted = 0.obs;
  final avgScorePct = 0.0.obs;
  final totalCorrect = 0.obs;
  final bookmarkCount = 0.obs;

  final trendPoints = <TrendPoint>[].obs;
  final subjectStats = <SubjectStat>[].obs;
  final typeDistribution = <String, double>{}.obs;
  final chapterStats = <ChapterStat>[].obs;

  // ── Challenge Analytics Observables ────────────────────────────────────────
  final totalChallengesTaken = 0.obs;
  final challengesThisWeek = 0.obs;
  final challengesThisMonth = 0.obs;
  final challengeAvgScorePct = 0.0.obs;
  final challengeTotalTimeSeconds = 0.obs;

  // ── Notes Analytics Observables ───────────────────────────────────────────
  final totalNotesCount = 0.obs;
  final completedNotesCount = 0.obs;
  final downloadedNotesCount = 0.obs;
  final subjectNotesStats = <SubjectNotesStat>[].obs;
  final gradeNotesStats = <GradeNotesStat>[].obs;

  // ── Weakness & Recommendation Observables ─────────────────────────────────
  final weakestAreas = <SubjectStat>[].obs;
  final strongestAreas = <SubjectStat>[].obs;
  final weakestChapters = <WeakChapterStat>[].obs;
  final recommendations = <StudyRecommendation>[].obs;

  /// Holistic Readiness score combining test mastery, notes syllabus completion, and consistency
  double get holisticReadiness {
    final tests = testsCompleted.value;
    final avg = avgScorePct.value;
    final notesTot = totalNotesCount.value;
    final notesComp = completedNotesCount.value;

    if (tests == 0 && notesComp == 0) return 0.0;

    final testScorePart = avg * 0.55;
    final notesPart = notesTot > 0 ? (notesComp / notesTot * 100) * 0.35 : 0.0;
    final volumeBonus = ((tests * 1.5) + (notesComp * 1.0)).clamp(0.0, 10.0);

    return (testScorePart + notesPart + volumeBonus).clamp(0.0, 100.0);
  }

  String get formattedChallengeTime {
    final secs = challengeTotalTimeSeconds.value;
    if (secs == 0) return '0m';
    final mins = secs ~/ 60;
    final hrs = mins ~/ 60;
    final remMins = mins % 60;
    if (hrs > 0) {
      return '${hrs}h ${remMins}m';
    }
    return '${mins}m';
  }

  @override
  void onInit() {
    super.onInit();
    _initFilterOptions();
    loadAll();
    ever(UserController.instance.user, (_) {
      _initFilterOptions();
      loadAll();
    });
  }

  // ── Populate filter option lists ─────────────────────────────────────────

  Future<void> _initFilterOptions() async {
    final db = await _db.database;
    final userStream = UserController.instance.user.value.stream.toLowerCase();

    String streamCondition = '';
    if (userStream == 'natural') {
      streamCondition = 'WHERE (is_natural = 1 OR is_common = 1)';
    } else if (userStream == 'social') {
      streamCondition = 'WHERE (is_natural = 0 OR is_common = 1)';
    }

    final subjectRows = await db.rawQuery('''
      SELECT DISTINCT name FROM subjects
      $streamCondition
      ORDER BY name
    ''');

    availableSubjects.value = [
      'All Subjects',
      ...subjectRows.map((r) => r['name'] as String),
    ];
  }

  String _normalizeTestType(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('entrance')) return 'entrance';
    if (lower.contains('model')) return 'model';
    if (lower.contains('chapter')) return 'chapter';
    if (lower.contains('grade')) return 'grade';
    return lower;
  }

  // ── Build SQL WHERE clause from all active filters ───────────────────────

  String _buildWhere(String userId) {
    final parts = <String>[
      '(r.user_id = ? OR r.user_id = \'\' OR r.user_id IS NULL)',
      '(r.isCompleted = 1 OR r.isCompleted IS NULL)',
    ];

    // Automatic Profile Stream filtering
    final userStream = UserController.instance.user.value.stream.toLowerCase();
    if (userStream == 'natural') {
      parts.add('(s.is_natural = 1 OR s.is_common = 1)');
    } else if (userStream == 'social') {
      parts.add('(s.is_natural = 0 OR s.is_common = 1)');
    }

    // Subject
    if (selectedSubject.value != 'All Subjects') {
      parts.add("s.name = '${selectedSubject.value}'");
    }

    // Test Category
    if (selectedTestType.value != 'All Types' &&
        selectedTestType.value != 'All Categories') {
      final type = _normalizeTestType(selectedTestType.value);
      parts.add("t.type = '$type'");
    }

    // Timed format
    switch (selectedTimed.value) {
      case TimedFilter.timedOnly:
        parts.add('t.time != -1');
        break;
      case TimedFilter.untimeOnly:
        parts.add('t.time = -1');
        break;
      case TimedFilter.all:
        break;
    }

    // Time period
    if (selectedTimeFilter.value != TimeFilter.all) {
      final cutoff = _cutoffDate(selectedTimeFilter.value);
      parts.add(
        "(r.completed_at IS NULL OR r.completed_at = '' OR r.completed_at >= '${cutoff.toIso8601String()}')",
      );
    }

    return parts.join(' AND ');
  }

  // Score filter is applied in Dart after fetching (requires decoding JSON)
  bool _passesScoreFilter(int correct, int total) {
    if (selectedScore.value == ScoreFilter.all || total == 0) return true;
    final pct = correct / total * 100;
    switch (selectedScore.value) {
      case ScoreFilter.poor:
        return pct < 50;
      case ScoreFilter.average:
        return pct >= 50 && pct < 70;
      case ScoreFilter.good:
        return pct >= 70;
      case ScoreFilter.all:
        return true;
    }
  }

  DateTime _cutoffDate(TimeFilter f) {
    final now = DateTime.now();
    switch (f) {
      case TimeFilter.lastWeek:
        return now.subtract(const Duration(days: 7));
      case TimeFilter.lastMonth:
        return now.subtract(const Duration(days: 30));
      case TimeFilter.last3Months:
        return now.subtract(const Duration(days: 90));
      case TimeFilter.all:
        return DateTime(2000);
    }
  }

  // ── Public filter API ────────────────────────────────────────────────────

  void applyFilters({
    String? subject,
    String? testType,
    TimeFilter? timeFilter,
    GradeFilter? grade,
    StreamFilter? stream,
    ScoreFilter? score,
    TimedFilter? timed,
  }) {
    if (subject != null) selectedSubject.value = subject;
    if (testType != null) selectedTestType.value = testType;
    if (timeFilter != null) selectedTimeFilter.value = timeFilter;
    if (grade != null) selectedGrade.value = grade;
    if (stream != null) selectedStream.value = stream;
    if (score != null) selectedScore.value = score;
    if (timed != null) selectedTimed.value = timed;
    loadAll();
  }

  void resetFilters() {
    selectedSubject.value = 'All Subjects';
    selectedTestType.value = 'All Categories';
    selectedTimeFilter.value = TimeFilter.all;
    selectedGrade.value = GradeFilter.all;
    selectedStream.value = StreamFilter.all;
    selectedScore.value = ScoreFilter.all;
    selectedTimed.value = TimedFilter.all;
    loadAll();
  }

  int get activeFilterCount {
    int count = 0;
    if (selectedSubject.value != 'All Subjects') count++;
    if (selectedTestType.value != 'All Types' &&
        selectedTestType.value != 'All Categories') {
      count++;
    }
    if (selectedTimeFilter.value != TimeFilter.all) count++;
    if (selectedGrade.value != GradeFilter.all) count++;
    if (selectedStream.value != StreamFilter.all) count++;
    if (selectedTimed.value != TimedFilter.all) count++;
    if (selectedScore.value != ScoreFilter.all) count++;
    return count;
  }

  bool get hasActiveFilters => activeFilterCount > 0;

  // ── Load all data ────────────────────────────────────────────────────────

  Future<void> loadAll({bool isManualRefresh = false}) async {
    if (isRefreshing.value) return;
    isRefreshing.value = true;

    // Reset filters on manual refresh so user gets a clean, full overview
    if (isManualRefresh) {
      selectedSubject.value = 'All Subjects';
      selectedTestType.value = 'All Categories';
      selectedTimed.value = TimedFilter.all;
      selectedScore.value = ScoreFilter.all;
      selectedGrade.value = GradeFilter.all;
      selectedStream.value = StreamFilter.all;
    }

    // Only show full blocking loader if we have zero data loaded yet
    if (testsCompleted.value == 0 && totalNotesCount.value == 0) {
      isLoading.value = true;
    }

    final startTime = DateTime.now();

    try {
      await _initFilterOptions();

      var userId = UserController.instance.user.value.id;
      if (userId.isEmpty) {
        final local = await UserRepository().getLocalUser();
        if (local != null && local.id.isNotEmpty) {
          userId = local.id;
          UserController.instance.user.value = local;
        }
      }
      if (userId.isEmpty) {
        final db = await _db.database;
        final userRows = await db.query('user', limit: 1);
        if (userRows.isNotEmpty) {
          userId = userRows.first['id']?.toString() ?? '';
        }
      }
      if (userId.isEmpty) {
        final db = await _db.database;
        final resRows = await db.rawQuery(
          'SELECT user_id FROM results WHERE user_id IS NOT NULL AND user_id != "" LIMIT 1',
        );
        if (resRows.isNotEmpty) {
          userId = resRows.first['user_id']?.toString() ?? '';
        }
      }

      await Future.wait([
        _loadSummary(userId),
        _loadTrend(userId),
        _loadSubjectPerformance(userId),
        _loadTypeDistribution(userId),
        _loadChapterProgress(userId),
        _loadBookmarkCount(userId),
        _loadChallengeAnalytics(userId),
        _loadNotesAnalytics(userId),
      ]);

      await _loadWeaknessAndRecommendations(userId);

      if (isManualRefresh) {
        final elapsed = DateTime.now().difference(startTime).inMilliseconds;
        if (elapsed < 500) {
          await Future.delayed(Duration(milliseconds: 500 - elapsed));
        }
      }
    } catch (_) {
      // Ignore background errors
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  // ── Private loaders ──────────────────────────────────────────────────────

  Future<void> _loadSummary(String userId) async {
    try {
      final db = await _db.database;
      final where = _buildWhere(userId);

      final rows = await db.rawQuery(
        '''
        SELECT r.correctAnswers, r.testQuestions
        FROM results r
        JOIN tests t ON r.test_id = t.id
        JOIN subjects s ON t.subject_id = s.id
        WHERE $where
      ''',
        [userId],
      );

      int correct = 0, total = 0;
      int count = 0;

      for (final row in rows) {
        final c = row['correctAnswers'] as int? ?? 0;
        int tot = 1;
        try {
          final list = jsonDecode(row['testQuestions'] as String) as List;
          tot = list.isNotEmpty ? list.length : 1;
        } catch (_) {}
        if (!_passesScoreFilter(c, tot)) continue;
        correct += c;
        total += tot;
        count++;
      }

      testsCompleted.value = count;
      totalCorrect.value = correct;
      avgScorePct.value = total > 0 ? correct / total * 100 : 0.0;
    } catch (_) {}
  }

  Future<void> _loadTrend(String userId) async {
    try {
      final db = await _db.database;
      final where = _buildWhere(userId);

      final rows = await db.rawQuery(
        '''
        SELECT r.correctAnswers, r.testQuestions
        FROM results r
        JOIN tests t ON r.test_id = t.id
        JOIN subjects s ON t.subject_id = s.id
        WHERE $where
        ORDER BY r.id DESC
        LIMIT 10
      ''',
        [userId],
      );

      final points = <TrendPoint>[];
      final reversed = rows.reversed.toList();
      for (int i = 0; i < reversed.length; i++) {
        final row = reversed[i];
        final correct = row['correctAnswers'] as int? ?? 0;
        int total = 1;
        try {
          final list = jsonDecode(row['testQuestions'] as String) as List;
          total = list.isNotEmpty ? list.length : 1;
        } catch (_) {}
        if (!_passesScoreFilter(correct, total)) continue;
        points.add(TrendPoint(index: i, score: correct / total * 100));
      }
      trendPoints.value = points;
    } catch (_) {
      trendPoints.clear();
    }
  }

  Future<void> _loadSubjectPerformance(String userId) async {
    try {
      final db = await _db.database;
      final where = _buildWhere(userId);

      final rows = await db.rawQuery(
        '''
        SELECT s.id as subject_id, s.name, r.correctAnswers, r.testQuestions
        FROM results r
        JOIN tests t ON r.test_id = t.id
        JOIN subjects s ON t.subject_id = s.id
        WHERE $where
      ''',
        [userId],
      );

      final Map<String, List<num>> bySubject = {}; // [correct, total, count, subjectId]
      for (final row in rows) {
        final name = row['name'] as String;
        final subId = (row['subject_id'] as num?)?.toInt() ?? 0;
        final correct = row['correctAnswers'] as int? ?? 0;
        int total = 1;
        try {
          final list = jsonDecode(row['testQuestions'] as String) as List;
          total = list.isNotEmpty ? list.length : 1;
        } catch (_) {}
        if (!_passesScoreFilter(correct, total)) continue;
        bySubject.putIfAbsent(name, () => [0, 0, 0, subId]);
        bySubject[name]![0] += correct;
        bySubject[name]![1] += total;
        bySubject[name]![2] += 1;
      }

      final stats = bySubject.entries.map((e) {
        final pct = e.value[1] > 0 ? (e.value[0] / e.value[1] * 100).toDouble() : 0.0;
        return SubjectStat(
          name: e.key,
          avgScore: pct,
          subjectId: e.value[3].toInt(),
          testsCount: e.value[2].toInt(),
        );
      }).toList()..sort((a, b) => b.avgScore.compareTo(a.avgScore));

      subjectStats.value = stats;
      _updateSubjectWeakness(stats);
    } catch (_) {
      subjectStats.clear();
      weakestAreas.clear();
      strongestAreas.clear();
    }
  }

  void _updateSubjectWeakness(List<SubjectStat> stats) {
    if (stats.isNotEmpty) {
      final sorted = [...stats]
        ..sort((a, b) => a.avgScore.compareTo(b.avgScore));
      final weak = sorted.where((s) => s.avgScore < 75).take(3).toList();
      if (weak.isNotEmpty) {
        weakestAreas.value = weak;
      } else {
        weakestAreas.value = [sorted.first];
      }
      strongestAreas.value = sorted.reversed.where((s) => s.avgScore >= 60).take(2).toList();
    } else {
      weakestAreas.clear();
      strongestAreas.clear();
    }
  }

  Future<void> _loadTypeDistribution(String userId) async {
    try {
      final db = await _db.database;
      final where = _buildWhere(userId);

      final rows = await db.rawQuery(
        '''
        SELECT t.type, r.correctAnswers, r.testQuestions
        FROM results r
        JOIN tests t ON r.test_id = t.id
        JOIN subjects s ON t.subject_id = s.id
        WHERE $where
      ''',
        [userId],
      );

      final Map<String, int> counts = {};
      for (final row in rows) {
        final correct = row['correctAnswers'] as int? ?? 0;
        int total = 1;
        try {
          final list = jsonDecode(row['testQuestions'] as String) as List;
          total = list.isNotEmpty ? list.length : 1;
        } catch (_) {}
        if (!_passesScoreFilter(correct, total)) continue;
        final type = (row['type'] as String?) ?? 'unknown';
        counts[type] = (counts[type] ?? 0) + 1;
      }

      final grand = counts.values.fold(0, (a, b) => a + b);
      final Map<String, double> dist = {};
      for (final e in counts.entries) {
        dist[e.key] = grand > 0 ? e.value / grand * 100 : 0;
      }
      typeDistribution.value = dist;
    } catch (_) {
      typeDistribution.clear();
    }
  }

  Future<void> _loadChapterProgress(String userId) async {
    try {
      final db = await _db.database;

      final parts = <String>['r.user_id = ?'];

      if (selectedSubject.value != 'All Subjects') {
        parts.add("s.name = '${selectedSubject.value}'");
      }
      switch (selectedGrade.value) {
        case GradeFilter.grade9:
          parts.add('t.grade = 9');
          break;
        case GradeFilter.grade10:
          parts.add('t.grade = 10');
          break;
        case GradeFilter.grade11:
          parts.add('t.grade = 11');
          break;
        case GradeFilter.grade12:
          parts.add('t.grade = 12');
          break;
        case GradeFilter.all:
          break;
      }
      switch (selectedStream.value) {
        case StreamFilter.natural:
          parts.add('s.is_natural = 1 AND s.is_common = 0');
          break;
        case StreamFilter.social:
          parts.add('s.is_natural = 0 AND s.is_common = 0');
          break;
        case StreamFilter.common:
          parts.add('s.is_common = 1');
          break;
        case StreamFilter.all:
          break;
      }

      final chapterWhere = parts.join(' AND ');

      final rows = await db.rawQuery(
        '''
        SELECT c.id as chapter_id, c.title, c.grade, s.id as subject_id, s.name as subject_name,
               r.correctAnswers, r.testQuestions
        FROM chapters c
        LEFT JOIN tests t ON t.chapter_id = c.id
        LEFT JOIN subjects s ON t.subject_id = s.id
        LEFT JOIN results r ON r.test_id = t.id AND r.user_id = ?
        WHERE c.id IN (SELECT DISTINCT chapter_id FROM tests WHERE chapter_id IS NOT NULL)
          AND ($chapterWhere)
        GROUP BY c.id
        ORDER BY r.correctAnswers DESC
        LIMIT 15
      ''',
        [userId, userId],
      );

      chapterStats.value = rows.map((row) {
        final title = row['title'] as String? ?? '';
        final correct = row['correctAnswers'] as int?;
        double? score;
        if (correct != null) {
          int total = 1;
          try {
            final list = jsonDecode(row['testQuestions'] as String) as List;
            total = list.isNotEmpty ? list.length : 1;
          } catch (_) {}
          score = correct / total * 100;
        }
        return ChapterStat(
          title: title,
          score: score,
          chapterId: (row['chapter_id'] as num?)?.toInt(),
          subjectId: (row['subject_id'] as num?)?.toInt(),
          subjectName: row['subject_name']?.toString(),
          grade: (row['grade'] as num?)?.toInt(),
        );
      }).toList();
    } catch (_) {
      chapterStats.clear();
    }
  }

  Future<void> _loadNotesAnalytics(String userId) async {
    final db = await _db.database;
    try {
      final userStream = UserController.instance.user.value.stream.toLowerCase();
      final whereParts = <String>[];
      if (userStream == 'natural') {
        whereParts.add('(s.is_natural = 1 OR s.is_common = 1)');
      } else if (userStream == 'social') {
        whereParts.add('(s.is_natural = 0 OR s.is_common = 1)');
      }

      if (selectedSubject.value != 'All Subjects') {
        whereParts.add("s.name = '${selectedSubject.value}'");
      }

      final whereClause = whereParts.isNotEmpty ? 'WHERE ${whereParts.join(' AND ')}' : '';

      // 1. Overall counts
      final totalRows = await db.rawQuery('''
        SELECT 
          COUNT(n.id) as total_count,
          SUM(CASE WHEN n.is_completed = 1 THEN 1 ELSE 0 END) as completed_count,
          SUM(CASE WHEN n.is_downloaded = 1 THEN 1 ELSE 0 END) as downloaded_count
        FROM notes n
        JOIN subjects s ON n.subject_id = s.id
        $whereClause
      ''');

      if (totalRows.isNotEmpty) {
        final r = totalRows.first;
        totalNotesCount.value = (r['total_count'] as num?)?.toInt() ?? 0;
        completedNotesCount.value = (r['completed_count'] as num?)?.toInt() ?? 0;
        downloadedNotesCount.value = (r['downloaded_count'] as num?)?.toInt() ?? 0;
      } else {
        totalNotesCount.value = 0;
        completedNotesCount.value = 0;
        downloadedNotesCount.value = 0;
      }

      // 2. Subject breakdown
      final streamWhere = (userStream == 'natural')
          ? 'WHERE (s.is_natural = 1 OR s.is_common = 1)'
          : (userStream == 'social')
              ? 'WHERE (s.is_natural = 0 OR s.is_common = 1)'
              : '';

      final subjectRows = await db.rawQuery('''
        SELECT 
          s.id as subject_id,
          s.name as subject_name,
          COUNT(n.id) as total_notes,
          SUM(CASE WHEN n.is_completed = 1 THEN 1 ELSE 0 END) as completed_notes,
          SUM(CASE WHEN n.is_downloaded = 1 THEN 1 ELSE 0 END) as downloaded_notes
        FROM subjects s
        LEFT JOIN notes n ON n.subject_id = s.id
        $streamWhere
        GROUP BY s.id, s.name
        ORDER BY completed_notes DESC, total_notes DESC, s.name ASC
      ''');

      subjectNotesStats.value = subjectRows.map((r) {
        return SubjectNotesStat(
          subjectId: (r['subject_id'] as num?)?.toInt() ?? 0,
          subjectName: r['subject_name']?.toString() ?? 'Subject',
          completedNotes: (r['completed_notes'] as num?)?.toInt() ?? 0,
          totalNotes: (r['total_notes'] as num?)?.toInt() ?? 0,
          downloadedNotes: (r['downloaded_notes'] as num?)?.toInt() ?? 0,
        );
      }).toList();

      // 3. Grade breakdown
      final gradeWhereParts = <String>['n.grade IN (9, 10, 11, 12)'];
      if (userStream == 'natural') {
        gradeWhereParts.add('(s.is_natural = 1 OR s.is_common = 1)');
      } else if (userStream == 'social') {
        gradeWhereParts.add('(s.is_natural = 0 OR s.is_common = 1)');
      }
      if (selectedSubject.value != 'All Subjects') {
        gradeWhereParts.add("s.name = '${selectedSubject.value}'");
      }

      final gradeRows = await db.rawQuery('''
        SELECT 
          n.grade,
          COUNT(n.id) as total_notes,
          SUM(CASE WHEN n.is_completed = 1 THEN 1 ELSE 0 END) as completed_notes
        FROM notes n
        JOIN subjects s ON n.subject_id = s.id
        WHERE ${gradeWhereParts.join(' AND ')}
        GROUP BY n.grade
        ORDER BY n.grade ASC
      ''');

      gradeNotesStats.value = gradeRows.map((r) {
        return GradeNotesStat(
          grade: (r['grade'] as num?)?.toInt() ?? 9,
          completedNotes: (r['completed_notes'] as num?)?.toInt() ?? 0,
          totalNotes: (r['total_notes'] as num?)?.toInt() ?? 0,
        );
      }).toList();
    } catch (_) {
      totalNotesCount.value = 0;
      completedNotesCount.value = 0;
      downloadedNotesCount.value = 0;
      subjectNotesStats.clear();
      gradeNotesStats.clear();
    }
  }

  Future<void> _loadWeaknessAndRecommendations(String userId) async {
    final db = await _db.database;
    try {
      final userStream = UserController.instance.user.value.stream.toLowerCase();
      String streamCondition = '';
      if (userStream == 'natural') {
        streamCondition = '(s.is_natural = 1 OR s.is_common = 1)';
      } else if (userStream == 'social') {
        streamCondition = '(s.is_natural = 0 OR s.is_common = 1)';
      }

      // Query chapters where user took tests
      final rows = await db.rawQuery('''
        SELECT 
          c.id as chapter_id,
          c.title as chapter_title,
          c.chapter_number,
          c.grade,
          s.id as subject_id,
          s.name as subject_name,
          r.correctAnswers,
          r.testQuestions,
          n.id as note_id,
          n.is_completed as note_completed
        FROM results r
        JOIN tests t ON r.test_id = t.id
        JOIN chapters c ON t.chapter_id = c.id
        JOIN subjects s ON t.subject_id = s.id
        LEFT JOIN notes n ON n.chapter_id = c.id
        WHERE (r.user_id = ? OR r.user_id = '' OR r.user_id IS NULL)
          AND (r.isCompleted = 1 OR r.isCompleted IS NULL)
          ${streamCondition.isNotEmpty ? 'AND $streamCondition' : ''}
      ''', [userId]);

      final Map<int, List<_ChapterScoreAgg>> aggMap = {};
      for (final r in rows) {
        final chId = (r['chapter_id'] as num?)?.toInt();
        if (chId == null) continue;
        final correct = (r['correctAnswers'] as num?)?.toInt() ?? 0;
        int total = 1;
        try {
          final list = jsonDecode(r['testQuestions'] as String) as List;
          total = list.isNotEmpty ? list.length : 1;
        } catch (_) {}

        aggMap.putIfAbsent(chId, () => []);
        aggMap[chId]!.add(_ChapterScoreAgg(
          chapterId: chId,
          chapterTitle: r['chapter_title']?.toString() ?? 'Chapter',
          chapterNumber: (r['chapter_number'] as num?)?.toInt() ?? 1,
          grade: (r['grade'] as num?)?.toInt() ?? 9,
          subjectId: (r['subject_id'] as num?)?.toInt(),
          subjectName: r['subject_name']?.toString() ?? 'Subject',
          correct: correct,
          total: total,
          noteId: (r['note_id'] as num?)?.toInt(),
          noteCompleted: (r['note_completed'] as num?)?.toInt() == 1,
        ));
      }

      final List<WeakChapterStat> weakList = [];
      for (final entry in aggMap.entries) {
        final list = entry.value;
        if (list.isEmpty) continue;
        int cTot = 0, qTot = 0;
        for (final item in list) {
          cTot += item.correct;
          qTot += item.total;
        }
        final avg = qTot > 0 ? (cTot / qTot * 100) : 0.0;
        final first = list.first;
        weakList.add(WeakChapterStat(
          chapterId: first.chapterId,
          chapterTitle: first.chapterTitle,
          chapterNumber: first.chapterNumber,
          grade: first.grade,
          subjectId: first.subjectId,
          subjectName: first.subjectName,
          avgScore: avg,
          testsTaken: list.length,
          hasNoteCompleted: first.noteCompleted,
          noteId: first.noteId,
        ));
      }

      // Sort by avgScore ascending (lowest scores first)
      weakList.sort((a, b) => a.avgScore.compareTo(b.avgScore));
      weakestChapters.value = weakList.take(5).toList();

      // Strongest vs Weakest subjects - reliably sync from subjectStats
      _updateSubjectWeakness(subjectStats);

      // Generate smart, actionable study recommendations
      final List<StudyRecommendation> recs = [];

      // 1. Weakest chapter recommendations
      for (final wc in weakestChapters) {
        if (wc.avgScore < 65) {
          if (!wc.hasNoteCompleted && wc.noteId != null) {
            recs.add(StudyRecommendation(
              id: 'note_${wc.chapterId}',
              title: 'Study Note: ${wc.chapterTitle}',
              subtitle: 'Score is ${wc.avgScore.toStringAsFixed(0)}% in ${wc.subjectName} • Read summary note to solidify core concepts',
              subjectName: wc.subjectName,
              subjectId: wc.subjectId,
              type: RecommendationType.readNote,
              targetId: wc.noteId,
              badgeText: 'Read Note',
            ));
          } else {
            recs.add(StudyRecommendation(
              id: 'test_${wc.chapterId}',
              title: 'Re-test: ${wc.chapterTitle}',
              subtitle: 'Score is ${wc.avgScore.toStringAsFixed(0)}% • Practice chapter questions to build mastery',
              subjectName: wc.subjectName,
              subjectId: wc.subjectId,
              type: RecommendationType.practiceChapter,
              targetId: wc.chapterId,
              badgeText: 'Practice Test',
            ));
          }
        }
      }

      // 2. If subject has low score
      for (final ws in weakestAreas) {
        if (recs.length >= 4) break;
        recs.add(StudyRecommendation(
          id: 'subject_${ws.name}',
          title: 'Master ${ws.name}',
          subtitle: 'Current average: ${ws.avgScore.toStringAsFixed(0)}% • Focus on high-yield entrance & model exams',
          subjectName: ws.name,
          subjectId: ws.subjectId,
          type: RecommendationType.practiceSubject,
          targetId: ws.subjectId,
          badgeText: 'Review Subject',
        ));
      }

      // 3. Fallback recommendations if user is just starting
      if (recs.isEmpty) {
        recs.add(StudyRecommendation(
          id: 'rec_start_test',
          title: 'Take an Entrance Exam',
          subtitle: 'Assess your starting knowledge level with genuine national exam questions',
          subjectName: 'All Subjects',
          type: RecommendationType.explore,
          badgeText: 'Start Test',
        ));
        recs.add(StudyRecommendation(
          id: 'rec_read_notes',
          title: 'Explore Subject Notes',
          subtitle: 'Review chapter summaries & downloadable PDFs for Grade 11 & 12',
          subjectName: 'All Subjects',
          type: RecommendationType.exploreNotes,
          badgeText: 'Browse Notes',
        ));
      }

      recommendations.value = recs.take(4).toList();
    } catch (_) {}
  }

  Future<void> _loadChallengeAnalytics(String userId) async {
    final db = await _db.database;
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS local_challenge_practice (
          challenge_id TEXT PRIMARY KEY,
          score INTEGER NOT NULL,
          total_questions INTEGER NOT NULL,
          time_spent_seconds INTEGER,
          user_answers TEXT NOT NULL,
          completed_at TEXT NOT NULL
        )
      ''');

      final rows = await db.query('local_challenge_practice');

      final now = DateTime.now();
      final oneWeekAgo = now.subtract(const Duration(days: 7));
      final oneMonthAgo = now.subtract(const Duration(days: 30));

      int countTotal = 0;
      int countWeek = 0;
      int countMonth = 0;
      int totalScore = 0;
      int totalQuestions = 0;
      int totalTime = 0;

      for (final r in rows) {
        countTotal++;
        final score = (r['score'] as num?)?.toInt() ?? 0;
        final totQ = (r['total_questions'] as num?)?.toInt() ?? 0;
        final timeSpent = (r['time_spent_seconds'] as num?)?.toInt() ?? 0;
        final completedAtStr = r['completed_at']?.toString();

        totalScore += score;
        totalQuestions += totQ;
        totalTime += timeSpent;

        if (completedAtStr != null) {
          final dt = DateTime.tryParse(completedAtStr);
          if (dt != null) {
            if (dt.isAfter(oneWeekAgo)) countWeek++;
            if (dt.isAfter(oneMonthAgo)) countMonth++;
          }
        }
      }

      totalChallengesTaken.value = countTotal;
      challengesThisWeek.value = countWeek;
      challengesThisMonth.value = countMonth;
      challengeTotalTimeSeconds.value = totalTime;
      challengeAvgScorePct.value = totalQuestions > 0 ? (totalScore / totalQuestions * 100) : 0.0;
    } catch (_) {}
  }

  Future<void> _loadBookmarkCount(String userId) async {
    try {
      final db = await _db.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM bookmarks WHERE user_id = ?',
        [userId],
      );
      bookmarkCount.value = result.first['cnt'] as int? ?? 0;
    } catch (_) {
      bookmarkCount.value = 0;
    }
  }
}
