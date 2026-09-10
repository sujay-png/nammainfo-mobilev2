import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'supabase_client.dart';
import '../features/auth/auth_screen.dart';
import '../features/home/home_shell.dart';
import '../features/profile/profile_builder_screen.dart';
import '../features/card/public_card_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildRouter() {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/home',
    refreshListenable: GoRouterRefreshStream(supabase.auth.onAuthStateChange),
    redirect: (context, state) {
      final loggedIn = supabase.auth.currentSession != null;
      final onAuthPage = state.matchedLocation == '/auth';

      // Public card views (someone else's card, reached via NFC/QR/link)
      // should be viewable even if you're not signed in yet.
      final isPublicCard = state.matchedLocation.startsWith('/c/') ||
          state.matchedLocation.startsWith('/profile/');

      if (!loggedIn && !onAuthPage && !isPublicCard) return '/auth';
      if (loggedIn && onAuthPage) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeShell()),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const ProfileBuilderScreen(),
      ),
      // nammainfo://profile/:profileId
      GoRoute(
        path: '/profile/:profileId',
        builder: (context, state) => PublicCardScreen(
          profileId: state.pathParameters['profileId'],
        ),
      ),
      // https://nammainfo.com/c/:cardId  (also what's written to the NFC chip)
      GoRoute(
        path: '/c/:cardId',
        builder: (context, state) => PublicCardScreen(
          cardIdOrSlug: state.pathParameters['cardId'],
        ),
      ),
    ],
  );
}

/// Maps an externally-received URI (from app_links, an NFC tap, or a QR
/// scan) to an in-app route path. Handles both the custom scheme used for
/// app-to-app deep links and the universal https link written to physical
/// cards.
String? routeForExternalUri(Uri uri) {
  // nammainfo://profile/<id>
  if (uri.scheme == 'nammainfo' && uri.host == 'profile') {
    final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    return id == null ? null : '/profile/$id';
  }
  // https://nammainfo.com/c/<id>  (or any host, in case of a custom domain)
  if ((uri.scheme == 'https' || uri.scheme == 'http') &&
      uri.pathSegments.length >= 2 &&
      uri.pathSegments.first == 'c') {
    return '/c/${uri.pathSegments[1]}';
  }
  // https://nammainfo.com/<slug>  (the vanity link now written to new
  // cards, e.g. /wrnxt — see Env.publicCardUrl). Any other single-segment
  // path on the site that isn't a card just won't resolve in
  // PublicCardScreen and shows "card not found", so this is safe even if
  // the web app grows ordinary marketing pages later.
  const reservedSlugs = {'c', 'api', 'profile', 'home', 'auth'};
  if ((uri.scheme == 'https' || uri.scheme == 'http') &&
      uri.pathSegments.length == 1 &&
      !reservedSlugs.contains(uri.pathSegments.first)) {
    return '/c/${uri.pathSegments.first}';
  }
  return null;
}

/// Bridges a Stream (Supabase's auth changes) into a Listenable so
/// go_router can re-evaluate `redirect` whenever auth state changes.
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
