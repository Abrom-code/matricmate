import 'dart:convert';
import 'package:get/get.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart';

class SubjectStat {
  final String name;
  final double avgScore; // 0.0 – 100.0
  SubjectStat({required this.name, required this.avgScore});
}

class ChapterStat {
  final String title;
  final double? score; // null = not attempted
  ChapterStat({required this.title, required this.score});
}

class TrendPoint {
  final int index;
  final double score; // 0.0 – 100.0
  TrendPoint({required this.index, required this.score});
}

class AnalyticsController extends GetxController {
  static AnalyticsController get instance => Get.find();

  final _db = DatabaseService.instance;

  final isLoading = true.obs;

  // Summary
  final testsCompleted = 0.obs;
  final avgScorePct = 0.0.obs;
  final totalCorrect = 0.obs;
  final bookmarkCount = 0.obs;

  // Charts
  final trendPoints = <TrendPoint>[].obs;
  final subjectStats = <SubjectStat>[].obs;
  final typeDistribution = <String, double>{}.obs; // type -> percentage
  final chapterStats = <ChapterStat>[].obs;
  final weakestAreas = <SubjectStat>[].obs; // bottom 2 subjects

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

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

  // ── Summary ──────────────────────────────────────────────────────────────

  Future<void> _loadSummary(String userId) async {
    final db = await _db.database;

    final rows = await db.rawQuery(
      'SELECT correctAnswers, testQuestions FROM results WHERE user_id = ?',
      [userId],
    );

    testsCompleted.value = rows.length;

    int correct = 0;
    int total = 0;

    for (final row in rows) {
      correct += (row['correctAnswers'] as int? ?? 0);
      final questions = row['testQuestions'];
      if (questions != null && questions is String) {
        try {
          final list = jsonDecode(questions) as List;
          total += list.length;
        } catch (_) {}
      }
    }

    totalCorrect.value = correct;
    avgScorePct.value = total > 0 ? (correct / total * 100) : 0.0;
  }

  // ── Trend (last 10 completed tests) ──────────────────────────────────────

  Future<void> _loadTrend(String userId) async {
    final db = await _db.database;

    final rows = await db.rawQuery(
      '''
      SELECT r.correctAnswers, r.testQuestions
      FROM results r
      JOIN tests t ON r.test_id = t.id
      WHERE r.user_id = ?
      ORDER BY t.created_at DESC
      LIMIT 10
      ''',
      [userId],
    );

    // Reverse so oldest is first (left → right on chart)
    final reversed = rows.reversed.toList();

    final points = <TrendPoint>[];
    for (int i = 0; i < reversed.length; i++) {
      final row = reversed[i];
      final correct = row['correctAnswers'] as int? ?? 0;
      int total = 1;
      try {
        final list = jsonDecode(row['testQuestions'] as String) as List;
        total = list.isNotEmpty ? list.length : 1;
      } catch (_) {}
      points.add(TrendPoint(index: i, score: correct / total * 100));
    }

    trendPoints.value = points;
  }

  // ── Subject performance ───────────────────────────────────────────────────

  Future<void> _loadSubjectPerformance(String userId) async {
    final db = await _db.database;

    // For each subject, compute avg score properly
    final Map<String, List<int>> bySubject = {};

    final detailedRows = await db.rawQuery(
      '''
      SELECT s.name, r.correctAnswers, r.testQuestions
      FROM results r
      JOIN tests t ON r.test_id = t.id
      JOIN subjects s ON t.subject_id = s.id
      WHERE r.user_id = ?
      ''',
      [userId],
    );

    for (final row in detailedRows) {
      final name = row['name'] as String;
      final correct = row['correctAnswers'] as int? ?? 0;
      int total = 1;
      try {
        final list = jsonDecode(row['testQuestions'] as String) as List;
        total = list.isNotEmpty ? list.length : 1;
      } catch (_) {}

      bySubject.putIfAbsent(name, () => [0, 0]);
      bySubject[name]![0] += correct;
      bySubject[name]![1] += total;
    }

    final stats = bySubject.entries.map((e) {
      final pct = e.value[1] > 0 ? e.value[0] / e.value[1] * 100 : 0.0;
      return SubjectStat(name: e.key, avgScore: pct);
    }).toList();

    stats.sort((a, b) => b.avgScore.compareTo(a.avgScore));
    subjectStats.value = stats;
  }

  // ── Type distribution ─────────────────────────────────────────────────────

  Future<void> _loadTypeDistribution(String userId) async {
    final db = await _db.database;

    final rows = await db.rawQuery(
      '''
      SELECT t.type, COUNT(r.id) as cnt
      FROM results r
      JOIN tests t ON r.test_id = t.id
      WHERE r.user_id = ?
      GROUP BY t.type
      ''',
      [userId],
    );

    final Map<String, double> dist = {};
    int total = rows.fold(0, (sum, row) => sum + (row['cnt'] as int? ?? 0));
    if (total == 0) total = 1;

    for (final row in rows) {
      final type = (row['type'] as String?) ?? 'unknown';
      final cnt = (row['cnt'] as int?) ?? 0;
      dist[type] = cnt / total * 100;
    }

    typeDistribution.value = dist;
  }

  // ── Chapter progress ──────────────────────────────────────────────────────

  Future<void> _loadChapterProgress(String userId) async {
    final db = await _db.database;

    final rows = await db.rawQuery(
      '''
      SELECT c.title,
             r.correctAnswers,
             r.testQuestions
      FROM chapters c
      LEFT JOIN tests t ON t.chapter_id = c.id
      LEFT JOIN results r ON r.test_id = t.id AND r.user_id = ?
      WHERE c.id IN (SELECT DISTINCT chapter_id FROM tests WHERE chapter_id IS NOT NULL)
      GROUP BY c.id
      ORDER BY r.correctAnswers DESC NULLS LAST
      LIMIT 10
      ''',
      [userId],
    );

    final stats = rows.map((row) {
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

    chapterStats.value = stats;
  }

  // ── Bookmark count ────────────────────────────────────────────────────────

  Future<void> _loadBookmarkCount(String userId) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM bookmarks WHERE user_id = ?',
      [userId],
    );
    bookmarkCount.value = result.first['cnt'] as int? ?? 0;
  }

  // ── Weakest areas (bottom 2 subjects by avg score) ────────────────────────

  void _computeWeakestAreas() {
    if (subjectStats.isEmpty) {
      weakestAreas.value = [];
      return;
    }
    final sorted = [...subjectStats]..sort((a, b) => a.avgScore.compareTo(b.avgScore));
    weakestAreas.value = sorted.take(2).toList();
  }
}
