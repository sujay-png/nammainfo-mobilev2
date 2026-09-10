import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post.dart';

class PostsRepository {
  final SupabaseClient _client;
  PostsRepository(this._client);

  /// Feed = own posts + posts from businesses you've connected with
  /// (enforced by the `posts_select_network` RLS policy server-side —
  /// this query relies on that, it doesn't filter client-side).
  Future<List<Post>> fetchFeed({int limit = 30, DateTime? before}) async {
    var query = _client
        .from('posts')
        .select('*, profiles!posts_profile_id_fkey(business_name, avatar_url)');

    if (before != null) {
      query = query.lt('created_at', before.toIso8601String());
    }

    final rows =
        await query.order('created_at', ascending: false).limit(limit);
    return (rows as List)
        .map((r) => Post.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<Post>> fetchForProfile(String profileId) async {
    final rows = await _client
        .from('posts')
        .select('*, profiles!posts_profile_id_fkey(business_name, avatar_url)')
        .eq('profile_id', profileId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => Post.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<Post> createPost({
    required String profileId,
    required String content,
    required PostType postType,
    String? mediaUrl,
    DateTime? eventDate,
  }) async {
    final row = await _client
        .from('posts')
        .insert({
          'profile_id': profileId,
          'content': content,
          'post_type': postType.value,
          if (mediaUrl != null) 'media_url': mediaUrl,
          if (eventDate != null) 'event_date': eventDate.toIso8601String(),
        })
        .select('*, profiles!posts_profile_id_fkey(business_name, avatar_url)')
        .single();
    return Post.fromMap(row);
  }

  Future<void> deletePost(String id) async {
    await _client.from('posts').delete().eq('id', id);
  }
}
