import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme.dart';
import '../../core/providers.dart';
import '../../models/profile.dart';
import 'contacts_tags.dart';

final _tagsStoreProvider = Provider((ref) => ContactsTagsStore());

final _connectionsProvider = FutureProvider.autoDispose<List<Profile>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  final ids = await ref.read(connectionsRepositoryProvider).myConnectionIds(userId);
  final repo = ref.read(profileRepositoryProvider);
  final profiles = await Future.wait(ids.map(repo.getById));
  return profiles.whereType<Profile>().toList();
});

/// "Scanned Contacts" tab — searchable list of saved connections with a
/// tag/folder system (Client / Prospect / Vendor / Partner), matching
/// the Figma design.
class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

String _initial(String? name) {
  final trimmed = name?.trim();
  if (trimmed == null || trimmed.isEmpty) return '?';
  return trimmed[0].toUpperCase();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  String _query = '';
  String _folder = 'All';
  Map<String, String?> _tags = {};
  List<String> _customFolders = [];

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    final store = ref.read(_tagsStoreProvider);
    final custom = await store.customFolders();
    if (mounted) setState(() => _customFolders = custom);
  }

  Future<void> _assignFolder(Profile p) async {
    final store = ref.read(_tagsStoreProvider);
    final current = await store.tagFor(p.id);
    if (!mounted) return;
    final folders = [...ContactsTagsStore.defaultFolders, ..._customFolders];

    final chosen = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ...folders.map(
              (f) => ListTile(
                title: Text(f),
                trailing: current == f ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(context).pop(f),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.remove_circle_outline),
              title: const Text('Remove folder'),
              onTap: () => Navigator.of(context).pop(''),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (chosen == null) return;
    await store.setTag(p.id, chosen.isEmpty ? null : chosen);
    setState(() => _tags[p.id] = chosen.isEmpty ? null : chosen);
  }

  Future<void> _newFolder() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New folder'),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(ctrl.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    await ref.read(_tagsStoreProvider).addCustomFolder(name);
    await _loadTags();
  }

  @override
  Widget build(BuildContext context) {
    final connectionsAsync = ref.watch(_connectionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            onPressed: _newFolder,
          ),
        ],
      ),
      body: connectionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (contacts) {
          final folders = ['All', ...ContactsTagsStore.defaultFolders, ..._customFolders];
          final filtered = contacts.where((p) {
            final matchesQuery = _query.isEmpty ||
                (p.ownerName ?? '').toLowerCase().contains(_query.toLowerCase()) ||
                (p.businessName ?? '').toLowerCase().contains(_query.toLowerCase());
            final matchesFolder = _folder == 'All' || _tags[p.id] == _folder;
            return matchesQuery && matchesFolder;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search contacts',
                    prefixIcon: Icon(Icons.search, size: 20),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: folders.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final f = folders[i];
                    final count = f == 'All'
                        ? contacts.length
                        : contacts.where((p) => _tags[p.id] == f).length;
                    return ChoiceChip(
                      label: Text(f == 'All' ? f : '$f ($count)'),
                      selected: _folder == f,
                      onSelected: (_) => setState(() => _folder = f),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No contacts yet — scan or tap a card to save one.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final p = filtered[i];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.gray100,
                              backgroundImage: p.avatarUrl != null
                                  ? CachedNetworkImageProvider(p.avatarUrl!)
                                  : null,
                              child: p.avatarUrl == null
                                  ? Text(_initial(p.ownerName ?? p.businessName))
                                  : null,
                            ),
                            title: Text(p.ownerName ?? p.businessName ?? 'Unknown'),
                            subtitle: Text(
                              [p.jobTitle, p.businessName].where((s) => s?.isNotEmpty == true).join(' · '),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (p.phone != null)
                                  IconButton(
                                    icon: const Icon(Icons.call_outlined, size: 20),
                                    onPressed: () => launchUrl(Uri.parse('tel:${p.phone}')),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.folder_outlined, size: 20),
                                  onPressed: () => _assignFolder(p),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
