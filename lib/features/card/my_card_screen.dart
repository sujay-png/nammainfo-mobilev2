import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/env.dart';
import '../../core/theme.dart';
import '../../models/card.dart';
import '../profile/widgets/live_card_preview.dart';
import '../profile/widgets/accordion_section.dart';
import '../profile/widgets/about_stats_section.dart';
import '../profile/widgets/services_section.dart';
import '../profile/widgets/gallery_section.dart';
import '../profile/widgets/social_links_section.dart';
import '../profile/widgets/reviews_section.dart';
import '../profile/widgets/banking_section.dart';
import '../profile/widgets/downloads_section.dart';
import '../contacts/save_to_device_contacts.dart';
import '../nfc/nfc_service.dart';

final _nfcServiceProvider = Provider((ref) => NfcService());

final _myCardProvider = FutureProvider.autoDispose<BusinessCard?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return ref.watch(cardRepositoryProvider).getOrCreateForProfile(userId);
});

class MyCardScreen extends ConsumerStatefulWidget {
  const MyCardScreen({super.key});

  @override
  ConsumerState<MyCardScreen> createState() => _MyCardScreenState();
}

class _MyCardScreenState extends ConsumerState<MyCardScreen> {
  bool _writing = false;

  Future<void> _writeToPhysicalCard(String url) async {
    setState(() => _writing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      messenger.showSnackBar(
        const SnackBar(content: Text('Hold a blank NFC card to the back of your phone…')),
      );
      await ref.read(_nfcServiceProvider).writeCardUri(url);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('Card written successfully ✓')),
      );
    } on NfcUnavailableException catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } on NfcWriteException catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(const SnackBar(
        content: Text('Something went wrong while writing the card.'),
      ));
    } finally {
      if (mounted) setState(() => _writing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(myProfileProvider);
    final cardAsync = ref.watch(_myCardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Card'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Edit card',
            onPressed: () => context.push('/profile/edit'),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (profile) {
          if (profile == null) return const SizedBox.shrink();

          return cardAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (card) {
              if (card == null) return const SizedBox.shrink();
              final url = Env.publicCardUrl(cardId: card.id, profileId: profile.id, publicSlug: card.publicSlug);
              final completionPct = (profile.completion * 100).round();

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                children: [
                  LiveCardPreview(profile: profile),

                  // Free-account completion banner (Figma: non-member flow).
                  if (!profile.isMember) ...[
                    const SizedBox(height: 16),
                    _CompletionBanner(pct: completionPct),
                  ],

                  const SizedBox(height: 24),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: QrImageView(
                        data: url,
                        size: 180,
                        backgroundColor: Colors.transparent,
                        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square),
                        dataModuleStyle:
                            const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Anyone can scan this to open your card — works even on\n'
                    'phones without NFC.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _writing ? null : () => _writeToPhysicalCard(url),
                    icon: _writing
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.nfc, size: 18),
                    label: Text(_writing ? 'Hold card near phone…' : 'Write to physical NFC card'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => Share.share(url),
                    icon: const Icon(Icons.ios_share, size: 18),
                    label: const Text('Share my card'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: url));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Link copied')),
                        );
                      }
                    },
                    icon: const Icon(Icons.link, size: 18),
                    label: const Text('Copy link'),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      'Tapped ${card.tapCount} time${card.tapCount == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),

                  const SizedBox(height: 28),
                  Text('Card details', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),

                  AccordionSection(
                    title: 'About us',
                    icon: Icons.info_outline,
                    child: AboutStatsSection(profile: profile),
                  ),
                  AccordionSection(
                    title: 'Services & products',
                    icon: Icons.storefront_outlined,
                    count: profile.services.length,
                    child: ServicesSection(
                      services: profile.services,
                      businessName: profile.businessName,
                    ),
                  ),
                  AccordionSection(
                    title: 'Gallery',
                    icon: Icons.photo_library_outlined,
                    count: profile.gallery.length,
                    child: GallerySection(items: profile.gallery),
                  ),
                  AccordionSection(
                    title: 'Social links',
                    icon: Icons.share_outlined,
                    count: profile.socialLinks.length,
                    child: SocialLinksSection(links: profile.socialLinks),
                  ),
                  AccordionSection(
                    title: 'Google reviews',
                    icon: Icons.star_outline,
                    child: ReviewsSection(googleReviewUrl: profile.googleReviewUrl),
                  ),
                  AccordionSection(
                    title: 'Banking info',
                    icon: Icons.account_balance_outlined,
                    count: profile.bankAccounts.length,
                    child: BankingSection(accounts: profile.bankAccounts),
                  ),
                  AccordionSection(
                    title: 'Downloads & actions',
                    icon: Icons.download_outlined,
                    child: DownloadsSection(
                      profile: profile,
                      publicUrl: url,
                      onSaveToContacts: () => saveProfileToDeviceContacts(context, profile),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _CompletionBanner extends StatelessWidget {
  final int pct;
  const _CompletionBanner({required this.pct});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Card completion', style: theme.textTheme.titleSmall),
              Text('$pct%', style: theme.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 6,
              backgroundColor: AppColors.gray200,
              valueColor: const AlwaysStoppedAnimation(AppColors.black),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: pct >= 80
                      ? () {}
                      : null,
                  child: const Text('Preview card', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showMembershipSheet(context),
                  child: const Text('Activate membership', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMembershipSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _BuyMembershipSheet(),
    );
  }
}

class _BuyMembershipSheet extends StatelessWidget {
  const _BuyMembershipSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const features = [
      'Custom @username & shareable link',
      'Unlimited services, gallery & reviews',
      'Priority support',
      'Advanced card analytics',
    ];
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Namma Info membership', style: theme.textTheme.headlineSmall),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('₹999 / year', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.check, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(f, style: theme.textTheme.bodyMedium)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              // TODO: wire to your payment gateway, then set profiles.is_member = true.
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payments aren\'t wired up yet — connect a gateway to enable this.')),
              );
            },
            child: const Text('Continue to payment'),
          ),
        ],
      ),
    );
  }
}
