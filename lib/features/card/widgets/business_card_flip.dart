import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../models/profile.dart';
import '../../profile/widgets/social_links_section.dart' show iconForPlatform;

// ---------------------------------------------------------------------------
// Shared chrome
// ---------------------------------------------------------------------------

Future<void> _showEditSheet(BuildContext context, Widget child) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: FractionallySizedBox(
        heightFactor: 0.9,
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
          ),
          child: child,
        ),
      ),
    ),
  );
}

class _SheetScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final VoidCallback? onSave;
  final bool saving;

  const _SheetScaffold({
    required this.title,
    required this.body,
    required this.onSave,
    required this.saving,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.gray300,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: body,
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: ElevatedButton(
              onPressed: saving ? null : onSave,
              child: saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save'),
            ),
          ),
        ),
      ],
    );
  }
}

class _TextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int maxLines;

  const _TextField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final Widget child;
  final VoidCallback onDelete;
  const _ItemCard({required this.child, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: onDelete,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.delete_outline, size: 18, color: AppColors.gray500),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AddButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.add, size: 18),
      label: Text(label),
    );
  }
}

/// Returns true on success, false on failure (and shows the error instead
/// of failing silently — a save that neither closes the sheet nor tells
/// the user why looks exactly like "nothing got saved").
Future<bool> _saveAndClose(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> patch,
) async {
  final userId = ref.read(currentUserIdProvider);
  if (userId == null) return false;
  try {
    await ref.read(profileRepositoryProvider).updateOwn(userId, patch);
    ref.invalidate(myProfileProvider);
    if (context.mounted) Navigator.of(context).pop();
    return true;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Couldn\'t save: $e')),
      );
    }
    return false;
  }
}

// ---------------------------------------------------------------------------
// About us
// ---------------------------------------------------------------------------

void showAboutEditSheet(BuildContext context, WidgetRef ref, Profile profile) {
  _showEditSheet(context, _AboutEditBody(profile: profile));
}

class _AboutEditBody extends ConsumerStatefulWidget {
  final Profile profile;
  const _AboutEditBody({required this.profile});

  @override
  ConsumerState<_AboutEditBody> createState() => _AboutEditBodyState();
}

class _AboutEditBodyState extends ConsumerState<_AboutEditBody> {
  late final _bioCtrl = TextEditingController(text: widget.profile.bio ?? '');
  late final _yearsCtrl =
      TextEditingController(text: widget.profile.yearsInBusiness?.toString() ?? '');
  late final _clientsCtrl =
      TextEditingController(text: widget.profile.clientsServed?.toString() ?? '');
  late final _coverageCtrl = TextEditingController(text: widget.profile.coverageArea ?? '');
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    await _saveAndClose(context, ref, {
      'bio': _bioCtrl.text.trim(),
      'years_in_business': int.tryParse(_yearsCtrl.text.trim()),
      'clients_served': int.tryParse(_clientsCtrl.text.trim()),
      'coverage_area': _coverageCtrl.text.trim(),
    });
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: 'About us',
      saving: _saving,
      onSave: _save,
      body: Column(
        children: [
          _TextField(label: 'Short description', controller: _bioCtrl, maxLines: 4),
          _TextField(
            label: 'Years in business',
            controller: _yearsCtrl,
            keyboardType: TextInputType.number,
          ),
          _TextField(
            label: 'Clients served',
            controller: _clientsCtrl,
            keyboardType: TextInputType.number,
          ),
          _TextField(label: 'Coverage area', controller: _coverageCtrl),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Services & products
// ---------------------------------------------------------------------------

void showServicesEditSheet(BuildContext context, WidgetRef ref, Profile profile) {
  _showEditSheet(context, _ServicesEditBody(profile: profile));
}

class _ServicesEditBody extends ConsumerStatefulWidget {
  final Profile profile;
  const _ServicesEditBody({required this.profile});

  @override
  ConsumerState<_ServicesEditBody> createState() => _ServicesEditBodyState();
}

class _ServicesEditBodyState extends ConsumerState<_ServicesEditBody> {
  late List<_ServiceDraft> _items =
      widget.profile.services.map(_ServiceDraft.from).toList();
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    final services = _items
        .where((d) => d.nameCtrl.text.trim().isNotEmpty)
        .map((d) => ServiceItem(
              name: d.nameCtrl.text.trim(),
              description: d.descCtrl.text.trim().isEmpty ? null : d.descCtrl.text.trim(),
              priceRange: d.priceCtrl.text.trim().isEmpty ? null : d.priceCtrl.text.trim(),
              imageUrl: d.imageUrl,
            ).toMap())
        .toList();
    await _saveAndClose(context, ref, {'services': services});
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: 'Services & products',
      saving: _saving,
      onSave: _save,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in _items)
            _ItemCard(
              onDelete: () => setState(() => _items.remove(item)),
              child: Column(
                children: [
                  const SizedBox(height: 4),
                  _TextField(label: 'Name', controller: item.nameCtrl),
                  _TextField(label: 'Description', controller: item.descCtrl, maxLines: 2),
                  _TextField(label: 'Price range', controller: item.priceCtrl),
                ],
              ),
            ),
          _AddButton(
            label: 'Add service',
            onTap: () => setState(() => _items.add(_ServiceDraft.empty())),
          ),
        ],
      ),
    );
  }
}

