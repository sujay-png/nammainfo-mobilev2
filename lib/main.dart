import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_links/app_links.dart';

import 'core/supabase_client.dart';
import 'core/theme.dart';
import 'core/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSupabase();
  runApp(const ProviderScope(child: NammaInfoApp()));
}

class NammaInfoApp extends StatefulWidget {
  const NammaInfoApp({super.key});

  @override
  State<NammaInfoApp> createState() => _NammaInfoAppState();
}

class _NammaInfoAppState extends State<NammaInfoApp> {
  late final GoRouter _router;
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _router = buildRouter();
    _listenForDeepLinks();
  }

  Future<void> _listenForDeepLinks() async {
    // Cold start: the app was opened directly via a link/NFC tap.
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) _handleUri(initialUri);
    } catch (_) {
      // No initial link — normal cold start.
    }

    // Warm start: the app was already running.
    _linkSub = _appLinks.uriLinkStream.listen(_handleUri, onError: (_) {});
  }

  void _handleUri(Uri uri) {
    final route = routeForExternalUri(uri);
    if (route != null) _router.go(route);
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Namma Info',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: _router,
    );
  }
}
