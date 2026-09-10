class ServiceItem {
  final String name;
  final String? description;
  final String? priceRange;
  final String? imageUrl;

  const ServiceItem({
    required this.name,
    this.description,
    this.priceRange,
    this.imageUrl,
  });

  factory ServiceItem.fromMap(Map<String, dynamic> map) => ServiceItem(
        name: map['name'] as String? ?? '',
        description: map['description'] as String?,
        priceRange: map['price_range'] as String?,
        imageUrl: map['image_url'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        if (description != null) 'description': description,
        if (priceRange != null) 'price_range': priceRange,
        if (imageUrl != null) 'image_url': imageUrl,
      };
}

class GalleryItem {
  final String imageUrl;
  final String? category;
  final String? label;

  const GalleryItem({required this.imageUrl, this.category, this.label});

  factory GalleryItem.fromMap(Map<String, dynamic> map) => GalleryItem(
        imageUrl: map['image_url'] as String? ?? '',
        category: map['category'] as String?,
        label: map['label'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'image_url': imageUrl,
        if (category != null) 'category': category,
        if (label != null) 'label': label,
      };
}

class BankAccount {
  final String label; // e.g. "GST billing", "Non-tax", "UPI"
  final String? accountName;
  final String? accountNumber;
  final String? ifsc;
  final String? upiId;

  const BankAccount({
    required this.label,
    this.accountName,
    this.accountNumber,
    this.ifsc,
    this.upiId,
  });

  factory BankAccount.fromMap(Map<String, dynamic> map) => BankAccount(
        label: map['label'] as String? ?? '',
        accountName: map['account_name'] as String?,
        accountNumber: map['account_number'] as String?,
        ifsc: map['ifsc'] as String?,
        upiId: map['upi_id'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'label': label,
        if (accountName != null) 'account_name': accountName,
        if (accountNumber != null) 'account_number': accountNumber,
        if (ifsc != null) 'ifsc': ifsc,
        if (upiId != null) 'upi_id': upiId,
      };
}

class SocialLink {
  final String platform; // whatsapp / instagram / facebook / youtube / linkedin / custom
  final String url;
  final String? label; // used when platform == 'custom'

  const SocialLink({required this.platform, required this.url, this.label});

  factory SocialLink.fromMap(Map<String, dynamic> map) => SocialLink(
        platform: map['platform'] as String? ?? 'custom',
        url: map['url'] as String? ?? '',
        label: map['label'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'platform': platform,
        'url': url,
        if (label != null) 'label': label,
      };
}

class Profile {
  final String id;
  final String? businessName;
  final String? ownerName;
  final String? jobTitle;
  final String? phone;
  final String? email;
  final String? website;
  final String? bio;
  final String? avatarUrl;
  final String? coverUrl;
  final String slug;
  final DateTime createdAt;

  // --- Extended "smart card" fields (Figma parity) ---
  // These are parsed defensively (default to empty/null) so the app keeps
  // working even before the matching Supabase columns/tables exist.
  final String? username;
  final bool isMember;
  final DateTime? membershipExpiresAt;

  final int? yearsInBusiness;
  final int? clientsServed;
  final String? coverageArea;

  final List<ServiceItem> services;
  final List<GalleryItem> gallery;
  final List<SocialLink> socialLinks;
  final List<BankAccount> bankAccounts;
  final String? googleReviewUrl;
  final String? brochureUrl;
  final String? address;
  final String? gstNumber;

  const Profile({
    required this.id,
    required this.slug,
    required this.createdAt,
    this.businessName,
    this.ownerName,
    this.jobTitle,
    this.phone,
    this.email,
    this.website,
    this.bio,
    this.avatarUrl,
    this.coverUrl,
    this.username,
    this.isMember = false,
    this.membershipExpiresAt,
    this.yearsInBusiness,
    this.clientsServed,
    this.coverageArea,
    this.services = const [],
    this.gallery = const [],
    this.socialLinks = const [],
    this.bankAccounts = const [],
    this.googleReviewUrl,
    this.brochureUrl,
    this.address,
    this.gstNumber,
  });

  /// How complete the profile is (0.0–1.0) — drives the free-account
  /// progress banner / ring, same as the Figma design.
  double get completion {
    final fields = <bool>[
      businessName?.isNotEmpty == true,
      ownerName?.isNotEmpty == true,
      jobTitle?.isNotEmpty == true,
      phone?.isNotEmpty == true,
      email?.isNotEmpty == true,
      website?.isNotEmpty == true,
      bio?.isNotEmpty == true,
      avatarUrl?.isNotEmpty == true,
      services.isNotEmpty,
      gallery.isNotEmpty,
      socialLinks.isNotEmpty,
      address?.isNotEmpty == true,
    ];
    final done = fields.where((f) => f).length;
    return done / fields.length;
  }

  factory Profile.fromMap(Map<String, dynamic> map) => Profile(
        id: map['id'] as String,
        businessName: map['business_name'] as String?,
        ownerName: map['owner_name'] as String?,
        jobTitle: map['job_title'] as String?,
        phone: map['phone'] as String?,
        email: map['email'] as String?,
        website: map['website'] as String?,
        bio: map['bio'] as String?,
        avatarUrl: map['avatar_url'] as String?,
        coverUrl: map['cover_url'] as String?,
        slug: map['slug'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        username: map['username'] as String?,
        isMember: map['is_member'] as bool? ?? false,
        membershipExpiresAt: map['membership_expires_at'] == null
            ? null
            : DateTime.tryParse(map['membership_expires_at'] as String),
        yearsInBusiness: map['years_in_business'] as int?,
        clientsServed: map['clients_served'] as int?,
        coverageArea: map['coverage_area'] as String?,
        services: (map['services'] as List<dynamic>?)
                ?.map((e) => ServiceItem.fromMap(e as Map<String, dynamic>))
                .toList() ??
            const [],
        gallery: (map['gallery'] as List<dynamic>?)
                ?.map((e) => GalleryItem.fromMap(e as Map<String, dynamic>))
                .toList() ??
            const [],
        socialLinks: (map['social_links'] as List<dynamic>?)
                ?.map((e) => SocialLink.fromMap(e as Map<String, dynamic>))
                .toList() ??
            const [],
        bankAccounts: (map['bank_accounts'] as List<dynamic>?)
                ?.map((e) => BankAccount.fromMap(e as Map<String, dynamic>))
                .toList() ??
            const [],
        googleReviewUrl: map['google_review_url'] as String?,
        brochureUrl: map['brochure_url'] as String?,
        address: map['address'] as String?,
        gstNumber: map['gst_number'] as String?,
      );

  Map<String, dynamic> toUpdateMap() => {
        if (businessName != null) 'business_name': businessName,
        if (ownerName != null) 'owner_name': ownerName,
        if (jobTitle != null) 'job_title': jobTitle,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        if (website != null) 'website': website,
        if (bio != null) 'bio': bio,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      };

  Profile copyWith({
    String? businessName,
    String? ownerName,
    String? jobTitle,
    String? phone,
    String? email,
    String? website,
    String? bio,
    String? avatarUrl,
    String? coverUrl,
    String? username,
    bool? isMember,
    DateTime? membershipExpiresAt,
    int? yearsInBusiness,
    int? clientsServed,
    String? coverageArea,
    List<ServiceItem>? services,
    List<GalleryItem>? gallery,
    List<SocialLink>? socialLinks,
    List<BankAccount>? bankAccounts,
    String? googleReviewUrl,
    String? brochureUrl,
    String? address,
    String? gstNumber,
  }) {
    return Profile(
      id: id,
      slug: slug,
      createdAt: createdAt,
      businessName: businessName ?? this.businessName,
      ownerName: ownerName ?? this.ownerName,
      jobTitle: jobTitle ?? this.jobTitle,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      username: username ?? this.username,
      isMember: isMember ?? this.isMember,
      membershipExpiresAt: membershipExpiresAt ?? this.membershipExpiresAt,
      yearsInBusiness: yearsInBusiness ?? this.yearsInBusiness,
      clientsServed: clientsServed ?? this.clientsServed,
      coverageArea: coverageArea ?? this.coverageArea,
      services: services ?? this.services,
      gallery: gallery ?? this.gallery,
      socialLinks: socialLinks ?? this.socialLinks,
      bankAccounts: bankAccounts ?? this.bankAccounts,
      googleReviewUrl: googleReviewUrl ?? this.googleReviewUrl,
      brochureUrl: brochureUrl ?? this.brochureUrl,
      address: address ?? this.address,
      gstNumber: gstNumber ?? this.gstNumber,
    );
  }
}
