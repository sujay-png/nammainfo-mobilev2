import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme.dart';
import '../../../models/profile.dart';

IconData iconForPlatform(String platform) {
  switch (platform) {
    case 'whatsapp':
      return Icons.chat_outlined;
    case 'instagram':
      return Icons.camera_alt_outlined;
    case 'facebook':
      return Icons.facebook_outlined;
    case 'youtube':
      return Icons.play_circle_outline;
    case 'linkedin':
      return Icons.business_center_outlined;
    default:
      return Icons.link;
  }
}

String labelForPlatform(SocialLink link) {
  if (link.platform == 'custom') return link.label ?? 'Link';
  return link.platform[0].toUpperCase() + link.platform.substring(1);
}

class SocialLinksSection extends StatelessWidget {
  final List<SocialLink> links;
  const SocialLinksSection({super.key, required this.links});

  @override
  Widget build(BuildContext context) {
    if (links.isEmpty) {
      return Text(
        'No social links added yet.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: links
          .map(
            (l) => InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => launchUrl(Uri.parse(l.url), mode: LaunchMode.externalApplication),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(iconForPlatform(l.platform), size: 16),
                    const SizedBox(width: 6),
                    Text(labelForPlatform(l), style: Theme.of(context).textTheme.labelLarge),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
