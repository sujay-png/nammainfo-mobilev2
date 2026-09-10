import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/card.dart';

class CardRepository {
  final SupabaseClient _client;
  CardRepository(this._client);

  /// A profile can have more than one physical card issued over time
  /// (lost card, redesign, etc.) — this returns the active one.
  Future<BusinessCard?> getActiveForProfile(String profileId) async {
    final row = await _client
        .from('cards')
        .select()
        .eq('profile_id', profileId)
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (row == null) return null;
    return BusinessCard.fromMap(row);
  }

  Future<BusinessCard> getOrCreateForProfile(String profileId) async {
    final existing = await getActiveForProfile(profileId);
    if (existing != null) return existing;

    final row = await _client
        .from('cards')
        .insert({'profile_id': profileId})
        .select()
        .single();
    return BusinessCard.fromMap(row);
  }

  /// Public lookup by either the card's UUID (what's on the physical NFC
  /// chip / QR code) or its friendly `public_slug`. RLS only exposes
  /// active cards to anonymous readers.
  Future<BusinessCard?> getByIdOrSlug(String value) async {
    final isUuid = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    ).hasMatch(value);

    final row = await _client
        .from('cards')
        .select()
        .eq(isUuid ? 'id' : 'public_slug', value)
        .maybeSingle();
    if (row == null) return null;
    return BusinessCard.fromMap(row);
  }
}
