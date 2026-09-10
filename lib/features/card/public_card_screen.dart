import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme.dart';
import '../../core/providers.dart';
import '../../models/profile.dart';
import '../profile/widgets/live_card_preview.dart';
import '../connections/save_connection_sheet.dart';
import '../contacts/save_to_device_contacts.dart';

/// Route target for both `nammainfo://profile/:profileId` and
/// `https://nammainfo.com/c/:cardId` deep links (see core/router.dart).
/// This is the screen someone sees the instant they tap an NFC card or
/// scan a QR code — mirrors the Figma "NFC/QR landing" screen.
class PublicCardScreen extends ConsumerStatefulWidget {
  final String? cardIdOrSlug;
  final String? profileId;

  const PublicCardScreen({super.key, this.cardIdOrSlug, this.profileId});

  @override
  ConsumerState<PublicCardScreen> createState() => _PublicCardScreenState();
}

class _PublicCardScreenState extends ConsumerState<PublicCardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  Future<Profile?> _resolve(WidgetRef ref) async {
    if (widget.profileId != null) {
      return ref.read(profileRepositoryProvider).getById(widget.profileId!);
    }
    if (widget.cardIdOrSlug != null) {
      final card =
          await ref.read(cardRepositoryProvider).getByIdOrSlug(widget.cardIdOrSlug!);
      if (card == null) return null;
      return ref.read(profileRepositoryProvider).getById(card.profileId);
    }
    return null;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          final isFreshTap = myId == null; // not signed in => a real "tap" landing

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (isFreshTap) ...[
                Center(
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final t = _pulseController.value;
                      return SizedBox(
                        width: 72,
                        height: 72,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Opacity(
                              opacity: (1 - t).clamp(0, 1),
                              child: Transform.scale(
                                scale: 1 + t * 0.8,
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.black, width: 1.4),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: 56,
                              height: 56,
                              decoration: const BoxDecoration(
                                color: AppColors.black,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.nfc, color: Colors.white, size: 26),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'You tapped ${profile.ownerName ?? 'a'}\'s NFC card',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
              ],

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

              if (isFreshTap) ...[
                ElevatedButton.icon(
                  icon: const Icon(Icons.download_outlined, size: 18),
                  label: const Text('Download Namma Info'),
                  onPressed: () => launchUrl(
                    Uri.parse(
                      Theme.of(context).platform == TargetPlatform.iOS
                          ? 'https://apps.apple.com/'
                          : 'https://play.google.com/store',
                    ),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  icon: const Icon(Icons.contact_page_outlined, size: 18),
                  label: const Text('Skip & save to contacts'),
                  onPressed: () => saveProfileToDeviceContacts(context, profile),
                ),
              ],

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
