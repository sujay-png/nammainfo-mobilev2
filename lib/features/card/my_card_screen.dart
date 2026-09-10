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
import '../../models/profile.dart';
import 'widgets/business_card_flip.dart';
import 'card_onboarding_wizard.dart';
import 'edit/section_edit_sheets.dart';
import 'trade_in/trade_in_sheet.dart';
import '../profile/widgets/accordion_section.dart';
import '../profile/widgets/about_stats_section.dart';
import '../profile/widgets/services_section.dart';
import '../profile/widgets/gallery_section.dart';
import '../profile/widgets/social_links_section.dart';
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

  // So the "you're almost done" membership nudge only interrupts once per
  // time the screen is open, not on every rebuild.
  bool _shownCompletionNudge = false;

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

  void _maybeShowCompletionNudge(Profile profile, int pct) {
    if (_shownCompletionNudge || profile.isMember || pct < 99) return;
    _shownCompletionNudge = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => const _BuyMembershipSheet(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(myProfileProvider);
    final cardAsync = ref.watch(_myCardProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
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

          // First-time users design their card before seeing anything else.
          if (!profile.cardDesigned) {
            return const CardOnboardingWizard();
          }

          return cardAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (card) {
              if (card == null) return const SizedBox.shrink();
              final url = Env.publicCardUrl(cardId: card.id, profileId: profile.id, publicSlug: card.publicSlug);
              final completionPct = (profile.completion * 100).round();
              _maybeShowCompletionNudge(profile, completionPct);

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                children: [
                  BusinessCardFlip(
                    profile: profile,
                    qrData: url,
                    nfcActive: card.physicalCardOrdered,
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Tap the card to flip it',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),

                  // Free-account completion banner (Figma: non-member flow).
                  if (!profile.isMember) ...[
                    const SizedBox(height: 16),
                    _CompletionBanner(pct: completionPct),
                  ],

                  const SizedBox(height: 16),
                  _SharePanel(
                    url: url,
                    tapCount: card.tapCount,
                    physicalCardOrdered: card.physicalCardOrdered,
                    writing: _writing,
                    onWriteToCard: () => _writeToPhysicalCard(url),
                  ),

                  const SizedBox(height: 16),
                  _TradeInPromo(onTap: () => showTradeInSheet(context, profile)),

                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Text('Card details', style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      Text(
                        'Tap ✎ to edit a section',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  AccordionSection(
                    title: 'About us',
                    icon: Icons.info_outline,
                    onEdit: () => showAboutEditSheet(context, ref, profile),
                    child: AboutStatsSection(profile: profile),
                  ),
                  AccordionSection(
                    title: 'Services & products',
                    icon: Icons.storefront_outlined,
                    count: profile.services.length,
                    onEdit: () => showServicesEditSheet(context, ref, profile),
                    child: ServicesSection(
                      services: profile.services,
                      businessName: profile.businessName,
                    ),
                  ),
                  AccordionSection(
                    title: 'Gallery',
                    icon: Icons.photo_library_outlined,
                    count: profile.gallery.length,
                    onEdit: () => showGalleryEditSheet(context, ref, profile),
                    child: GallerySection(items: profile.gallery),
                  ),
                  AccordionSection(
                    title: 'Social links',
                    icon: Icons.share_outlined,
                    count: profile.socialLinks.length,
                    onEdit: () => showSocialLinksEditSheet(context, ref, profile),
                    child: SocialLinksSection(links: profile.socialLinks),
                  ),
                  AccordionSection(
                    title: 'Banking info',
                    icon: Icons.account_balance_outlined,
                    count: profile.bankAccounts.length,
                    onEdit: () => showBankingEditSheet(context, ref, profile),
                    child: BankingSection(accounts: profile.bankAccounts),
                  ),
                  AccordionSection(
                    title: 'Downloads & actions',
                    icon: Icons.download_outlined,
                    onEdit: () => showBrochureEditSheet(context, ref, profile),
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

/// Groups the QR code, share/copy actions and (once ordered) the NFC-write
/// action into one visually cohesive card, instead of loose full-width
/// buttons floating in whitespace.
class _SharePanel extends StatelessWidget {
  final String url;
  final int tapCount;
  final bool physicalCardOrdered;
  final bool writing;
  final VoidCallback onWriteToCard;

  const _SharePanel({
    required this.url,
    required this.tapCount,
    required this.physicalCardOrdered,
    required this.writing,
    required this.onWriteToCard,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => _showEnlargedQr(context, url),
                child: Hero(
                  tag: 'card-qr-$url',
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: QrImageView(
                      data: url,
                      size: 96,
                      backgroundColor: Colors.transparent,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: AppColors.black,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Share your card', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Anyone can scan this to open your card — works\neven on phones without NFC.',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tapped $tapCount time${tapCount == 1 ? '' : 's'}',
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Share.share(url),
                  icon: const Icon(Icons.ios_share, size: 16),
                  label: const Text('Share'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: url));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link copied')),
                      );
                    }
                  },
                  icon: const Icon(Icons.link, size: 16),
                  label: const Text('Copy link'),
                ),
              ),
            ],
          ),
          // A physical NFC chip only exists once the user has ordered
          // one — nothing to write to before that, so this stays hidden
          // until then.
          if (physicalCardOrdered) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: writing ? null : onWriteToCard,
                icon: writing
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.nfc, size: 18),
                label: Text(writing ? 'Hold card near phone…' : 'Write to physical NFC card'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showEnlargedQr(BuildContext context, String url) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.001), // scrim animates in via transitionBuilder
        pageBuilder: (context, animation, secondaryAnimation) {
          return _EnlargedQrDialog(url: url, animation: animation);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn);
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: Container(
              color: Colors.black.withValues(alpha: 0.7 * animation.value.clamp(0.0, 1.0)),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.7, end: 1).animate(curved),
                child: child,
              ),
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 380),
        reverseTransitionDuration: const Duration(milliseconds: 260),
      ),
    );
  }
}

/// Full-screen enlarged QR shown after tapping the small preview — grows out
/// of the same Hero so the transition feels like the code is expanding in
/// place rather than a plain dialog popping up.
class _EnlargedQrDialog extends StatelessWidget {
  final String url;
  final Animation<double> animation;
  const _EnlargedQrDialog({required this.url, required this.animation});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: GestureDetector(
            onTap: () {}, // absorb taps on the card itself
            child: Hero(
              tag: 'card-qr-$url',
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 36),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadii.xl),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 40,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    QrImageView(
                      data: url,
                      size: 240,
                      backgroundColor: Colors.transparent,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: AppColors.black,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Scan to open my card',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap anywhere to close',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.gray400),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Catchy promo card for the "send us your old card, get it upgraded to
/// NFC and delivered" service.
class _TradeInPromo extends StatelessWidget {
  final VoidCallback onTap;
  const _TradeInPromo({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.black,
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Got an old business card?',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Turn it smart — we\'ll add an NFC tag & deliver it to your door.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
          ],
        ),
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
        color: AppColors.white,
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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showMembershipSheet(context),
              child: const Text('Activate membership', style: TextStyle(fontSize: 12)),
            ),
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
              Expanded(
                child: Text('You\'re almost done!', style: theme.textTheme.headlineSmall),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Activate membership to unlock the last bit of your card.',
            style: theme.textTheme.bodyMedium,
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
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Maybe later'),
          ),
        ],
      ),
    );
  }
}