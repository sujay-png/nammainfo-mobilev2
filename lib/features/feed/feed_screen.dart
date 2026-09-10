import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../models/post.dart';
import 'widgets/post_card.dart';
import 'widgets/create_post_sheet.dart';

final _feedProvider = FutureProvider.autoDispose<List<Post>>((ref) async {
  return ref.watch(postsRepositoryProvider).fetchFeed();
});

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(_feedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Namma Info'),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final posted = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            builder: (_) => const CreatePostSheet(),
          );
          if (posted == true) ref.invalidate(_feedProvider);
        },
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(_feedProvider),
        child: feedAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [
              const SizedBox(height: 120),
              Center(child: Text('Couldn\'t load your feed: $e')),
            ],
          ),
          data: (posts) {
            if (posts.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Your feed is empty. Save a connection by tapping or '
                        'scanning someone\'s card, and their updates will '
                        'show up here.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: posts.length,
              itemBuilder: (context, i) => PostCard(post: posts[i]),
            );
          },
        ),
      ),
    );
  }
}
