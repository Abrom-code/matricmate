import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/features/tips_and_news/models/tips_and_news_model.dart';
import 'package:matricmate/utils/constants/app_timeouts.dart';
import 'package:matricmate/utils/network_manager/network_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TipsAndNewsRepository {
  TipsAndNewsRepository({DatabaseService? databaseService})
      : _db = databaseService ?? DatabaseService.instance;

  final DatabaseService _db;
  final SupabaseClient _sb = Supabase.instance.client;

  /// Syncs latest tips and news from Supabase and stores in local SQLite.
  /// Falls back silently to offline SQLite cache when disconnected.
  Future<List<TipsAndNewsModel>> syncFromRemote({String? stream}) async {
    final isConnected = await NetworkManager.instance.isConnected();
    if (!isConnected) {
      return await getLocalItems();
    }

    try {
      var query = _sb
          .from('tips_and_news')
          .select()
          .eq('is_published', true);

      final cleanStream = stream?.trim().toLowerCase();
      if (cleanStream != null && cleanStream.isNotEmpty && cleanStream != 'both') {
        query = query.or('audience.eq.both,audience.eq.$cleanStream');
      }

      final rows = await query
          .order('is_pinned', ascending: false)
          .order('created_at', ascending: false)
          .limit(100)
          .timeout(AppTimeouts.query);

      final List<Map<String, dynamic>> rawList =
          List<Map<String, dynamic>>.from(rows);

      // Save to local SQLite
      if (rawList.isNotEmpty) {
        await _db.saveTipsAndNews(rawList);
      }

      return await getLocalItems();
    } catch (_) {
      // On network failure or timeout, return local cached data seamlessly
      return await getLocalItems();
    }
  }

  /// Retrieves items from local SQLite joined with local read tracking.
  Future<List<TipsAndNewsModel>> getLocalItems({String? category}) async {
    final rows = await _db.getTipsAndNews(category: category);
    return rows.map((r) => TipsAndNewsModel.fromJson(r)).toList();
  }

  /// Marks an item as read locally in SQLite. (0ms, 0 network).
  Future<void> markAsRead(int id) async {
    await _db.markTipOrNewsRead(id);
  }

  /// Marks all tips and news as read locally.
  Future<void> markAllAsRead() async {
    await _db.markAllTipsAndNewsRead();
  }

  /// Gets the count of unread items from local SQLite.
  Future<int> getUnreadCount() async {
    return await _db.getUnreadTipsAndNewsCount();
  }
}

