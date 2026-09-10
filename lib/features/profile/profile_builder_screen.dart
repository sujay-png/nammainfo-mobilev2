import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/providers.dart';
import '../../models/profile.dart';
import 'widgets/live_card_preview.dart';

class ProfileBuilderScreen extends ConsumerStatefulWidget {
  const ProfileBuilderScreen({super.key});

  @override
  ConsumerState<ProfileBuilderScreen> createState() =>
      _ProfileBuilderScreenState();
}

class _ProfileBuilderScreenState extends ConsumerState<ProfileBuilderScreen> {
  final _businessNameCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _jobTitleCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  String? _avatarUrl;
  bool _hydrated = false;
  bool _saving = false;
  bool _uploadingAvatar = false;

  Profile _previewProfile(Profile base) => base.copyWith(
        businessName: _businessNameCtrl.text,
        ownerName: _ownerNameCtrl.text,
        jobTitle: _jobTitleCtrl.text,
        phone: _phoneCtrl.text,
        email: _emailCtrl.text,
        website: _websiteCtrl.text,
        bio: _bioCtrl.text,
        avatarUrl: _avatarUrl,
      );

  void _hydrate(Profile p) {
    if (_hydrated) return;
    _businessNameCtrl.text = p.businessName ?? '';
    _ownerNameCtrl.text = p.ownerName ?? '';
    _jobTitleCtrl.text = p.jobTitle ?? '';
    _phoneCtrl.text = p.phone ?? '';
    _emailCtrl.text = p.email ?? '';
    _websiteCtrl.text = p.website ?? '';
    _bioCtrl.text = p.bio ?? '';
    _avatarUrl = p.avatarUrl;
    _hydrated = true;
  }

  Future<void> _pickAvatar() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (file == null) return;

    setState(() => _uploadingAvatar = true);
    try {
      final url = await ref
          .read(profileRepositoryProvider)
          .uploadAvatar(userId, file.path);
      setState(() => _avatarUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Couldn\'t upload photo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _save() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    setState(() => _saving = true);
    try {
      await ref.read(profileRepositoryProvider).updateOwn(userId, {
        'business_name': _businessNameCtrl.text.trim(),
        'owner_name': _ownerNameCtrl.text.trim(),
        'job_title': _jobTitleCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'website': _websiteCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        if (_avatarUrl != null) 'avatar_url': _avatarUrl,
      });
      ref.invalidate(myProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Card updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Couldn\'t save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _businessNameCtrl,
      _ownerNameCtrl,
      _jobTitleCtrl,
      _phoneCtrl,
      _emailCtrl,
      _websiteCtrl,
      _bioCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(myProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit your card')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Couldn\'t load profile: $e')),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('No profile found.'));
          }
          _hydrate(profile);

          return AnimatedBuilder(
            animation: Listenable.merge([
              _businessNameCtrl,
              _ownerNameCtrl,
              _jobTitleCtrl,
              _phoneCtrl,
              _emailCtrl,
              _websiteCtrl,
              _bioCtrl,
            ]),
            builder: (context, _) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  LiveCardPreview(profile: _previewProfile(profile)),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _uploadingAvatar ? null : _pickAvatar,
                      icon: _uploadingAvatar
                          ? const SizedBox(
                              height: 14,
                              width: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.photo_camera_outlined, size: 18),
                      label: const Text('Change photo'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _Field(label: 'Business name', controller: _businessNameCtrl),
                  _Field(label: 'Your name', controller: _ownerNameCtrl),
                  _Field(label: 'Job title', controller: _jobTitleCtrl),
                  _Field(
                    label: 'Phone',
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                  ),
                  _Field(
                    label: 'Email',
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  _Field(
                    label: 'Website',
                    controller: _websiteCtrl,
                    keyboardType: TextInputType.url,
                  ),
                  _Field(label: 'Bio', controller: _bioCtrl, maxLines: 3),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save card'),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int maxLines;

  const _Field({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
