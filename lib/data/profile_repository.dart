import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';

class ProfileRepository {
  final SupabaseClient _client;
  ProfileRepository(this._client);

  Future<Profile?> getById(String id) async {
    final row =
        await _client.from('profiles').select().eq('id', id).maybeSingle();
    if (row == null) return null;
    return Profile.fromMap(row);
  }

  Future<Profile?> getBySlug(String slug) async {
    final row = await _client
        .from('profiles')
        .select()
        .eq('slug', slug)
        .maybeSingle();
    if (row == null) return null;
    return Profile.fromMap(row);
  }

  Future<Profile> updateOwn(String id, Map<String, dynamic> patch) async {
    final row = await _client
        .from('profiles')
        .update(patch)
        .eq('id', id)
        .select()
        .single();
    return Profile.fromMap(row);
  }

  /// Uploads to the `avatars` storage bucket under the user's own folder
  /// (matches typical `storage.objects` RLS keyed on `auth.uid()` as the
  /// first path segment) and returns the public URL. [prefix] distinguishes
  /// an owner photo ('avatar') from a company logo ('logo') within the same
  /// bucket/folder.
  Future<String> uploadAvatar(String userId, String localPath, {String prefix = 'avatar'}) async {
    final fileExt = localPath.split('.').last;
    final path =
        '$userId/${prefix}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

    await _client.storage.from('avatars').upload(
          path,
          File(localPath),
          fileOptions: const FileOptions(upsert: true),
        );

    return _client.storage.from('avatars').getPublicUrl(path);
  }
}
