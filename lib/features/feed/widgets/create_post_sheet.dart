import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../models/post.dart';

class CreatePostSheet extends ConsumerStatefulWidget {
  const CreatePostSheet({super.key});

  @override
  ConsumerState<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends ConsumerState<CreatePostSheet> {
  final _contentCtrl = TextEditingController();
  PostType _type = PostType.announcement;
  DateTime? _eventDate;
  bool _posting = false;

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickEventDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;
    setState(() {
      _eventDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    final content = _contentCtrl.text.trim();
    if (content.isEmpty) return;
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    setState(() => _posting = true);
    try {
      await ref.read(postsRepositoryProvider).createPost(
            profileId: userId,
            content: content,
            postType: _type,
            eventDate: _type == PostType.event ? _eventDate : null,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _posting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Couldn\'t post: $e')),
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
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 18),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Text('New post', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            children: PostType.values.map((t) {
              final selected = _type == t;
              return ChoiceChip(
                label: Text(t.label),
                selected: selected,
                onSelected: (_) => setState(() => _type = t),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _contentCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: switch (_type) {
                PostType.event => 'What\'s the event about?',
                PostType.announcement => 'Share an announcement…',
                PostType.update => 'What\'s new at your business?',
              },
            ),
          ),
          if (_type == PostType.event) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickEventDate,
              icon: const Icon(Icons.event_outlined, size: 18),
              label: Text(
                _eventDate == null
                    ? 'Set event date & time'
                    : _eventDate.toString(),
              ),
            ),
          ],
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _posting ? null : _submit,
            child: _posting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Post'),
          ),
        ],
      ),
    );
  }
}
