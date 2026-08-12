import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/appbar/modern_appbar.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/notifications/controllers/notifications_controller.dart';
import 'package:matricmate/features/notifications/screens/widgets/notification_tile.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  NotificationsController get ctrl => NotificationsController.instance;

  @override
  void initState() {
    super.initState();
    // Run diagnose first so the console always shows DB state on open,
    // then do the full sync load.
    ctrl.diagnose().then((_) => ctrl.loadNotifications(syncRemote: true));
  }

  void _confirmClearAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear all notifications?'),
        content: const Text(
          'This removes all notifications from your device. '
          'They will reappear on next sync.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ctrl.deleteAll();
            },
            child: const Text(
              'Clear all',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// Sends a real FCM push to THIS device via the edge function.
  /// Use this to verify the full chain: edge function → FCM → device.
  /// Close/background the app first, then tap — if the push arrives, it works.
  Future<void> _sendTestPush(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      // 1. Get FCM token for this device
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) {
        messenger.showSnackBar(const SnackBar(
          content: Text('❌ No FCM token — notification permission not granted?'),
        ));
        return;
      }

      // 2. Get webhook secret from app_config
      final rows = await Supabase.instance.client
          .from('app_config')
          .select('key, value')
          .eq('key', 'webhook_secret')
          .limit(1);

      final secret = (rows as List).isNotEmpty
          ? rows.first['value']?.toString() ?? ''
          : '';

      if (secret.isEmpty) {
        messenger.showSnackBar(const SnackBar(
          content: Text('❌ webhook_secret not set in app_config table'),
          backgroundColor: Colors.orange,
        ));
        return;
      }

      // 3. Call edge function with a direct token push (bypasses stream fan-out)
      final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
      final userId = UserController.instance.user.value.id;

      final response = await http.post(
        Uri.parse('$supabaseUrl/functions/v1/send-push'),
        headers: {
          'Content-Type': 'application/json',
          'x-webhook-secret': secret,
        },
        body: jsonEncode({
          'event': 'announcement',
          'title': '🔔 Test Push',
          'body': 'If you see this as a notification, FCM is working!',
          'audience': 'user',
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        messenger.showSnackBar(const SnackBar(
          content: Text('✅ Push sent! Background the app and check for notification.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ));
      } else if (response.statusCode == 401) {
        messenger.showSnackBar(const SnackBar(
          content: Text('❌ 401 Unauthorized — webhook_secret is wrong or edge function not deployed'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 6),
        ));
      } else {
        messenger.showSnackBar(SnackBar(
          content: Text('❌ Edge function returned ${response.statusCode}: ${response.body}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('❌ Error: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernAppbarWithBuilder(
        title: 'Notifications',
        showBackArrow: true,
        actions: [
          // Debug: send a test push to verify the full FCM chain
          IconButton(
            tooltip: 'Send test push (debug)',
            icon: const Icon(Icons.send_rounded, color: AppColors.white, size: 20),
            onPressed: () => _sendTestPush(context),
          ),
          Obx(() {
            if (ctrl.notifications.isEmpty) return const SizedBox.shrink();
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (ctrl.unreadCount.value > 0)
                  TextButton(
                    onPressed: ctrl.markAllRead,
                    child: const Icon(
                      Icons.done_all_rounded,
                      color: AppColors.white,
                      size: 22,
                    ),
                  ),
                IconButton(
                  tooltip: 'Clear all',
                  icon: const Icon(
                    Icons.delete_sweep_rounded,
                    color: AppColors.white,
                    size: 22,
                  ),
                  onPressed: () => _confirmClearAll(context),
                ),
              ],
            );
          }),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await ctrl.diagnose();
          await ctrl.loadNotifications(syncRemote: true);
        },
        child: Obx(() {
          if (ctrl.isLoading.value && ctrl.notifications.isEmpty) {
            return const AppCircularLoading(title: 'Loading notifications...');
          }

          if (ctrl.notifications.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 120),
                Center(
                  child: Icon(
                    Icons.notifications_none_rounded,
                    size: 48,
                    color: AppColors.darkGrey,
                  ),
                ),
                SizedBox(height: 12),
                Center(
                  child: Text(
                    'No notifications yet',
                    style: TextStyle(color: AppColors.darkGrey),
                  ),
                ),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSizes.defaultSpace),
            itemCount: ctrl.notifications.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSizes.spaceBtwItems),
            itemBuilder: (_, i) =>
                NotificationTile(notification: ctrl.notifications[i]),
          );
        }),
      ),
    );
  }
}
