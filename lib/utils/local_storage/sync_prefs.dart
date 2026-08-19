import 'package:shared_preferences/shared_preferences.dart';

/// Persists last successful sync timestamps per data category in GetStorage.
class SyncPrefs {
  SyncPrefs._();

  static const _subjectsKey = 'sync_ts_subjects';
  static const _entranceKey = 'sync_ts_entrance';
  static const _chaptersKey = 'sync_ts_chapters';

  static Future<DateTime?> lastSubjectsSync() => _get(_subjectsKey);
  static Future<DateTime?> lastEntranceSync() => _get(_entranceKey);
  static Future<DateTime?> lastChaptersSync() => _get(_chaptersKey);

  static Future<void> saveSubjectsSync(DateTime time) =>
      _save(_subjectsKey, time);
  static Future<void> saveEntranceSync(DateTime time) =>
      _save(_entranceKey, time);
  static Future<void> saveChaptersSync(DateTime time) =>
      _save(_chaptersKey, time);

  /// Clears all sync timestamps (e.g. on sign-out or "force full sync").
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_subjectsKey);
    await prefs.remove(_entranceKey);
    await prefs.remove(_chaptersKey);
  }

  static Future<DateTime?> _get(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(key);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  static Future<void> _save(String key, DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, time.millisecondsSinceEpoch);
  }
}
