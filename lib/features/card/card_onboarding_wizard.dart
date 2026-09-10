import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';

/// Shown the first time a user opens "My Card" and hasn't designed their
/// card yet: a short "do you want to make one?" prompt, then a step-by-step
/// form for everything the physical/digital card template needs. On finish
/// it flips `profiles.card_designed` to true, and MyCardScreen takes over.
class CardOnboardingWizard extends ConsumerStatefulWidget {
  const CardOnboardingWizard({super.key});

  @override
  ConsumerState<CardOnboardingWizard> createState() => _CardOnboardingWizardState();
}

class _CardOnboardingWizardState extends ConsumerState<CardOnboardingWizard> {
  // 0 = intro prompt, 1..3 = form steps.
  int _step = 0;
  static const _formSteps = 3;

  final _pageController = PageController();

  final _businessNameCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _jobTitleCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  String? _logoUrl;
  bool _uploadingLogo = false;
  bool _saving = false;

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in [
      _businessNameCtrl,
      _ownerNameCtrl,
      _jobTitleCtrl,
      _phoneCtrl,
      _emailCtrl,
      _websiteCtrl,
      _addressCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _goToForm() {
    setState(() => _step = 1);
  }

  void _next() {
    if (_step == 1 && _businessNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business name is required.')),
      );
      return;
    }
    if (_step == 2 && _ownerNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your name is required.')),
      );
      return;
    }
    if (_step < _formSteps) {
      setState(() => _step += 1);
      _pageController.animateToPage(
        _step - 1,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  void _back() {
    if (_step <= 1) {
      setState(() => _step = 0);
      return;
    }
    setState(() => _step -= 1);
    _pageController.animateToPage(
      _step - 1,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _pickLogo() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (file == null) return;

    setState(() => _uploadingLogo = true);
    try {
      final url = await ref
          .read(profileRepositoryProvider)
          .uploadAvatar(userId, file.path, prefix: 'logo');
      setState(() => _logoUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Couldn\'t upload logo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingLogo = false);
    }
  }

  Future<void> _finish() async {
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
        'address': _addressCtrl.text.trim(),
        if (_logoUrl != null) 'logo_url': _logoUrl,
        'card_designed': true,
      });
      ref.invalidate(myProfileProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Couldn\'t save your card: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_step == 0) return _IntroPrompt(onStart: _goToForm);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              IconButton(
                onPressed: _back,
                icon: const Icon(Icons.arrow_back, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: _step / _formSteps,
                    minHeight: 5,
                    backgroundColor: AppColors.gray200,
                    valueColor: const AlwaysStoppedAnimation(AppColors.black),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('$_step/$_formSteps', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _StepScaffold(
                title: 'Your business',
                subtitle: 'This is what shows on the back of your card.',
                children: [
                  _Field(label: 'Business name *', controller: _businessNameCtrl),
                  const SizedBox(height: 18),
                  _LogoPicker(
                    logoUrl: _logoUrl,
                    uploading: _uploadingLogo,
                    onTap: _pickLogo,
                  ),
                ],
              ),
              _StepScaffold(
                title: 'Your details',
                subtitle: 'This is what shows on the front of your card.',
                children: [
                  _Field(label: 'Your name *', controller: _ownerNameCtrl),
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
                ],
              ),
              _StepScaffold(
                title: 'Online & location',
                subtitle: 'Optional — you can always add these later.',
                children: [
                  _Field(
                    label: 'Website',
                    controller: _websiteCtrl,
                    keyboardType: TextInputType.url,
                  ),
                  _Field(label: 'Address', controller: _addressCtrl, maxLines: 2),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: ElevatedButton(
            onPressed: _saving ? null : _next,
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(_step == _formSteps ? 'Create my card' : 'Next'),
          ),
        ),
      ],
    );
  }
}

class _IntroPrompt extends StatelessWidget {
  final VoidCallback onStart;
  const _IntroPrompt({required this.onStart});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.black, width: 1.4),
            ),
            child: const Icon(Icons.badge_outlined, size: 36, color: AppColors.black),
          ),
          const SizedBox(height: 24),
          Text(
            'Design your own\ndigital business card?',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          Text(
            'Takes under a minute. You can edit everything later.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onStart,
              child: const Text('Yes, let\'s design it'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _StepScaffold({required this.title, required this.subtitle, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      children: [
        Text(title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(subtitle, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 20),
        ...children,
      ],
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
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

class _LogoPicker extends StatelessWidget {
  final String? logoUrl;
  final bool uploading;
  final VoidCallback onTap;

  const _LogoPicker({required this.logoUrl, required this.uploading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: uploading ? null : onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.gray300),
                image: logoUrl != null
                    ? DecorationImage(image: NetworkImage(logoUrl!), fit: BoxFit.cover)
                    : null,
              ),
              child: uploading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : (logoUrl == null
                      ? const Icon(Icons.add_photo_alternate_outlined, color: AppColors.gray400)
                      : null),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                logoUrl == null ? 'Add company logo (optional)' : 'Logo added — tap to change',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
