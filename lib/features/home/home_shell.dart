import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/providers.dart';
import '../feed/feed_screen.dart';
import '../card/my_card_screen.dart';
import '../profile/profile_builder_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(myProfileProvider);
    final avatarUrl = profileAsync.valueOrNull?.avatarUrl;

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          FeedScreen(),
          MyCardScreen(),
          ProfileBuilderScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Feed',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.nfc_outlined),
            activeIcon: Icon(Icons.nfc),
            label: 'My Card',
          ),
          BottomNavigationBarItem(
            icon: avatarUrl != null
                ? CircleAvatar(radius: 11, backgroundImage: CachedNetworkImageProvider(avatarUrl))
                : const Icon(Icons.person_outline),
            activeIcon: avatarUrl != null
                ? CircleAvatar(radius: 11, backgroundImage: CachedNetworkImageProvider(avatarUrl))
                : const Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
