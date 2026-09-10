import 'package:supabase_flutter/supabase_flutter.dart';
import 'env.dart';

Future<void> initSupabase() async {
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );
}

/// Shorthand used throughout the app.
SupabaseClient get supabase => Supabase.instance.client;
