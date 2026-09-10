class BusinessCard {
  final String id;
  final String profileId;
  final String publicSlug;
  final bool isActive;
  final int tapCount;
  final DateTime createdAt;

  const BusinessCard({
    required this.id,
    required this.profileId,
    required this.publicSlug,
    required this.isActive,
    required this.tapCount,
    required this.createdAt,
  });

  factory BusinessCard.fromMap(Map<String, dynamic> map) => BusinessCard(
        id: map['id'] as String,
        profileId: map['profile_id'] as String,
        publicSlug: map['public_slug'] as String,
        isActive: map['is_active'] as bool,
        tapCount: map['tap_count'] as int,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  /// The URL written to the physical NFC chip / encoded in the QR code.
  String universalLink(String siteUrl) => '$siteUrl/c/$id';
}
