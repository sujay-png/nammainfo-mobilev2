import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/theme.dart';
import '../../core/providers.dart';
import '../feed/feed_screen.dart';
import '../card/my_card_screen.dart';
import '../scan/scan_screen.dart';
import '../contacts/contacts_screen.dart';
import '../settings/settings_screen.dart';

/// Bottom tab shell — Instagram-style nav with the QR scan button
/// elevated in the centre, matching the Figma design.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 1;

  static const _tabs = [
    FeedScreen(),
    MyCardScreen(),
    ScanScreen(),
    ContactsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(myProfileProvider);
    final avatarUrl = profileAsync.valueOrNull?.avatarUrl;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: SizedBox(
        height: 64,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            BottomAppBar(
              height: 64,
              padding: EdgeInsets.zero,
              color: isDark ? AppColors.black : AppColors.white,
              elevation: 0,
              shape: const CircularNotchedRectangle(),
              notchMargin: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: Icons.dynamic_feed_outlined,
                    activeIcon: Icons.dynamic_feed,
                    label: 'Feed',
                    selected: _index == 0,
                    onTap: () => setState(() => _index = 0),
                  ),
                  _NavItem(
                    icon: Icons.badge_outlined,
                    activeIcon: Icons.badge,
                    label: 'My Card',
                    selected: _index == 1,
                    avatarUrl: avatarUrl,
                    onTap: () => setState(() => _index = 1),
                  ),
                  const SizedBox(width: 56),
                  _NavItem(
                    icon: Icons.contacts_outlined,
                    activeIcon: Icons.contacts,
                    label: 'Contacts',
                    selected: _index == 3,
                    onTap: () => setState(() => _index = 3),
                  ),
                  _NavItem(
                    icon: Icons.settings_outlined,
                    activeIcon: Icons.settings,
                    label: 'Settings',
                    selected: _index == 4,
                    onTap: () => setState(() => _index = 4),
                  ),
                ],
              ),
            ),
            Positioned(
              top: -20,
              child: GestureDetector(
                onTap: () => setState(() => _index = 2),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _index == 2
                        ? (isDark ? AppColors.white : AppColors.black)
                        : (isDark ? AppColors.ink800 : AppColors.black),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppColors.black : AppColors.white,
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    Icons.qr_code_scanner,
                    color: _index == 2
                        ? (isDark ? AppColors.black : AppColors.white)
                        : AppColors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? avatarUrl;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Theme.of(context).colorScheme.onSurface
        : AppColors.gray400;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            avatarUrl != null
                ? CircleAvatar(
                    radius: 11,
                    backgroundImage: CachedNetworkImageProvider(avatarUrl!),
                  )
                : Icon(selected ? activeIcon : icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
