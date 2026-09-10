import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../models/post.dart';

class PostCard extends StatelessWidget {
  final Post post;
  const PostCard({super.key, required this.post});

  Color _badgeColor(PostType type) => switch (type) {
        PostType.event => AppColors.accent,
        PostType.announcement => AppColors.brand500,
        PostType.update => AppColors.inkMuted,
      };

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat('MMM d').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: post.authorAvatarUrl != null
                    ? CachedNetworkImage(
                        imageUrl: post.authorAvatarUrl!,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 36,
                        height: 36,
                        color: AppColors.surface,
                        alignment: Alignment.center,
                        child: Text(
                          (post.authorName?.isNotEmpty == true
                                  ? post.authorName![0]
                                  : 'N')
                              .toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  post.authorName ?? 'Namma Info member',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                _timeAgo(post.createdAt),
                style: const TextStyle(fontSize: 11, color: AppColors.inkMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _badgeColor(post.postType).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              post.postType.label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: _badgeColor(post.postType),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(post.content, style: const TextStyle(fontSize: 14, height: 1.4)),
          if (post.mediaUrl != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: CachedNetworkImage(
                imageUrl: post.mediaUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 200,
              ),
            ),
          ],
          if (post.postType == PostType.event && post.eventDate != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.event_outlined, size: 15, color: AppColors.inkMuted),
                const SizedBox(width: 6),
                Text(
                  DateFormat('EEE, MMM d · h:mm a').format(post.eventDate!),
                  style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