class _ServiceDraft {
  final TextEditingController nameCtrl;
  final TextEditingController descCtrl;
  final TextEditingController priceCtrl;
  final String? imageUrl;

  _ServiceDraft({required this.nameCtrl, required this.descCtrl, required this.priceCtrl, this.imageUrl});

  factory _ServiceDraft.from(ServiceItem s) => _ServiceDraft(
        nameCtrl: TextEditingController(text: s.name),
        descCtrl: TextEditingController(text: s.description ?? ''),
        priceCtrl: TextEditingController(text: s.priceRange ?? ''),
        imageUrl: s.imageUrl,
      );

  factory _ServiceDraft.empty() => _ServiceDraft(
        nameCtrl: TextEditingController(),
        descCtrl: TextEditingController(),
        priceCtrl: TextEditingController(),
      );
}

// ---------------------------------------------------------------------------
// Gallery
// ---------------------------------------------------------------------------

void showGalleryEditSheet(BuildContext context, WidgetRef ref, Profile profile) {
  _showEditSheet(context, _GalleryEditBody(profile: profile));
}

class _GalleryEditBody extends ConsumerStatefulWidget {
  final Profile profile;
  const _GalleryEditBody({required this.profile});

  @override
  ConsumerState<_GalleryEditBody> createState() => _GalleryEditBodyState();
}

class _GalleryEditBodyState extends ConsumerState<_GalleryEditBody> {
  late List<_GalleryDraft> _items =
      widget.profile.gallery.map((g) => _GalleryDraft(url: g.imageUrl, label: g.label)).toList();
  bool _saving = false;
  bool _uploading = false;

