import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme.dart';
import '../../../models/profile.dart';

class LiveCardPreview extends StatelessWidget {
  final Profile profile;
  const LiveCardPreview({super.key, required this.profile});

  String _initials() {
    final name = profile.ownerName?.trim();
    if (name == null || name.isEmpty) return 'NI';
    final parts = name.split(RegExp(r'\s+')).take(2);
    return parts.map((p) => p.isNotEmpty ? p[0].toUpperCase() : '').join();
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = [profile.jobTitle, profile.businessName]
        .where((s) => s != null && s.isNotEmpty)
        .join(' · ');

    return AspectRatio(
      aspectRatio: 1.6,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.xl),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.brand900, AppColors.brand700, AppColors.ink800],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'DIGITAL BUSINESS CARD',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.6,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'NAMMA INFO',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: profile.avatarUrl != null
                      ? CachedNetworkImage(
                          imageUrl: profile.avatarUrl!,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 52,
                          height: 52,
                          color: Colors.white.withValues(alpha: 0.1),
                          alignment: Alignment.center,
                          child: Text(
                            _initials(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.ownerName?.isNotEmpty == true
                            ? profile.ownerName!
                            : 'Your name',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle.isNotEmpty ? subtitle : 'Your business',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
