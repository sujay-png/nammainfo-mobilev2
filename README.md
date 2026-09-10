# Namma Info — Mobile (Flutter)

This is source code, not a generated Flutter project — the `android/` and
`ios/` native folders aren't included (they're machine-generated and huge).
Get it running in three steps:

```bash
flutter create . --org com.nammainfo --project-name nammainfo_mobile
flutter pub get
```

`flutter create .` fills in `android/` and `ios/` around the existing
`lib/`, `pubspec.yaml`, etc. without touching your code. Then apply the two
snippet files in `platform_setup/`:

- `android_manifest_snippet.xml` → merge into
  `android/app/src/main/AndroidManifest.xml` (NFC permission + intent
  filters for both the custom scheme and Android App Links)
- `ios_info_plist_snippet.xml` → merge into `ios/Runner/Info.plist`, plus
  the two Xcode capabilities it documents (NFC reader entitlement,
  Associated Domains)

Run with:

```bash
flutter run
```

Supabase URL/key are baked into `lib/core/env.dart` (same public project as
the web app) — override at build time if you ever point at a different
project:

```bash
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

## What's implemented

- **Auth** — email/password sign in/up against Supabase Auth
  (`features/auth`). The `on_auth_user_created` trigger on the DB already
  creates the `profiles` row for you on sign-up.
- **Profile Builder & Card Customizer** (`features/profile`) — edits every
  field from the spec, live-updates the same card preview component used
  everywhere else in the app, and uploads an avatar to Supabase Storage.
- **My Card** (`features/card/my_card_screen.dart`) — shows the live card,
  a QR code of `https://nammainfo.com/c/<card-id>` (this is the *same*
  fallback pattern as your printed card's back — NFC for phones that
  support it, QR for the ones that don't), and a **"Write to physical NFC
  card"** button that writes that exact URL as an NDEF URI record via
  `features/nfc/nfc_service.dart`.
- **NFC read** — `NfcService.readOnce()` decodes a tapped tag's URI record
  while the app is in the foreground (used for tap-to-connect flows beyond
  the OS-level deep link).
- **Deep link router** (`core/router.dart` + `main.dart`) — `go_router`
  routes for `nammainfo://profile/:id` and `https://nammainfo.com/c/:id`,
  wired to `app_links` for cold-start and warm-start incoming links. Either
  one opens `PublicCardScreen`, and if you're signed in and it's not your
  own card, a **Save Connection** bottom sheet appears.
- **Feed** (`features/feed`) — this is the app's home tab, chronological,
  Instagram-style: your own posts + posts from everyone you've saved as a
  connection (enforced server-side by the `posts_select_network` RLS
  policy — the client doesn't do any filtering itself). Post creation
  sheet supports Announcement / Event / Update with an optional event
  date/time.
- **Bottom navigation**: **Feed → My Card → Profile**. Per your note about
  the Figma reference, "Share" was replaced with **Profile** as the third
  tab; sharing your own card is a button inside My Card instead.

## Design intent

The card preview (`features/profile/widgets/live_card_preview.dart`) uses
the same deep maroon/ink foil palette as the web landing page and your
printed card, not a default Material card — same visual language across
web, app, and the physical card back you showed me (NFC logo + QR on the
back, full company details on the front).

## Store-compliance notes (read before submitting)

- **NFC**: both stores allow apps that use NFC for legitimate tag read/
  write use cases like this one. Make sure the NFC permission (Android)
  and `NFCReaderUsageDescription` (iOS) strings accurately describe what
  you're doing — already set in the snippets to something specific, not
  generic boilerplate (a generic description is a common rejection
  reason).
- **Sign-in requirement**: Apple requires that non-login-gated content
  stays reachable — that's why `PublicCardScreen` is reachable without an
  account in `core/router.dart`'s redirect logic. Don't wall it behind
  auth or App Review will flag it.
- **Account deletion**: both stores now require an in-app way to delete
  your account, not just a support email. Not built yet — flagging so it
  doesn't surprise you at submission time.
- **Privacy manifest (iOS)**: Apple requires a `PrivacyInfo.xcprivacy`
  declaring what "required reason" APIs you use (Supabase's SDK may touch
  UserDefaults). Check this once `flutter create .` has generated the iOS
  project — some plugin versions ship their own, some don't yet.

## Not yet built (next phase)

- Account deletion flow (see above — needed for store approval)
- Push notifications for new posts from connections
- Editing/deleting your own posts from the feed UI (repository methods
  already exist in `data/posts_repository.dart`)
- Offline caching of the feed
