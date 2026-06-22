import 'package:matricmate/utils/exceptions/exeption_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> ensureSupabaseAuth() async {
  final client = Supabase.instance.client;

  if (client.auth.currentSession != null) return;

  try {
    await client.auth.signInAnonymously();
  } catch (e) {
    // Wrap and re-throw so the calling repository gets a clean AppFailure
    throw AppExceptionHandler.handle(e is Object ? e : Exception(e.toString()));
  }
}
