import 'dart:convert';
import 'package:get/get.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';

// ── Data classes ──────────────────────────────────────────────────────────────

class SubjectStat {
  final String name;
  final double avgScore;
  SubjectStat({required this.name, required this.avgScore});
}

class ChapterStat {
  final String title;
  final double? score;
  ChapterStat({required this.title, required this.score});
}

class TrendPoint {
  final int index;
  final double score;
  TrendPoint({required this.index, required this.score});
}

// ── Filter enums ──────────────────────────────────────────────────────────────

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
  final weakestAreas = <SubjectStat>[].obs;

  @override
  void onInit() {
    super.onInit();
    _initFilterOptions();
    loadAll();
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

    final subjectRows = await db.rawQuery(
      '''
      SELECT DISTINCT name FROM subjects
      $streamCondition
      ORDER BY name
    ''',
    );

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
    final parts = <String>['r.user_id = ?'];

    // Automatic Profile Stream filtering (no manual stream picker needed)
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

    // Test Category (All 4 categories supported)
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
      parts.add("t.created_at >= '${cutoff.toIso8601String()}'");
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
    if (selectedTimed.value != TimedFilter.all) count++;
    if (selectedScore.value != ScoreFilter.all) count++;
    return count;
  }

  bool get hasActiveFilters => activeFilterCount > 0;

  // ── Load all data ────────────────────────────────────────────────────────

  Future<void> loadAll() async {
    isLoading.value = true;
    try {
      final userId = UserController.instance.user.value.id;
      if (userId.isEmpty) return;
      await Future.wait([
        _loadSummary(userId),
        _loadTrend(userId),
        _loadSubjectPerformance(userId),
        _loadTypeDistribution(userId),
        _loadChapterProgress(userId),
        _loadBookmarkCount(userId),
      ]);
      _computeWeakestAreas();
    } finally {
      isLoading.value = false;
    }
  }

  // ── Private loaders ──────────────────────────────────────────────────────

  Future<void> _loadSummary(String userId) async {
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
  }

  Future<void> _loadTrend(String userId) async {
    final db = await _db.database;
    final where = _buildWhere(userId);

    final rows = await db.rawQuery(
      '''
      SELECT r.correctAnswers, r.testQuestions
      FROM results r
      JOIN tests t ON r.test_id = t.id
      JOIN subjects s ON t.subject_id = s.id
      WHERE $where
      ORDER BY t.created_at DESC
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
  }

  Future<void> _loadSubjectPerformance(String userId) async {
    final db = await _db.database;
    final where = _buildWhere(userId);

    final rows = await db.rawQuery(
      '''
      SELECT s.name, r.correctAnswers, r.testQuestions
      FROM results r
      JOIN tests t ON r.test_id = t.id
      JOIN subjects s ON t.subject_id = s.id
      WHERE $where
    ''',
      [userId],
    );

    final Map<String, List<int>> bySubject = {};
    for (final row in rows) {
      final name = row['name'] as String;
      final correct = row['correctAnswers'] as int? ?? 0;
      int total = 1;
      try {
        final list = jsonDecode(row['testQuestions'] as String) as List;
        total = list.isNotEmpty ? list.length : 1;
      } catch (_) {}
      if (!_passesScoreFilter(correct, total)) continue;
      bySubject.putIfAbsent(name, () => [0, 0]);
      bySubject[name]![0] += correct;
      bySubject[name]![1] += total;
    }

    final stats = bySubject.entries.map((e) {
      final pct = e.value[1] > 0 ? e.value[0] / e.value[1] * 100 : 0.0;
      return SubjectStat(name: e.key, avgScore: pct);
    }).toList()..sort((a, b) => b.avgScore.compareTo(a.avgScore));

    subjectStats.value = stats;
  }

  Future<void> _loadTypeDistribution(String userId) async {
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
  }

  Future<void> _loadChapterProgress(String userId) async {
    final db = await _db.database;

    // Chapter progress: apply subject + grade + stream filters only
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
      SELECT c.title, r.correctAnswers, r.testQuestions
      FROM chapters c
      LEFT JOIN tests t ON t.chapter_id = c.id
      LEFT JOIN subjects s ON t.subject_id = s.id
      LEFT JOIN results r ON r.test_id = t.id AND r.user_id = ?
      WHERE c.id IN (SELECT DISTINCT chapter_id FROM tests WHERE chapter_id IS NOT NULL)
        AND ($chapterWhere)
      GROUP BY c.id
      ORDER BY r.correctAnswers DESC NULLS LAST
      LIMIT 10
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
      return ChapterStat(title: title, score: score);
    }).toList();
  }

  Future<void> _loadBookmarkCount(String userId) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM bookmarks WHERE user_id = ?',
      [userId],
    );
    bookmarkCount.value = result.first['cnt'] as int? ?? 0;
  }

  void _computeWeakestAreas() {
    if (subjectStats.isEmpty) {
      weakestAreas.value = [];
      return;
    }
    final sorted = [...subjectStats]
      ..sort((a, b) => a.avgScore.compareTo(b.avgScore));
    weakestAreas.value = sorted.take(2).toList();
  }
}
