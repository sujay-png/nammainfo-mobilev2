enum PostType { announcement, event, update }

extension PostTypeX on PostType {
  String get value => switch (this) {
        PostType.announcement => 'announcement',
        PostType.event => 'event',
        PostType.update => 'update',
      };

  String get label => switch (this) {
        PostType.announcement => 'Announcement',
        PostType.event => 'Event',
        PostType.update => 'Update',
      };

  static PostType fromValue(String value) => switch (value) {
        'event' => PostType.event,
        'update' => PostType.update,
        _ => PostType.announcement,
      };
}

class Post {
  final String id;
  final String profileId;
  final String content;
  final PostType postType;
  final String? mediaUrl;
  final DateTime? eventDate;
  final DateTime createdAt;

  // Joined author fields — populated by PostsRepository, not the raw table.
  final String? authorName;
  final String? authorAvatarUrl;

  const Post({
    required this.id,
    required this.profileId,
    required this.content,
    required this.postType,
    required this.createdAt,
    this.mediaUrl,
    this.eventDate,
    this.authorName,
    this.authorAvatarUrl,
  });

  factory Post.fromMap(Map<String, dynamic> map) => Post(
        id: map['id'] as String,
        profileId: map['profile_id'] as String,
        content: map['content'] as String,
        postType: PostTypeX.fromValue(map['post_type'] as String),
        mediaUrl: map['media_url'] as String?,
        eventDate: map['event_date'] == null
            ? null
            : DateTime.parse(map['event_date'] as String),
        createdAt: DateTime.parse(map['created_at'] as String),
        authorName: (map['profiles'] as Map<String, dynamic>?)?['business_name']
            as String?,
        authorAvatarUrl:
            (map['profiles'] as Map<String, dynamic>?)?['avatar_url'] as String?,
      );
}
