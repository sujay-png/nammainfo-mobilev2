import 'package:supabase_flutter/supabase_flutter.dart';

class ConnectionsRepository {
  final SupabaseClient _client;
  ConnectionsRepository(this._client);

  Future<bool> isConnected(String userId, String otherUserId) async {
    final row = await _client
        .from('connections')
        .select('id')
        .eq('user_id', userId)
        .eq('connected_user_id', otherUserId)
        .maybeSingle();
    return row != null;
  }

  /// Saves a one-way connection (mirrors how "saving a contact" works —
  /// the other business doesn't need to reciprocate for it to show up in
  /// your own network/feed sources).
  Future<void> saveConnection({
    required String userId,
    required String connectedUserId,
  }) async {
    if (userId == connectedUserId) return;
    await _client.from('connections').upsert(
      {
        'user_id': userId,
        'connected_user_id': connectedUserId,
      },
      onConflict: 'user_id,connected_user_id',
      ignoreDuplicates: true,
    );
  }

  Future<void> removeConnection({
    required String userId,
    required String connectedUserId,
  }) async {
    await _client
        .from('connections')
        .delete()
        .eq('user_id', userId)
        .eq('connected_user_id', connectedUserId);
  }

  Future<List<String>> myConnectionIds(String userId) async {
    final rows = await _client
        .from('connections')
        .select('connected_user_id')
        .eq('user_id', userId);
    return (rows as List)
        .map((r) => r['connected_user_id'] as String)
        .toList();
  }
}
