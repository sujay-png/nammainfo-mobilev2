import 'dart:math';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme.dart';

const _reviewPools = [
  [
    'Excellent service and very professional team — highly recommend for anyone in the area!',
    'Great experience from start to finish. Quick, reliable and fairly priced.',
    'One of the best in the business. Will definitely come back again.',
  ],
  [
    'Friendly staff and top quality work. Exactly what I was looking for.',
    'Prompt response and delivered exactly as promised. Five stars!',
    'Very knowledgeable and easy to work with. Great value for money.',
  ],
  [
    'Outstanding attention to detail and customer service.',
    'Reliable, honest and skilled — a pleasure to do business with.',
    'Consistently good service every time. Highly recommended locally.',
  ],
];

/// AI-suggested, keyword-optimised review templates a customer can tap to
/// copy/open in Google Reviews — matches the Figma design's "Google
/// Reviews" section.
class ReviewsSection extends StatefulWidget {
  final String? googleReviewUrl;
  const ReviewsSection({super.key, this.googleReviewUrl});

  @override
  State<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<ReviewsSection> {
  int _pool = 0;

  void _openReview(String text) {
    final url = widget.googleReviewUrl;
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Owner hasn\'t added a Google review link yet.')),
      );
      return;
    }
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final reviews = _reviewPools[_pool];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Tap a template to open Google Reviews', style: Theme.of(context).textTheme.bodySmall),
            TextButton.icon(
              onPressed: () => setState(() => _pool = Random().nextInt(_reviewPools.length)),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('New reviews'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ...reviews.map(
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => _openReview(r),
              borderRadius: BorderRadius.circular(AppRadii.sm),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Text(r, style: Theme.of(context).textTheme.bodyMedium),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
