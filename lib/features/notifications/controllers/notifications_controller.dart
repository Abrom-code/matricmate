import 'package:get/get.dart';
import 'package:matricmate/data/repositories/notifications/notification_repository.dart';
import 'package:matricmate/features/notifications/models/notification_model.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/utils/exceptions/exception_handler.dart';

class NotificationsController extends GetxController {
  static NotificationsController get instance => Get.find();

  final NotificationRepository _repo = NotificationRepository();

  final RxList<AppNotification> notifications = <AppNotification>[].obs;
  final RxInt unreadCount = 0.obs;
  final RxBool isLoading = false.obs;

  String get _userId => UserController.instance.user.value.id;
  String get _userStream => UserController.instance.user.value.stream;

  /// Loads from local SQLite. Pass [syncRemote] true to pull fresh rows
  /// from Supabase first (personal + stream-matching broadcasts).
  /// A remote sync failure is silently swallowed — the UI still loads
  /// from the local cache rather than showing an error snackbar.
  Future<void> loadNotifications({bool syncRemote = false}) async {
    if (_userId.isEmpty) return;
    try {
      isLoading.value = true;
      if (syncRemote) {
        try {
          await _repo.syncFromRemote(_userId, _userStream);
        } catch (_) {
          // Remote sync is best-effort; never let it block the local load.
        }
      }
      notifications.assignAll(await _repo.getLocal(_userId));
      unreadCount.value = await _repo.getUnreadCount(_userId);
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markRead(int id) async {
    await _repo.markRead(id);
    await loadNotifications();
  }

  Future<void> markAllRead() async {
    if (_userId.isEmpty) return;
    await _repo.markAllRead(_userId);
    await loadNotifications();
  }

  /// Called by FcmService when a push arrives while the app is in the
  /// foreground — inserts immediately so the bell badge/list update live
  /// without waiting on the next syncRemote() call.
  Future<void> insertFromPush(AppNotification n) async {
    await _repo.insertLocal(n);
    await loadNotifications();
  }
}
