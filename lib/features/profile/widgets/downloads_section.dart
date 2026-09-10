import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/profile.dart';

class DownloadsSection extends StatelessWidget {
  final Profile profile;
  final String publicUrl;
  final VoidCallback onSaveToContacts;

  const DownloadsSection({
    super.key,
    required this.profile,
    required this.publicUrl,
    required this.onSaveToContacts,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActionTile(
          icon: Icons.badge_outlined,
          label: 'Download my profile card (image)',
          onTap: () => Share.share(publicUrl),
        ),
        if (profile.brochureUrl != null)
          _ActionTile(
            icon: Icons.picture_as_pdf_outlined,
            label: 'Download brochure',
            onTap: () => launchUrl(Uri.parse(profile.brochureUrl!), mode: LaunchMode.externalApplication),
          ),
        _ActionTile(
          icon: Icons.contact_page_outlined,
          label: 'Save to contacts',
          onTap: onSaveToContacts,
        ),
        _ActionTile(
          icon: Icons.ios_share,
          label: 'Share my card',
          onTap: () => Share.share(publicUrl),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 20),
      title: Text(label, style: Theme.of(context).textTheme.titleSmall),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    );
  }
}
