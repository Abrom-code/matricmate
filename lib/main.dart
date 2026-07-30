import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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

  // ThemeController must exist before any widget builds so the
  Get.put(ThemeController(), permanent: true);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ).then((FirebaseApp value) => Get.put(AuthenticationRepository()));

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_API_KEY'] ?? '',
  );

  runApp(const App());
}
