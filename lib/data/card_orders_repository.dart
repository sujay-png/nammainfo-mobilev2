import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Submissions for the "trade in your old card" flow — the customer
/// uploads a photo of an existing physical card and a delivery address;
/// we manually confirm pricing/delivery and fulfil it (no payment
/// gateway wired up yet, see CardTradeInSheet).
class CardOrdersRepository {
  final SupabaseClient _client;
  CardOrdersRepository(this._client);

  Future<String> uploadOldCardPhoto(String userId, String localPath) async {
    final fileExt = localPath.split('.').last;
    final path = '$userId/old_card_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    await _client.storage.from('avatars').upload(
          path,
          File(localPath),
          fileOptions: const FileOptions(upsert: true),
        );
    return _client.storage.from('avatars').getPublicUrl(path);
  }

  Future<void> submit({
    required String userId,
    String? oldCardPhotoUrl,
    required String deliveryAddress,
    String? phone,
    String? notes,
  }) async {
    await _client.from('card_orders').insert({
      'user_id': userId,
      if (oldCardPhotoUrl != null) 'old_card_photo_url': oldCardPhotoUrl,
      'delivery_address': deliveryAddress,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
  }
}
