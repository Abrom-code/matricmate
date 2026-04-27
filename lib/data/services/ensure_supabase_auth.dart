import 'package:matricmate/utils/exceptions/exeption_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> ensureSupabaseAuth() async {
  final client = Supabase.instance.client;

  if (client.auth.currentSession == null) {
    try {
      await client.auth.signInAnonymously();
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }
}
