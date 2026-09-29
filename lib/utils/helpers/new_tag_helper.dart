import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Helper to manage "NEW" tags for notes and tests.
/// Items show a "NEW" badge if created within the past 1 week (7 days)
/// and the user has not yet clicked/opened them.
/// Once clicked or if time is up (> 7 days), the "NEW" badge is removed.
class NewTagHelper {
  NewTagHelper._();

  static final GetStorage _box = GetStorage();
  static const String _openedTestsKey = 'new_tag_opened_tests';
  static const String _openedNotesKey = 'new_tag_opened_notes';

  // Reactive sets so widgets rebuilding via Obx update instantly upon click
  static final RxSet<int> _openedTests = <int>{}.obs;
  static final RxSet<int> _openedNotes = <int>{}.obs;
  static bool _initialized = false;

  /// Ensures storage-backed sets are populated into memory.
  static void ensureInitialized() {
    if (_initialized) return;
    try {
      final testsList = _box.read<List>(_openedTestsKey) ?? [];
      final notesList = _box.read<List>(_openedNotesKey) ?? [];
      _openedTests.addAll(testsList.map((e) => (e as num).toInt()));
      _openedNotes.addAll(notesList.map((e) => (e as num).toInt()));
      _initialized = true;
    } catch (_) {
      _initialized = true;
    }
  }

  /// Checks if a test has already been opened/clicked by the user.
  static bool isTestOpened(int testId) {
    ensureInitialized();
    return _openedTests.contains(testId);
  }

  /// Checks if a note has already been opened/clicked by the user.
  static bool isNoteOpened(int noteId) {
    ensureInitialized();
    return _openedNotes.contains(noteId);
  }

  /// Checks if a test is considered "NEW" (created within 7 days and never clicked/opened).
  static bool isTestNew({
    required int testId,
    required DateTime createdAt,
    bool hasResult = false,
    bool isInProgress = false,
  }) {
    ensureInitialized();
    if (hasResult || isInProgress) return false;
    if (_openedTests.contains(testId)) return false;
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return createdAt.isAfter(cutoff);
  }

  /// Marks a test as opened/clicked, instantly removing the "NEW" badge.
  static void markTestOpened(int testId) {
    ensureInitialized();
    if (_openedTests.contains(testId)) return;
    _openedTests.add(testId);
    _box.write(_openedTestsKey, _openedTests.toList());
  }

  /// Checks if a note is considered "NEW" (created within 7 days and never clicked/opened).
  static bool isNoteNew({
    required int noteId,
    DateTime? createdAt,
    String? downloadedAt,
    bool isCompleted = false,
  }) {
    ensureInitialized();
    if (isCompleted) return false;
    if (_openedNotes.contains(noteId)) return false;
    final date = createdAt ??
        (downloadedAt != null ? DateTime.tryParse(downloadedAt) : null);
    if (date == null) return false;
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return date.isAfter(cutoff);
  }

  /// Marks a note as opened/clicked, instantly removing the "NEW" badge.
  static void markNoteOpened(int noteId) {
    ensureInitialized();
    if (_openedNotes.contains(noteId)) return;
    _openedNotes.add(noteId);
    _box.write(_openedNotesKey, _openedNotes.toList());
  }
}
