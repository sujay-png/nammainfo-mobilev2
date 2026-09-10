import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

import '../../core/providers.dart';
import '../../core/env.dart';
import '../../core/theme.dart';
import '../../models/card.dart';
import '../profile/widgets/live_card_preview.dart';
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
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).pushNamed('/profile/edit'),
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
              final url = '${Env.siteUrl}/c/${card.id}';

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  LiveCardPreview(profile: profile),
                  const SizedBox(height: 28),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: QrImageView(
                        data: url,
                        size: 180,
                        backgroundColor: Colors.white,
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
                ],
              );
            },
          );
        },
      ),
    );
  }
}
