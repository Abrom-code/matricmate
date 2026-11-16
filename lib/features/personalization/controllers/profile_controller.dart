import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/data/database/database_service.dart';

class ProfileController extends GetxController {
  static ProfileController get instance => Get.find();
  final DatabaseService _databaseService = DatabaseService.instance;

  final completedTest = 0.obs;
  final avgScorePct = 0.0.obs;
  final bookmarkCount = 0.obs;
  final completedNotes = 0.obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) => loadStats());
  }

  Future<void> loadStats() async {
    completedTest.value = await _databaseService.getCompletedTests();
    bookmarkCount.value = await _loadBookmarkCount();
    completedNotes.value = await _loadNotesCount();
    avgScorePct.value = await _loadAvgScore();
  }

  Future<int> _loadNotesCount() async {
    try {
      final db = await _databaseService.database;
      final r = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM notes WHERE is_completed = 1',
      );
      final completed = (r.firstOrNull?['cnt'] as num?)?.toInt() ?? 0;
      if (completed > 0) return completed;
      final r2 = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM notes WHERE is_downloaded = 1',
      );
      return (r2.firstOrNull?['cnt'] as num?)?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _loadBookmarkCount() async {
    try {
      final db = await _databaseService.database;
      final userId = await _getUserId();
      if (userId.isEmpty) return 0;
      final r = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM bookmarks WHERE user_id = ?',
        [userId],
      );
      return r.first['cnt'] as int? ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<double> _loadAvgScore() async {
    try {
      final db = await _databaseService.database;
      final userId = await _getUserId();
      if (userId.isEmpty) return 0.0;
      final rows = await db.rawQuery(
        '''
        SELECT r.correctAnswers, COALESCE(NULLIF(t.question_count, 0), 1) as total_questions
        FROM results r
        LEFT JOIN tests t ON r.test_id = t.id
        WHERE r.user_id = ?
        ''',
        [userId],
      );
      int correct = 0;
      int total = 0;
      for (final row in rows) {
        correct += (row['correctAnswers'] as int? ?? 0);
        total += (row['total_questions'] as num?)?.toInt() ?? 1;
      }
      return total > 0 ? correct / total * 100 : 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  Future<String> _getUserId() async {
    final users = await _databaseService.getUser();
    return users.firstOrNull?['id'] as String? ?? '';
  }
}