  Future<void> _addPhoto() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      final url =
          await ref.read(profileRepositoryProvider).uploadAvatar(userId, file.path, prefix: 'gallery');
      setState(() => _items.add(_GalleryDraft(url: url, label: null)));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Couldn\'t upload photo: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final gallery = _items.map((d) => GalleryItem(imageUrl: d.url, label: d.label).toMap()).toList();
    await _saveAndClose(context, ref, {'gallery': gallery});
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: 'Gallery',
      saving: _saving,
      onSave: _save,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final item in _items)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      child: Image.network(item.url, width: 90, height: 90, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: InkWell(
                        onTap: () => setState(() => _items.remove(item)),
                        child: Container(
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          padding: const EdgeInsets.all(3),
                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              InkWell(
                onTap: _uploading ? null : _addPhoto,
                borderRadius: BorderRadius.circular(AppRadii.sm),
                child: Container(
                  width: 90,
                  height: 90,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.gray300),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: _uploading
                      ? const SizedBox(
                          height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.add_a_photo_outlined, color: AppColors.gray400),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GalleryDraft {
  final String url;
  final String? label;
  _GalleryDraft({required this.url, this.label});
}

// ---------------------------------------------------------------------------
// Social links
// ---------------------------------------------------------------------------

const _socialPlatforms = ['whatsapp', 'instagram', 'facebook', 'youtube', 'linkedin', 'custom'];

void showSocialLinksEditSheet(BuildContext context, WidgetRef ref, Profile profile) {
  _showEditSheet(context, _SocialLinksEditBody(profile: profile));
}

class _SocialLinksEditBody extends ConsumerStatefulWidget {
  final Profile profile;
  const _SocialLinksEditBody({required this.profile});

  @override
  ConsumerState<_SocialLinksEditBody> createState() => _SocialLinksEditBodyState();
}

class _SocialLinksEditBodyState extends ConsumerState<_SocialLinksEditBody> {
  late List<_SocialDraft> _items = widget.profile.socialLinks.map(_SocialDraft.from).toList();
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    final links = _items
        .where((d) => d.urlCtrl.text.trim().isNotEmpty)
        .map((d) => SocialLink(
              platform: d.platform,
              url: d.urlCtrl.text.trim(),
              label: d.platform == 'custom' ? d.labelCtrl.text.trim() : null,
            ).toMap())
        .toList();
    await _saveAndClose(context, ref, {'social_links': links});
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: 'Social links',
      saving: _saving,
      onSave: _save,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in _items)
            _ItemCard(
              onDelete: () => setState(() => _items.remove(item)),
              child: Column(
                children: [
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _socialPlatforms.map((p) {
                      final selected = item.platform == p;
                      return ChoiceChip(
                        avatar: Icon(iconForPlatform(p), size: 14),
                        label: Text(p),
                        selected: selected,
                        onSelected: (_) => setState(() => item.platform = p),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  if (item.platform == 'custom')
                    _TextField(label: 'Label', controller: item.labelCtrl),
                  _TextField(
                    label: 'Link (https://...)',
                    controller: item.urlCtrl,
                    keyboardType: TextInputType.url,
                  ),
                ],
              ),
            ),
          _AddButton(
            label: 'Add link',
            onTap: () => setState(() => _items.add(_SocialDraft.empty())),
          ),
        ],
      ),
    );
  }
}

class _SocialDraft {
  String platform;
  final TextEditingController urlCtrl;
  final TextEditingController labelCtrl;
  _SocialDraft({required this.platform, required this.urlCtrl, required this.labelCtrl});

  factory _SocialDraft.from(SocialLink l) => _SocialDraft(
        platform: l.platform,
        urlCtrl: TextEditingController(text: l.url),
        labelCtrl: TextEditingController(text: l.label ?? ''),
      );

  factory _SocialDraft.empty() => _SocialDraft(
        platform: 'whatsapp',
        urlCtrl: TextEditingController(),
        labelCtrl: TextEditingController(),
      );
}

// ---------------------------------------------------------------------------
// Banking info
// ---------------------------------------------------------------------------

void showBankingEditSheet(BuildContext context, WidgetRef ref, Profile profile) {
  _showEditSheet(context, _BankingEditBody(profile: profile));
}

class _BankingEditBody extends ConsumerStatefulWidget {
  final Profile profile;
  const _BankingEditBody({required this.profile});

  @override
  ConsumerState<_BankingEditBody> createState() => _BankingEditBodyState();
}

class _BankingEditBodyState extends ConsumerState<_BankingEditBody> {
  late List<_BankDraft> _items = widget.profile.bankAccounts.map(_BankDraft.from).toList();
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    final accounts = _items
        .where((d) => d.labelCtrl.text.trim().isNotEmpty)
        .map((d) => BankAccount(
              label: d.labelCtrl.text.trim(),
              accountName: d.accountNameCtrl.text.trim().isEmpty ? null : d.accountNameCtrl.text.trim(),
              accountNumber:
                  d.accountNumberCtrl.text.trim().isEmpty ? null : d.accountNumberCtrl.text.trim(),
              ifsc: d.ifscCtrl.text.trim().isEmpty ? null : d.ifscCtrl.text.trim(),
              upiId: d.upiCtrl.text.trim().isEmpty ? null : d.upiCtrl.text.trim(),
            ).toMap())
        .toList();
    await _saveAndClose(context, ref, {'bank_accounts': accounts});
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: 'Banking info',
      saving: _saving,
      onSave: _save,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in _items)
            _ItemCard(
              onDelete: () => setState(() => _items.remove(item)),
              child: Column(
                children: [
                  const SizedBox(height: 4),
                  _TextField(label: 'Label (e.g. UPI, GST billing)', controller: item.labelCtrl),
                  _TextField(label: 'Account holder name', controller: item.accountNameCtrl),
                  _TextField(
                    label: 'Account number',
                    controller: item.accountNumberCtrl,
                    keyboardType: TextInputType.number,
                  ),
                  _TextField(label: 'IFSC', controller: item.ifscCtrl),
                  _TextField(label: 'UPI ID', controller: item.upiCtrl),
                ],
              ),
            ),
          _AddButton(
            label: 'Add account',
            onTap: () => setState(() => _items.add(_BankDraft.empty())),
          ),
        ],
      ),
    );
  }
}

