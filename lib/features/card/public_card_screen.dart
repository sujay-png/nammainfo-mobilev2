import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers.dart';
import '../../models/profile.dart';
import '../profile/widgets/live_card_preview.dart';
import '../connections/save_connection_sheet.dart';

/// Route target for both `nammainfo://profile/:profileId` and
/// `https://nammainfo.com/c/:cardId` deep links (see core/router.dart).
class PublicCardScreen extends ConsumerWidget {
  final String? cardIdOrSlug;
  final String? profileId;

  const PublicCardScreen({super.key, this.cardIdOrSlug, this.profileId});

  Future<Profile?> _resolve(WidgetRef ref) async {
    if (profileId != null) {
      return ref.read(profileRepositoryProvider).getById(profileId!);
    }
    if (cardIdOrSlug != null) {
      final card = await ref.read(cardRepositoryProvider).getByIdOrSlug(cardIdOrSlug!);
      if (card == null) return null;
      return ref.read(profileRepositoryProvider).getById(card.profileId);
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Business card')),
      body: FutureBuilder<Profile?>(
        future: _resolve(ref),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final profile = snapshot.data;
          if (profile == null) {
            return const Center(child: Text('This card couldn\'t be found.'));
          }

          final myId = ref.watch(currentUserIdProvider);
          final isOwnCard = myId != null && myId == profile.id;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              LiveCardPreview(profile: profile),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (profile.phone != null)
                    _QuickAction(
                      icon: Icons.call_outlined,
                      label: 'Call',
                      onTap: () => launchUrl(Uri.parse('tel:${profile.phone}')),
                    ),
                  if (profile.email != null)
                    _QuickAction(
                      icon: Icons.mail_outline,
                      label: 'Email',
                      onTap: () => launchUrl(Uri.parse('mailto:${profile.email}')),
                    ),
                  if (profile.website != null)
                    _QuickAction(
                      icon: Icons.public,
                      label: 'Website',
                      onTap: () => launchUrl(
                        Uri.parse(profile.website!),
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
                ],
              ),
              if (profile.bio != null) ...[
                const SizedBox(height: 16),
                Text(profile.bio!, style: Theme.of(context).textTheme.bodyMedium),
              ],
              const SizedBox(height: 24),
              if (!isOwnCard && myId != null)
                ElevatedButton.icon(
                  icon: const Icon(Icons.person_add_alt_1, size: 18),
                  label: const Text('Save connection'),
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => SaveConnectionSheet(profile: profile),
                  ),
                ),
              if (myId == null)
                Text(
                  'Sign in to save this connection to your network.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, size: 20),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}
