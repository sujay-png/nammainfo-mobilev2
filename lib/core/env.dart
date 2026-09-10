/// App-wide config. Values are safe to ship in the client — Supabase's
/// anon/publishable key is designed to be public; RLS on the DB side is
/// what actually enforces access control.
///
/// Override at build time with:
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
class Env {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://cqgxdogpmdtifvpbcmqc.supabase.co',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'sb_publishable_3S2EYmd--_MOj9SYO27OuQ_PtYG3l8G',
  );

  static const siteUrl = String.fromEnvironment(
    'SITE_URL',
    defaultValue: 'https://nammainfo.com',
  );

  static const appScheme = 'nammainfo';
}
