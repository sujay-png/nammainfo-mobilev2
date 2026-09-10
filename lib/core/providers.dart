import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client.dart';
import '../data/profile_repository.dart';
import '../data/card_repository.dart';
import '../data/connections_repository.dart';
import '../data/posts_repository.dart';
import '../data/card_orders_repository.dart';
import '../models/profile.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) => supabase);

final profileRepositoryProvider = Provider(
  (ref) => ProfileRepository(ref.watch(supabaseClientProvider)),
);
final cardRepositoryProvider = Provider(
  (ref) => CardRepository(ref.watch(supabaseClientProvider)),
);
final connectionsRepositoryProvider = Provider(
  (ref) => ConnectionsRepository(ref.watch(supabaseClientProvider)),
);
final postsRepositoryProvider = Provider(
  (ref) => PostsRepository(ref.watch(supabaseClientProvider)),
);
final cardOrdersRepositoryProvider = Provider(
  (ref) => CardOrdersRepository(ref.watch(supabaseClientProvider)),
);

/// Emits the current Supabase auth session, including on sign in/out —
/// the router listens to this to decide whether to show auth or the app.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return supabase.auth.onAuthStateChange;
});

final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider).valueOrNull;
  return authState?.session?.user.id ?? supabase.auth.currentUser?.id;
});

/// The signed-in user's own profile row. Invalidate after edits/upserts.
final myProfileProvider = FutureProvider.autoDispose<Profile?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return ref.watch(profileRepositoryProvider).getById(userId);
});
