import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../models/profile.dart';
import '../profile/widgets/live_card_preview.dart';

class SaveConnectionSheet extends ConsumerStatefulWidget {
  final Profile profile;
  const SaveConnectionSheet({super.key, required this.profile});

  @override
  ConsumerState<SaveConnectionSheet> createState() => _SaveConnectionSheetState();
}

class _SaveConnectionSheetState extends ConsumerState<SaveConnectionSheet> {
  bool _saving = false;
  bool _saved = false;

  Future<void> _save() async {
    final myId = ref.read(currentUserIdProvider);
    if (myId == null) return;

    setState(() => _saving = true);
    try {
      await ref.read(connectionsRepositoryProvider).saveConnection(
            userId: myId,
            connectedUserId: widget.profile.id,
          );
      setState(() {
        _saving = false;
        _saved = true;
      });
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Couldn\'t save: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 20),
          LiveCardPreview(profile: widget.profile),
          const SizedBox(height: 18),
          Text(
            _saved ? 'Saved to your connections' : 'Save this connection?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            _saved
                ? 'You\'ll see their updates in your feed.'
                : 'You\'ll follow their business updates and events in your feed.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          if (!_saved)
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save connection'),
            )
          else
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
        ],
      ),
    );
  }
}
