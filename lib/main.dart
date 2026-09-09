import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:matricmate/data/services/fcm_service.dart';
import 'package:matricmate/data/services/payment_config_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:matricmate/app.dart';
import 'package:matricmate/data/repositories/authentication/authentication_repository.dart';
import 'package:matricmate/firebase_options.dart';
import 'package:matricmate/utils/themes/theme_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GetStorage.init();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}

  // ThemeController must exist before any widget builds
  Get.put(ThemeController(), permanent: true);

  // Create Android notification channel before any FCM message arrives
  await FlutterLocalNotificationsPlugin()
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(
        const AndroidNotificationChannel(
          'matricmate_default',
          'General Notifications',
          description: 'Announcements, payment updates, and new exam alerts',
          importance: Importance.high,
        ),
      );

  const defineUrl = String.fromEnvironment('SUPABASE_URL');
  const defineKey = String.fromEnvironment('SUPABASE_API_KEY');
  final envUrl = dotenv.isInitialized ? dotenv.env['SUPABASE_URL'] : null;
  final envKey = dotenv.isInitialized ? dotenv.env['SUPABASE_API_KEY'] : null;

  final supabaseUrl = defineUrl.isNotEmpty
      ? defineUrl
      : (envUrl ?? 'https://gcscoitnhdrqsibkxrit.supabase.co');
  final supabaseKey = defineKey.isNotEmpty
      ? defineKey
      : (envKey ?? 'sb_publishable_OhdIkL0Tlwn4I9cbf-EDdA_Vp9uKhda');

  // Initialize Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabaseKey,
  );

  Get.put(AuthenticationRepository());

  // Initialize Firebase for FCM Push Notifications
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Best-effort payment config fetch; auth load picks up failures
  unawaited(PaymentConfigService.instance.load());

  runApp(const App());
}