class _BankDraft {
  final TextEditingController labelCtrl;
  final TextEditingController accountNameCtrl;
  final TextEditingController accountNumberCtrl;
  final TextEditingController ifscCtrl;
  final TextEditingController upiCtrl;

  _BankDraft({
    required this.labelCtrl,
    required this.accountNameCtrl,
    required this.accountNumberCtrl,
    required this.ifscCtrl,
    required this.upiCtrl,
  });

  factory _BankDraft.from(BankAccount a) => _BankDraft(
        labelCtrl: TextEditingController(text: a.label),
        accountNameCtrl: TextEditingController(text: a.accountName ?? ''),
        accountNumberCtrl: TextEditingController(text: a.accountNumber ?? ''),
        ifscCtrl: TextEditingController(text: a.ifsc ?? ''),
        upiCtrl: TextEditingController(text: a.upiId ?? ''),
      );

  factory _BankDraft.empty() => _BankDraft(
        labelCtrl: TextEditingController(),
        accountNameCtrl: TextEditingController(),
        accountNumberCtrl: TextEditingController(),
        ifscCtrl: TextEditingController(),
        upiCtrl: TextEditingController(),
      );
}

// ---------------------------------------------------------------------------
// Downloads & actions — just the brochure link for now.
// ---------------------------------------------------------------------------

void showBrochureEditSheet(BuildContext context, WidgetRef ref, Profile profile) {
  _showEditSheet(context, _BrochureEditBody(profile: profile));
}

class _BrochureEditBody extends ConsumerStatefulWidget {
  final Profile profile;
  const _BrochureEditBody({required this.profile});

  @override
  ConsumerState<_BrochureEditBody> createState() => _BrochureEditBodyState();
}

class _BrochureEditBodyState extends ConsumerState<_BrochureEditBody> {
  late final _urlCtrl = TextEditingController(text: widget.profile.brochureUrl ?? '');
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    await _saveAndClose(context, ref, {'brochure_url': _urlCtrl.text.trim()});
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: 'Downloads & actions',
      saving: _saving,
      onSave: _save,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add a link to a PDF brochure/catalogue — it\'ll show up as a download on your card.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          _TextField(
            label: 'Brochure link (https://...)',
            controller: _urlCtrl,
            keyboardType: TextInputType.url,
          ),
        ],
      ),
    );
  }
}