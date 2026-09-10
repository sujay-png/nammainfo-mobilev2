import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme.dart';
import '../../../models/profile.dart';

class GallerySection extends StatefulWidget {
  final List<GalleryItem> items;
  const GallerySection({super.key, required this.items});

  @override
  State<GallerySection> createState() => _GallerySectionState();
}

class _GallerySectionState extends State<GallerySection> {
  String _category = 'All';

  void _openLightbox(BuildContext context, GalleryItem item) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: CachedNetworkImage(imageUrl: item.imageUrl, fit: BoxFit.contain),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return Text(
        'No photos yet. Add some from Edit Card.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    final categories = [
      'All',
      ...{
        for (final i in widget.items)
          if (i.category != null) i.category!,
      },
    ];
    final filtered = _category == 'All'
        ? widget.items
        : widget.items.where((i) => i.category == _category).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (categories.length > 1)
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final c = categories[i];
                final selected = c == _category;
                return ChoiceChip(
                  label: Text(c),
                  selected: selected,
                  onSelected: (_) => setState(() => _category = c),
                );
              },
            ),
          ),
        if (categories.length > 1) const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final item = filtered[i];
              return InkWell(
                onTap: () => _openLightbox(context, item),
                borderRadius: BorderRadius.circular(AppRadii.sm),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  child: CachedNetworkImage(
                    imageUrl: item.imageUrl,
                    width: 110,
                    height: 110,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
