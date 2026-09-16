import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme.dart';
import '../../core/theme_provider.dart';
import '../../core/providers.dart';

final _notificationsProvider = StateProvider<bool>((ref) => true);

/// Settings tab — membership renewal, order a new physical card,
/// notifications, appearance (light/dark) and sign out. Matches the
/// Figma design's Settings screen (minus the colour-palette picker,
/// since this app is intentionally black & white).
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notifications = true;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _notifications = prefs.getBool('namma_notifications') ?? true);
  }

  Future<void> _setNotifications(bool v) async {
    setState(() => _notifications = v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('namma_notifications', v);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final profileAsync = ref.watch(myProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          profileAsync.when(
            data: (p) => _MembershipCard(daysLeft: _daysLeft(p?.membershipExpiresAt), isMember: p?.isMember ?? false),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 20),

          const _SectionLabel('Card'),
          _SettingsTile(
            icon: Icons.credit_card_outlined,
            title: 'Order a new physical card',
            subtitle: '₹499 — arrives in 5-7 days',
            onTap: () => _showOrderCardSheet(context),
          ),

          const SizedBox(height: 20),
          const _SectionLabel('Appearance'),
          _SettingsTile(
            icon: Icons.light_mode_outlined,
            title: 'Light',
            trailing: Radio<ThemeMode>(
              value: ThemeMode.light,
              groupValue: themeMode,
              onChanged: (m) => ref.read(themeModeProvider.notifier).setMode(m!),
            ),
            onTap: () => ref.read(themeModeProvider.notifier).setMode(ThemeMode.light),
          ),
          _SettingsTile(
            icon: Icons.dark_mode_outlined,
            title: 'Dark',
            trailing: Radio<ThemeMode>(
              value: ThemeMode.dark,
              groupValue: themeMode,
              onChanged: (m) => ref.read(themeModeProvider.notifier).setMode(m!),
            ),
            onTap: () => ref.read(themeModeProvider.notifier).setMode(ThemeMode.dark),
          ),
          _SettingsTile(
            icon: Icons.phone_iphone_outlined,
            title: 'System default',
            trailing: Radio<ThemeMode>(
              value: ThemeMode.system,
              groupValue: themeMode,
              onChanged: (m) => ref.read(themeModeProvider.notifier).setMode(m!),
            ),
            onTap: () => ref.read(themeModeProvider.notifier).setMode(ThemeMode.system),
          ),

          const SizedBox(height: 20),
          const _SectionLabel('Notifications'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Push notifications'),
            subtitle: const Text('New posts and connection activity'),
            value: _notifications,
            onChanged: _setNotifications,
          ),

          const SizedBox(height: 20),
          const _SectionLabel('Account'),
          _SettingsTile(
            icon: Icons.logout,
            title: 'Sign out',
            onTap: () => ref.read(supabaseClientProvider).auth.signOut(),
          ),
        ],
      ),
    );
  }

  int? _daysLeft(DateTime? expires) {
    if (expires == null) return null;
    return expires.difference(DateTime.now()).inDays;
  }

  void _showOrderCardSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
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
            Text('Order a new NFC card', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'A fresh physical card pre-linked to your profile — ₹499, delivered in 5-7 days.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () {
                // TODO: wire to your payment gateway / order fulfilment flow.
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Orders aren\'t wired up yet — connect a payment gateway to enable this.')),
                );
              },
              child: const Text('Continue to payment'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MembershipCard extends StatelessWidget {
  final int? daysLeft;
  final bool isMember;
  const _MembershipCard({required this.daysLeft, required this.isMember});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = (daysLeft == null) ? 0.0 : (daysLeft! / 365).clamp(0.0, 1.0);
    final warn = daysLeft != null && daysLeft! < 30;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                isMember ? 'Membership active' : 'Free account',
                style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
              ),
              const Spacer(),
              if (warn) const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
            ],
          ),
          if (daysLeft != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            Text('$daysLeft days remaining', style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70)),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Upgrade from My Card to unlock your @username and full profile.',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
              ),
              onPressed: () {},
              child: Text(isMember ? 'Renew membership — ₹999/yr' : 'Activate membership — ₹999/yr'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 20),
      title: Text(title, style: Theme.of(context).textTheme.titleSmall),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    );
  }
}
