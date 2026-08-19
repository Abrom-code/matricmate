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
  await dotenv.load(fileName: '.env');

  // ThemeController must exist before any widget builds
  Get.put(ThemeController(), permanent: true);

  // Create Android notification channel before any FCM message arrives
  await FlutterLocalNotificationsPlugin()
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(
        const AndroidNotificationChannel(
          'matricmate_default',
          'General Notifications',
          description: 'Announcements, payment updates, and new exam alerts',
          importance: Importance.high,
        ),
      );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ).then((FirebaseApp value) => Get.put(AuthenticationRepository()));

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_API_KEY'] ?? '',
  );

  // Best-effort anonymous payment config fetch; auth load picks up failures
  unawaited(PaymentConfigService.instance.load());

  runApp(const App());
}
