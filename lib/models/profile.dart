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
  final String slug;
  final DateTime createdAt;

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
  });

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
        slug: map['slug'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
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
    );
  }
}
