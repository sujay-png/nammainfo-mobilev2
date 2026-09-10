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
    // Real Vercel deployment for now — swap to https://nammainfo.com once
    // that custom domain is pointed at the same Vercel project.
    defaultValue: 'https://nammainfo-webv2.vercel.app',
  );

  static const appScheme = 'nammainfo';

  /// [siteUrl] is now a real, deployed site, so cards default to a real
  /// https link (works for people without the app too) instead of the
  /// app-only `nammainfo://` scheme. Flip this to true for quick local
  /// dev/testing — no hosting needed, opens straight into the app on any
  /// phone that already has it installed — or override at build time
  /// with --dart-define=USE_APP_SCHEME_FOR_CARD_LINKS=true.
  ///
  /// Note the https link still won't auto-open the app on tap (only a
  /// browser) until Android App Links / iOS Universal Links are set up —
  /// that needs assetlinks.json / apple-app-site-association hosted at
  /// [siteUrl], matching this app's real package ID / Team ID. Fine for
  /// now: the web page itself is a complete experience.
  static const useAppSchemeForCardLinks = bool.fromEnvironment(
    'USE_APP_SCHEME_FOR_CARD_LINKS',
    defaultValue: false,
  );

  /// The link to put on a physical NFC card / QR code for this profile —
  /// see [useAppSchemeForCardLinks]. [publicSlug] is the card's friendly
  /// slug (e.g. "wrnxt") — falls back to the raw card id if a slug isn't
  /// available yet.
  static String publicCardUrl({
    required String cardId,
    required String profileId,
    String? publicSlug,
  }) {
    if (useAppSchemeForCardLinks) {
      return '$appScheme://profile/$profileId';
    }
    final slug = (publicSlug != null && publicSlug.isNotEmpty) ? publicSlug : cardId;
    return '$siteUrl/$slug';
  }
}
