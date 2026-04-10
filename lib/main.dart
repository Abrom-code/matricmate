import 'package:flutter/material.dart';
import 'package:matricmate/app.dart';
import 'package:matricmate/utils/constants/api_constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize supabase
  await Supabase.initialize(
    url: ApiConstants.supabaseUrl,
    anonKey: ApiConstants.supabaseApiKey,
  );
  runApp(const App());
}
